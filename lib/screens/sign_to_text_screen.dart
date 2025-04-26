// sign_to_text.dart

import 'dart:async';
import 'dart:math' as math;

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image/image.dart' as imglib;

import '../providers/api_provider.dart';

class SignToTextScreen extends StatefulWidget {
  @override
  _SignToTextScreenState createState() => _SignToTextScreenState();
}

class _SignToTextScreenState extends State<SignToTextScreen> {
  late CameraController _cameraController;
  late List<CameraDescription> cameras;

  // Flag to indicate if streaming is active.
  bool isStreaming = false;

  String prediction = "";
  double _confidence = 0.0;
  String structuredSentence = "";
  int selectedCameraIndex = 0;

  ApiProvider apiProvider = ApiProvider();

  @override
  void initState() {
    super.initState();
    // Lock app orientation to portrait.
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    initCamera();
  }

  Future<void> initCamera() async {
    cameras = await availableCameras();
    if (cameras.isNotEmpty) {
      _cameraController = CameraController(
        cameras[selectedCameraIndex],
        ResolutionPreset.ultraHigh,
        enableAudio: false,
      );
      await _cameraController.initialize();
      // Lock camera capture orientation to portrait as well.
      await _cameraController
          .lockCaptureOrientation(DeviceOrientation.portraitUp);
      setState(() {});
    } else {
      print("No cameras found!");
    }
  }

  /// Convert YUV420 camera frame to JPEG bytes.
  /// For front camera: rotates 270° clockwise then flips horizontally.
  /// For back camera: rotates 90° clockwise then flips horizontally (to un-mirror the frame).
  Uint8List convertYUV420toJpeg(CameraImage image, {bool isFront = false}) {
    final width = image.width;
    final height = image.height;

    final yPlane = image.planes[0];
    final uPlane = image.planes[1];
    final vPlane = image.planes[2];

    final yBuffer = yPlane.bytes;
    final uBuffer = uPlane.bytes;
    final vBuffer = vPlane.bytes;

    // Create an image from the YUV data.
    imglib.Image img = imglib.Image(width, height);
    final int uvRowStride = uPlane.bytesPerRow;
    final int uvPixelStride = uPlane.bytesPerPixel!;

    for (int h = 0; h < height; h++) {
      final int yRowOffset = h * yPlane.bytesPerRow;
      final int uvRowOffset = (h >> 1) * uvRowStride;

      for (int w = 0; w < width; w++) {
        final int yPixel = yBuffer[yRowOffset + w];
        final int uPixel = uBuffer[uvRowOffset + (w >> 1) * uvPixelStride];
        final int vPixel = vBuffer[uvRowOffset + (w >> 1) * uvPixelStride];

        int r = (yPixel + 1.370705 * (vPixel - 128)).round();
        int g = (yPixel - 0.337633 * (uPixel - 128) - 0.698001 * (vPixel - 128))
            .round();
        int b = (yPixel + 1.732446 * (uPixel - 128)).round();

        r = r.clamp(0, 255);
        g = g.clamp(0, 255);
        b = b.clamp(0, 255);

        img.setPixelRgba(w, h, r, g, b);
      }
    }

    // --- Transformation to match the preview ---
    // For front camera: rotate 270° and flip horizontally.
    // For back camera: rotate 90° and flip horizontally (to un-mirror the frame).
    if (isFront) {
      img = imglib.copyRotate(img, 270);
      img = imglib.flipHorizontal(img);
    } else {
      img = imglib.copyRotate(img, 90);
      img = imglib.flipHorizontal(img);
    }
    // ---------------------------------------------

    return Uint8List.fromList(imglib.JpegEncoder().encodeImage(img));
  }

