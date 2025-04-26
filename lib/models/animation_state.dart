class AnimationState {
  final String currentAnimation;
  final bool isPlaying;
  final List<String> animationQueue;

  const AnimationState({
    required this.currentAnimation,
    required this.isPlaying,
    this.animationQueue = const [],
  });

  AnimationState copyWith({
    String? currentAnimation,
    bool? isPlaying,
    List<String>? animationQueue,
  }) {
    return AnimationState(
      currentAnimation: currentAnimation ?? this.currentAnimation,
      isPlaying: isPlaying ?? this.isPlaying,
      animationQueue: animationQueue ?? this.animationQueue,
    );
  }
}