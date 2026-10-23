import 'dart:math';
import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../theme/app_colors.dart';

class CelebrationNotifier extends Notifier<int> {
  late ConfettiController controller;

  @override
  int build() {
    controller = ConfettiController(duration: const Duration(seconds: 2));
    ref.onDispose(() => controller.dispose());
    return 0;
  }

  void celebrate() {
    HapticFeedback.heavyImpact();
    controller.play();
    state++;
  }
}

final celebrationProvider = NotifierProvider<CelebrationNotifier, int>(() {
  return CelebrationNotifier();
});

class ConfettiOverlay extends ConsumerWidget {
  const ConfettiOverlay({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(celebrationProvider);
    final controller = ref.read(celebrationProvider.notifier).controller;

    return Stack(
      children: [
        child,
        Align(
          alignment: Alignment.topCenter,
          child: ConfettiWidget(
            confettiController: controller,
            blastDirection: pi / 2,
            maxBlastForce: 8,
            minBlastForce: 3,
            emissionFrequency: 0.05,
            numberOfParticles: 25,
            gravity: 0.25,
            colors: const [
              AppColors.primary,
              AppColors.secondary,
              AppColors.tertiary,
              Color(0xFF3B82F6),
              Color(0xFFEC4899),
            ],
          ),
        ),
      ],
    );
  }
}
