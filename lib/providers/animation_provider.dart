import 'package:flutter_riverpod/flutter_riverpod.dart';

class AnimationState {
  final String currentAnimation;
  final bool shouldPlay;
  final bool isAnimationComplete;

  const AnimationState({
    required this.currentAnimation,
    this.shouldPlay = false,
    this.isAnimationComplete = false,
  });

  AnimationState copyWith({
    String? currentAnimation,
    bool? shouldPlay,
    bool? isAnimationComplete,
  }) {
    return AnimationState(
      currentAnimation: currentAnimation ?? this.currentAnimation,
      shouldPlay: shouldPlay ?? this.shouldPlay,
      isAnimationComplete: isAnimationComplete ?? this.isAnimationComplete,
    );
  }
}

class AnimationStateNotifier extends StateNotifier<AnimationState> {
  AnimationStateNotifier()
      : super(const AnimationState(
    currentAnimation: '', // No initial animation
    shouldPlay: false, // Do not play animation initially
    isAnimationComplete: true, // Initially considered complete
  ));

  void playAnimation(String animationName) {
    // Stop if an animation is already in progress
    if (!state.isAnimationComplete) return;

    // Start playing the animation
    state = state.copyWith(
      currentAnimation: animationName,
      shouldPlay: true,
      isAnimationComplete: false,
    );

    // Stop the animation after its duration
    Future.delayed(const Duration(seconds: 2), () {
      state = state.copyWith(
        shouldPlay: false,
        isAnimationComplete: true,
      );
    });
  }

  void resetAnimation() {
    state = state.copyWith(
      currentAnimation: '',
      shouldPlay: false,
      isAnimationComplete: true,
    );
  }
}

final animationStateProvider = StateNotifierProvider<AnimationStateNotifier, AnimationState>((ref) {
  return AnimationStateNotifier();
});