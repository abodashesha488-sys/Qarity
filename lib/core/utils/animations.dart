import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

class AppAnimations {
  AppAnimations._();

  static List<Effect<dynamic>> get fadeIn => [
    FadeEffect(duration: 400.ms, curve: Curves.easeOut),
  ];

  static List<Effect<dynamic>> get slideUp => [
    FadeEffect(duration: 400.ms, curve: Curves.easeOut),
    SlideEffect(
      begin: const Offset(0, 30),
      duration: 500.ms,
      curve: Curves.easeOutCubic,
    ),
  ];

  static List<Effect<dynamic>> get slideDown => [
    FadeEffect(duration: 400.ms, curve: Curves.easeOut),
    SlideEffect(
      begin: const Offset(0, -30),
      duration: 500.ms,
      curve: Curves.easeOutCubic,
    ),
  ];

  static List<Effect<dynamic>> get slideRight => [
    FadeEffect(duration: 400.ms, curve: Curves.easeOut),
    SlideEffect(
      begin: const Offset(-30, 0),
      duration: 500.ms,
      curve: Curves.easeOutCubic,
    ),
  ];

  static List<Effect<dynamic>> get scaleIn => [
    FadeEffect(duration: 300.ms, curve: Curves.easeOut),
    ScaleEffect(
      begin: const Offset(0.8, 0.8),
      duration: 400.ms,
      curve: Curves.easeOutBack,
    ),
  ];

  static List<Effect<dynamic>> get scaleBounce => [
    FadeEffect(duration: 200.ms),
    ScaleEffect(
      begin: const Offset(0.5, 0.5),
      duration: 600.ms,
      curve: Curves.elasticOut,
    ),
  ];

  static List<Effect<dynamic>> staggeredItem(int index) => [
    FadeEffect(
      delay: (index * 80).ms,
      duration: 400.ms,
      curve: Curves.easeOut,
    ),
    SlideEffect(
      delay: (index * 80).ms,
      begin: const Offset(0, 20),
      duration: 500.ms,
      curve: Curves.easeOutCubic,
    ),
  ];

  static List<Effect<dynamic>> staggeredGridItem(int index, {int crossAxisCount = 2}) {
    final row = index ~/ crossAxisCount;
    final col = index % crossAxisCount;
    final delay = ((row + col) * 100).ms;
    return [
      FadeEffect(delay: delay, duration: 400.ms, curve: Curves.easeOut),
      ScaleEffect(
        delay: delay,
        begin: const Offset(0.9, 0.9),
        duration: 500.ms,
        curve: Curves.easeOutBack,
      ),
    ];
  }

  static List<Effect<dynamic>> get tapFeedback => [
    ScaleEffect(
      begin: const Offset(1.0, 1.0),
      end: const Offset(0.96, 0.96),
      duration: 100.ms,
      curve: Curves.easeInOut,
    ),
    ScaleEffect(
      begin: const Offset(0.96, 0.96),
      end: const Offset(1.0, 1.0),
      duration: 200.ms,
      curve: Curves.easeOutBack,
    ),
  ];

  static List<Effect<dynamic>> get shimmer => [
    ShimmerEffect(
      duration: 1500.ms,
      curve: Curves.easeInOut,
      color: Colors.white.withValues(alpha: 0.3),
    ),
  ];

  static List<Effect<dynamic>> get notificationSlide => [
    SlideEffect(
      begin: const Offset(0, -100),
      duration: 400.ms,
      curve: Curves.easeOutBack,
    ),
    FadeEffect(duration: 300.ms),
  ];

  static List<Effect<dynamic>> get notificationExit => [
    SlideEffect(
      end: const Offset(0, -100),
      duration: 300.ms,
      curve: Curves.easeIn,
    ),
    FadeEffect(duration: 200.ms),
  ];

  static List<Effect<dynamic>> get pageEnter => [
    FadeEffect(duration: 300.ms, curve: Curves.easeOut),
    SlideEffect(
      begin: const Offset(0.1, 0),
      duration: 400.ms,
      curve: Curves.easeOutCubic,
    ),
  ];

  static List<Effect<dynamic>> get pulse => [
    ScaleEffect(
      begin: const Offset(1.0, 1.0),
      end: const Offset(1.05, 1.05),
      duration: 800.ms,
      curve: Curves.easeInOut,
    ),
    ScaleEffect(
      begin: const Offset(1.05, 1.05),
      end: const Offset(1.0, 1.0),
      duration: 800.ms,
      curve: Curves.easeInOut,
    ),
  ];

  static List<Effect<dynamic>> get spin => [
    RotateEffect(
      duration: 1200.ms,
      curve: Curves.linear,
    ),
  ];
}

extension AnimateWidgetExtension on Widget {
  Widget animateEntrance({int delayMs = 0}) {
    return animate(delay: delayMs.ms)
      .fade(duration: 400.ms, curve: Curves.easeOut)
      .slideY(
        begin: 0.1,
        duration: 500.ms,
        curve: Curves.easeOutCubic,
      );
  }

  Widget animateScale({int delayMs = 0}) {
    return animate(delay: delayMs.ms)
      .fade(duration: 300.ms)
      .scale(
        begin: const Offset(0.9, 0.9),
        duration: 400.ms,
        curve: Curves.easeOutBack,
      );
  }

  Widget animateStagger(int index) {
    return animate(delay: (index * 80).ms)
      .fade(duration: 400.ms)
      .slideY(
        begin: 0.1,
        duration: 500.ms,
        curve: Curves.easeOutCubic,
      );
  }
}