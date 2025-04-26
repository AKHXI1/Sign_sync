# fastapi_server.py

import base64
import logging
import sys
import os
import json
import cv2
import numpy as np
import tensorflow as tf
import mediapipe as mp
import asyncio

from fastapi import FastAPI, WebSocket, WebSocketDisconnect
from datetime import datetime

# ----------------------------
# Global Logging Configuration
# ----------------------------
log_filename = "server_logs.log"
logging.basicConfig(
    level=logging.DEBUG,
    format="%(asctime)s - %(levelname)s - %(message)s",
    handlers=[
        logging.FileHandler(log_filename, mode='w', encoding='utf-8'),
        logging.StreamHandler()
    ]
)

logger = logging.getLogger(__name__)
logger.info("Logging is now active!")

# ----------------------------
# Constants and Config
# ----------------------------
ACTIONS = ['idle', 'hello', 'thanks', 'name']  # Adjust to match your trained model's classes
SEQUENCE_LENGTH = 30  # Must match your training length
NUM_FEATURES = 1662   # 468*3 + 33*4 + 21*3 + 21*3

# Directory to store any captured videos
VIDEO_SAVE_PATH = "video_output"
os.makedirs(VIDEO_SAVE_PATH, exist_ok=True)

# ----------------------------
# Sign Language Detector Class
# ----------------------------
class SignLanguageDetector:
    def __init__(self):
        self.mp_holistic = mp.solutions.holistic
        self.mp_drawing = mp.solutions.drawing_utils

        # Rolling window for keypoints and structured sentence
        self.landmark_sequence = []
        self.sentence = []
        self.threshold = 0.8  # You can tune this

        self.current_prediction = ""
        self.current_confidence = 0.0
        self.structured_sentence = ""

        # Load Mediapipe Holistic model
        self.holistic = self.mp_holistic.Holistic(
            min_detection_confidence=0.7,
            min_tracking_confidence=0.7,
            model_complexity=1
        )

        # Load your TF model
        self.model = self.initialize_model()

    def initialize_model(self):
        try:
            model = tf.keras.models.load_model("light_lstm_final.h5")
            logger.info("Light LSTM model loaded successfully.")
            return model
        except Exception as e:
            logger.error(f"Error loading model: {str(e)}")
            sys.exit(1)

    def extract_keypoints(self, results):
        """Extract face, pose, left hand, right hand landmarks -> 1D numpy array."""
        face = np.zeros(468 * 3)
        pose = np.zeros(33 * 4)
        lh   = np.zeros(21 * 3)
        rh   = np.zeros(21 * 3)

        try:
            if results.face_landmarks:
                face = np.array([[res.x, res.y, res.z] for res in results.face_landmarks.landmark]).flatten()
            if results.pose_landmarks:
                pose = np.array([[res.x, res.y, res.z, res.visibility] for res in results.pose_landmarks.landmark]).flatten()
            if results.left_hand_landmarks:
                lh = np.array([[res.x, res.y, res.z] for res in results.left_hand_landmarks.landmark]).flatten()
            if results.right_hand_landmarks:
                rh = np.array([[res.x, res.y, res.z] for res in results.right_hand_landmarks.landmark]).flatten()
        except Exception as e:
            logger.error(f"Error extracting keypoints: {str(e)}")

        return np.concatenate([face, pose, lh, rh])

    def process_frame(self, frame_bgr):
        """
        Main pipeline:
        1) Convert BGR to RGB.
        2) Run Mediapipe Holistic.
        3) Extract keypoints and maintain a rolling window.
        4) When enough frames are collected, predict the sign.
           The current prediction is always updated, even if it is "idle".
           However, only non-"idle" predictions are added to the structured sentence.
        """
        results = self.holistic.process(cv2.cvtColor(frame_bgr, cv2.COLOR_BGR2RGB))
        keypoints = self.extract_keypoints(results)
        self.landmark_sequence.append(keypoints)
        if len(self.landmark_sequence) > SEQUENCE_LENGTH:
            self.landmark_sequence = self.landmark_sequence[-SEQUENCE_LENGTH:]

        if len(self.landmark_sequence) == SEQUENCE_LENGTH:
            input_data = np.array([self.landmark_sequence], dtype=np.float32)
            prediction = self.model.predict(input_data, verbose=0)[0]
            pred_idx = np.argmax(prediction)
            conf = float(prediction[pred_idx])
            new_word = ACTIONS[pred_idx]

            # Always update the current prediction (even if "idle")
            self.current_prediction = new_word
            self.current_confidence = conf

            if conf > self.threshold:
                # Only add non-"idle" predictions to the rolling sentence
                if new_word != "idle":
                    if not self.sentence or (new_word != self.sentence[-1]):
                        self.sentence.append(new_word)
                        logger.info(f"Detected: {new_word} (Conf: {conf:.2f}) | Sentence so far: {self.sentence}")
                        if len(self.sentence) > 8:
                            self.sentence = self.sentence[-8:]
        self.structured_sentence = " ".join(self.sentence[-8:])
        return self.current_prediction, self.current_confidence, self.structured_sentence

