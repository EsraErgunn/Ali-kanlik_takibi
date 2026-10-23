import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../core/theme/app_colors.dart';
import '../../../domain/plant_stage.dart';

class SwayingPlant extends StatefulWidget {
  const SwayingPlant({
    super.key,
    required this.stage,
    this.wilted = false,
    this.height,
    this.phaseOffset = 0.0,
    this.duration = const Duration(seconds: 3),
  });

  final PlantStage stage;
  final bool wilted;
  final double? height;
  final double phaseOffset;
  final Duration duration;

  @override
  State<SwayingPlant> createState() => _SwayingPlantState();
}

class _SwayingPlantState extends State<SwayingPlant>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  static const List<double> _desaturateMatrix = [
    0.2126 + 0.7874 * 0.25, 0.7152 - 0.7152 * 0.25, 0.0722 - 0.0722 * 0.25, 0, 0,
    0.2126 - 0.2126 * 0.25, 0.7152 + 0.2848 * 0.25, 0.0722 - 0.0722 * 0.25, 0, 0,
    0.2126 - 0.2126 * 0.25, 0.7152 - 0.7152 * 0.25, 0.0722 + 0.9278 * 0.25, 0, 0,
    0, 0, 0, 1, 0,
  ];

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final plantWidget = child ?? _buildPlantDisplay(context);
        if (widget.stage == PlantStage.seed) {
          return plantWidget;
        }

        final t = (_controller.value * 2 * math.pi) + widget.phaseOffset;
        final windAngle = 0.05 * math.sin(t) + 0.015 * math.sin(3 * t + 1);
        final finalAngle = widget.wilted ? windAngle + 0.10 : windAngle;

        return Transform.rotate(
          angle: finalAngle,
          alignment: Alignment.bottomCenter,
          child: plantWidget,
        );
      },
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 500),
        transitionBuilder: (child, animation) {
          return ScaleTransition(
            scale: animation,
            alignment: Alignment.bottomCenter,
            child: child,
          );
        },
        child: _buildPlantDisplay(context),
      ),
    );
  }

  Widget _buildPlantDisplay(BuildContext context) {
    final plantHeight = widget.height ?? 110.h;
    Widget plantCore = Image.asset(
      'assets/plant/stage_${widget.stage.index}.png',
      height: plantHeight,
      fit: BoxFit.contain,
      errorBuilder: (context, error, stackTrace) => _PlantIconPlaceholder(
        stage: widget.stage,
        height: plantHeight,
      ),
    );

    if (widget.wilted) {
      plantCore = ColorFiltered(
        colorFilter: const ColorFilter.matrix(_desaturateMatrix),
        child: plantCore,
      );
    }

    return KeyedSubtree(
      key: ValueKey('stage_${widget.stage.name}_wilted_${widget.wilted}'),
      child: plantCore,
    );
  }
}

class _PlantIconPlaceholder extends StatelessWidget {
  const _PlantIconPlaceholder({
    required this.stage,
    required this.height,
  });

  final PlantStage stage;
  final double height;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: height * 0.65,
              height: height * 0.65,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    AppColors.primaryContainer.withValues(alpha: 0.8),
                    AppColors.primaryContainer.withValues(alpha: 0.2),
                  ],
                ),
              ),
              child: Center(
                child: Text(
                  stage.emoji,
                  style: TextStyle(fontSize: (height * 0.38).sp),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