  /// Start or stop streaming camera frames via WebSocket.
  void toggleStreaming() async {
    if (!_cameraController.value.isInitialized) return;

    if (isStreaming) {
      // Stop streaming
      await _cameraController.stopImageStream();
      apiProvider.closeConnection(); // Close WebSocket
      setState(() {
        isStreaming = false;
      });
    } else {
      // Start streaming
      apiProvider.connect(
        onMessage: (data) {
          // Whenever the server sends a message, update our UI.
          setState(() {
            prediction = data['prediction'] ?? "";
            _confidence = data['confidence'] ?? 0.0;
            structuredSentence = data['structured_text'] ?? "";
          });
        },
      );

      setState(() {
        isStreaming = true;
      });

      // Determine if the active camera is the front camera.
      final isFront = cameras[selectedCameraIndex].lensDirection ==
          CameraLensDirection.front;

      // Send frames in real-time as they're available.
      _cameraController.startImageStream((CameraImage image) {
        if (!isStreaming) return;
        try {
          final frameBytes = convertYUV420toJpeg(image, isFront: isFront);
          apiProvider.sendFrame(frameBytes);
        } catch (e) {
          print("Error converting or sending frame: $e");
        }
      });
    }
  }

  /// Switch front/back camera.
  void switchCamera() async {
    selectedCameraIndex = (selectedCameraIndex + 1) % cameras.length;

    if (isStreaming) {
      // Stop streaming if active.
      await _cameraController.stopImageStream();
      apiProvider.closeConnection();
      setState(() => isStreaming = false);
    }

    await _cameraController.dispose();

    _cameraController = CameraController(
      cameras[selectedCameraIndex],
      ResolutionPreset.high,
      enableAudio: false,
    );

    await _cameraController.initialize();
    await _cameraController
        .lockCaptureOrientation(DeviceOrientation.portraitUp);

    setState(() {});
  }

  @override
  void dispose() {
    if (_cameraController.value.isInitialized) {
      _cameraController.stopImageStream();
      apiProvider.closeConnection();
      _cameraController.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Top 2/3 for camera preview; bottom 1/3 for text and controls.
    return Scaffold(
      backgroundColor: const Color(0xFFF5E6C8),
      body: SafeArea(
        child: Column(
          children: [
            // Camera preview (2/3 of the screen)
            Expanded(
              flex: 4,
              child: Stack(
                children: [
                  if (_cameraController.value.isInitialized)
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(8, 8, 8, 20),
                        child: RotatedBox(
                          // Rotate preview 90° clockwise.
                          quarterTurns: 1,
                          child: AspectRatio(
                            aspectRatio: _cameraController.value.aspectRatio,
                            child: Transform(
                              alignment: Alignment.center,
                              transform:
                                  cameras[selectedCameraIndex].lensDirection ==
                                          CameraLensDirection.front
                                      ? Matrix4.rotationY(math.pi)
                                      : Matrix4.identity(),
                              child: CameraPreview(_cameraController),
                            ),
                          ),
                        ),
                      ),
                    )
                  else
                    const Center(child: CircularProgressIndicator()),
                  // Button to switch cameras.
                  Positioned(
                    top: 16,
                    right: 16,
                    child: ElevatedButton.icon(
                      onPressed: switchCamera,
                      icon: const Icon(Icons.flip_camera_ios),
                      label: const Text("Switch"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF8B6F47),
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                  // Semi-transparent overlay for prediction + confidence.
                  Positioned(
                    bottom: 16,
                    left: 16,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.5),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        prediction.isNotEmpty
                            ? "$prediction (${(_confidence * 100).toStringAsFixed(1)}%)"
                            : "Waiting for prediction...",
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Bottom area for structured text and controls.
            Expanded(
              flex: 1,
              child: Container(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Stack with text box and clear button.
                    Stack(
                      children: [
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: const Color(0xFF8B6F47),
                              width: 2,
                            ),
                            borderRadius: BorderRadius.circular(8),
                            color: Colors.white.withOpacity(0.9),
                          ),
                          child: Text(
                            structuredSentence.isNotEmpty
                                ? structuredSentence
                                : "Waiting for prediction...",
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        // Clear button positioned at the top right of the text box.
                        Positioned(
                          top: 0,
                          right: 0,
                          child: IconButton(
                            icon: const Icon(Icons.clear, color: Colors.red),
                            onPressed: () {
                              // Send a clear command to the server so that its internal buffer is reset.
                              apiProvider.sendClearCommand();
                              // Also clear the local variable.
                              setState(() {
                                structuredSentence = "";
                              });
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    // Toggle streaming button.
                    ElevatedButton(
                      onPressed: toggleStreaming,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF8B6F47),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 32, vertical: 16),
                      ),
                      child: Text(isStreaming ? "Stop" : "Start Capture"),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