# ----------------------------
# FastAPI Application
# ----------------------------
app = FastAPI()
detector = SignLanguageDetector()

@app.websocket("/ws")
async def websocket_endpoint(websocket: WebSocket):
    """
    Receives base64-encoded frames over WebSocket, decodes them, writes to a video file,
    and runs them through the sign language detector.
    Sends back the prediction.
    Also listens for a special "CLEAR" command to reset the detector's sentence.
    """
    await websocket.accept()
    logger.info("WebSocket connection established.")

    # Lazy initialization of the video writer.
    video_writer = None
    fourcc = cv2.VideoWriter_fourcc(*"XVID")
    fps = 60  # Adjust as needed

    timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
    video_filename = os.path.join(VIDEO_SAVE_PATH, f"sign_video_{timestamp}.avi")

    try:
        while True:
            try:
                data = await websocket.receive_text()
            except WebSocketDisconnect:
                logger.info("WebSocket disconnected by client.")
                break
            except Exception as e:
                logger.error(f"Error receiving data: {str(e)}")
                break

            if not data:
                continue

            # Check for the clear command.
            if data == "CLEAR":
                detector.sentence = []
                detector.landmark_sequence = []
                logger.info("Detector sentence cleared via client command.")
                # Send back an update with empty prediction.
                await websocket.send_text(json.dumps({
                    "prediction": "",
                    "confidence": 0.0,
                    "structured_text": ""
                }))
                continue

            try:
                # Process incoming frame (assumed to be base64 encoded JPEG bytes).
                decoded_bytes = base64.b64decode(data)
                np_arr = np.frombuffer(decoded_bytes, np.uint8)
                frame = cv2.imdecode(np_arr, cv2.IMREAD_COLOR)

                if frame is None:
                    logger.warning("Decoded frame is None. Skipping...")
                    continue

                # --- No transformation here ---
                processed_frame = frame
                # ------------------------------

                if video_writer is None:
                    frame_height, frame_width = processed_frame.shape[:2]
                    video_writer = cv2.VideoWriter(
                        video_filename,
                        fourcc,
                        fps,
                        (frame_width, frame_height)
                    )
                    logger.info(f"Video writer initialized: {video_filename} {frame_width}x{frame_height}, fps={fps}")

                video_writer.write(processed_frame)

                pred, conf, struct_text = detector.process_frame(processed_frame)

                message = {
                    "prediction": pred,
                    "confidence": conf,
                    "structured_text": struct_text
                }
                await websocket.send_text(json.dumps(message))

            except Exception as e:
                logger.error(f"Error decoding/processing frame: {str(e)}")
                continue

    except WebSocketDisconnect:
        logger.info("WebSocket disconnected.")
    except Exception as e:
        logger.error(f"Unexpected WebSocket error: {str(e)}")
    finally:
        if video_writer is not None:
            video_writer.release()
            logger.info(f"Video saved at: {video_filename}")
        try:
            await websocket.close()
        except:
            pass
