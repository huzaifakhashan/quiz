import 'package:flutter/material.dart';

import '../core/theme.dart';

/// Circular countdown that shifts from green to amber to red as time runs out.
class TimerRing extends StatelessWidget {
  const TimerRing({
    super.key,
    required this.fraction,
    required this.seconds,
    this.size = 64,
  });

  final double fraction;
  final int seconds;
  final double size;

  Color get _color {
    if (fraction > 0.5) return AppColors.correct;
    if (fraction > 0.25) return AppColors.warning;
    return AppColors.wrong;
  }

  @override
  Widget build(BuildContext context) {
    final critical = fraction <= 0.25 && seconds > 0;
    return TweenAnimationBuilder<double>(
      tween: Tween(end: fraction.clamp(0, 1)),
      duration: const Duration(milliseconds: 900),
      curve: Curves.linear,
      builder: (context, value, _) => AnimatedScale(
        scale: critical && seconds.isOdd ? 1.08 : 1,
        duration: const Duration(milliseconds: 250),
        child: SizedBox.square(
          dimension: size,
          child: Stack(
            fit: StackFit.expand,
            children: [
              DecoratedBox(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.95),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(4),
                child: CircularProgressIndicator(
                  value: value,
                  strokeWidth: 5,
                  strokeCap: StrokeCap.round,
                  color: _color,
                  backgroundColor: _color.withValues(alpha: 0.15),
                ),
              ),
              Center(
                child: Text(
                  '$seconds',
                  style: TextStyle(
                    fontSize: size * 0.34,
                    fontWeight: FontWeight.w800,
                    color: _color,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
