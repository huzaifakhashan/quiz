import 'package:flutter/material.dart';

import '../core/theme.dart';

enum OptionState {
  idle,
  selectedCorrect,
  selectedWrong,
  revealedCorrect,
  dimmed,
  hidden,
}

const optionLetters = ['أ', 'ب', 'ج', 'د', 'هـ', 'و'];

class OptionTile extends StatelessWidget {
  const OptionTile({
    super.key,
    required this.index,
    required this.text,
    required this.state,
    this.onTap,
  });

  final int index;
  final String text;
  final OptionState state;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    final (Color bg, Color border, Color fg, IconData? icon) = switch (state) {
      OptionState.selectedCorrect || OptionState.revealedCorrect => (
        AppColors.correct.withValues(alpha: 0.14),
        AppColors.correct,
        AppColors.correct,
        Icons.check_circle_rounded,
      ),
      OptionState.selectedWrong => (
        AppColors.wrong.withValues(alpha: 0.12),
        AppColors.wrong,
        AppColors.wrong,
        Icons.cancel_rounded,
      ),
      OptionState.dimmed || OptionState.hidden => (
        scheme.surfaceContainerLow,
        scheme.outlineVariant.withValues(alpha: 0.4),
        scheme.onSurface.withValues(alpha: 0.4),
        null,
      ),
      OptionState.idle => (
        scheme.surfaceContainerLowest,
        scheme.outlineVariant,
        scheme.onSurface,
        null,
      ),
    };

    final hidden = state == OptionState.hidden;

    Widget tile = AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOut,
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: border,
          width: state == OptionState.idle ? 1.2 : 2,
        ),
      ),
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: hidden ? null : onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            child: Row(
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  width: 36,
                  height: 36,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: state == OptionState.idle
                        ? scheme.primaryContainer
                        : border.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    optionLetters[index],
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      color: state == OptionState.idle
                          ? scheme.onPrimaryContainer
                          : fg,
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    text,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: fg,
                      decoration: hidden ? TextDecoration.lineThrough : null,
                    ),
                  ),
                ),
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 250),
                  transitionBuilder: (child, anim) =>
                      ScaleTransition(scale: anim, child: child),
                  child: icon == null
                      ? const SizedBox(width: 24)
                      : Icon(icon, key: ValueKey(icon), color: fg),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    if (state == OptionState.selectedWrong) {
      tile = _Shake(child: tile);
    }

    return AnimatedOpacity(
      duration: const Duration(milliseconds: 300),
      opacity: hidden ? 0.35 : 1,
      child: tile,
    );
  }
}

/// Quick horizontal shake used to emphasize a wrong answer.
class _Shake extends StatelessWidget {
  const _Shake({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 450),
      builder: (context, t, child) {
        final dx = (1 - t) * 10 * _wave(t * 4);
        return Transform.translate(offset: Offset(dx, 0), child: child);
      },
      child: child,
    );
  }

  static double _wave(double x) {
    final f = x - x.floor();
    return f < 0.5 ? 4 * f - 1 : 3 - 4 * f;
  }
}
