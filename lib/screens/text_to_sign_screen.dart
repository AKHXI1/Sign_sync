import 'package:flutter/material.dart';
import 'package:flutter_3d_controller/flutter_3d_controller.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/animation_provider.dart';
import '../services/sign_language_processor.dart';

class TextToSignScreen extends ConsumerStatefulWidget {
  const TextToSignScreen({super.key});

  @override
  ConsumerState<TextToSignScreen> createState() => _TextToSignScreenState();
}

class _TextToSignScreenState extends ConsumerState<TextToSignScreen> {
  final TextEditingController _textController = TextEditingController();
  final Flutter3DController _controller = Flutter3DController();
  List<String> _currentAnimationQueue = [];
  bool _isModelLoaded = false;

  // Duration for each sign language animation.
  // Adjust if you know the actual durations.
  static const Duration _signAnimationDuration = Duration(seconds: 2);

  @override
  void initState() {
    super.initState();

    // Listen for when the model is fully loaded.
    _controller.onModelLoaded.addListener(() {
      if (_controller.onModelLoaded.value) {
        setState(() => _isModelLoaded = true);
        _zoomIn();

        // Start playing idle animation once the model is loaded.
        _playIdleAnimation();
      }
    });
  }

  /// Adjust the camera settings after the model is loaded.
  void _zoomIn() {
    if (!_isModelLoaded) return;
    _controller.setCameraOrbit(0, 80, 20);
    _controller.setCameraTarget(0, 1.2, 0);
  }

  /// Starts playing the idle animation.
  void _playIdleAnimation() {
    if (!_isModelLoaded) return;
    // Replace 'idle' with the actual idle animation name if needed.
    // _controller.playAnimation(animationName: 'C001_CharacterSelect_Idle');
    _controller.playAnimation(animationName: 'idle-sign-lang-ani');
  }

  /// Plays the next sign language animation from the queue.
  ///
  /// Since the controller API does not provide an animation-completion
  /// callback, we simulate waiting for the animation to complete by using
  /// a fixed delay (_signAnimationDuration).
  void _playNextAnimation() {
    if (!_isModelLoaded || _currentAnimationQueue.isEmpty) return;

    // Stop the idle animation before playing a sign animation.
    _controller.resetAnimation();
    _controller.pauseAnimation();

    // Get the next animation from the queue.
    final String nextAnimation = _currentAnimationQueue.removeAt(0);

    // Notify state (if needed) and play the sign language animation.
    ref.read(animationStateProvider.notifier).playAnimation(nextAnimation);
    _controller.playAnimation(animationName: nextAnimation);

    // Wait for the animation to complete before proceeding.
    Future.delayed(_signAnimationDuration, () {
      // Reset and pause the current animation.
      _controller.resetAnimation();
      _controller.pauseAnimation();

      // If there are more animations, play the next one.
      if (_currentAnimationQueue.isNotEmpty) {
        _playNextAnimation();
      } else {
        // Once all sign animations are finished, reset state and resume idle.
        ref.read(animationStateProvider.notifier).resetAnimation();
        _playIdleAnimation();
      }
    });
  }

  /// Processes the input text by generating a queue of sign animations.
  void _processText() {
    if (!_isModelLoaded) return;

    // Stop the idle animation while processing text.
    _controller.resetAnimation();
    _controller.pauseAnimation();

    final String text = _textController.text;
    if (text.isEmpty) return;

    // Clear any previous animations and generate a new queue.
    _currentAnimationQueue.clear();
    final List<String> animations = SignLanguageProcessor.processText(text);
    if (animations.isNotEmpty) {
      _currentAnimationQueue.addAll(animations);
      _playNextAnimation();
    }
  }

  void _dismissKeyboard() {
    FocusScope.of(context).unfocus();
  }

  void _onDonePressed() {
    _dismissKeyboard();
    _processText();
  }

  @override
  void dispose() {
    _textController.dispose();
    // Remove listeners to prevent memory leaks.
    _controller.onModelLoaded.removeListener(() {});
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5E6C8),
      body: Column(
        children: [
          // 3D Model Viewer
          Expanded(
            flex: 2,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.transparent,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 10,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: Flutter3DViewer(
                    // The controller gives you full control over the 3D model.
                    controller: _controller,
                    src: 'assets/models/animations/ani_final.glb',
                    // Optional: customize the loading progress bar.
                    progressBarColor: Colors.orange,
                    // Optional: enable or disable touch.
                    enableTouch: true,
                  ),
                ),
              ),
            ),
          ),

          // "Convert to Sign Language" Button
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: ElevatedButton(
              onPressed: _isModelLoaded ? _processText : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF8B6F47),
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 50),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                elevation: 4,
              ),
              child: const Text(
                'Convert to Sign Language',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
          ),

          // Text Input Field
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _textController,
              textInputAction: TextInputAction.done,
              onSubmitted: (_) => _onDonePressed(),
              decoration: InputDecoration(
                hintText: 'Enter text to convert...',
                hintStyle: const TextStyle(color: Colors.grey),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20),
                  borderSide: const BorderSide(color: Color(0xFF8B6F47)),
                ),
                filled: true,
                fillColor: Colors.white,
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
              maxLines: 3,
            ),
          ),
        ],
      ),
    );
  }
}
