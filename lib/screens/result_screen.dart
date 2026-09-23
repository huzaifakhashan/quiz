import 'dart:math';

import 'package:flutter/material.dart';

import '../core/theme.dart';
import '../models/category.dart';
import '../models/quiz_result.dart';
import '../widgets/common.dart';
import 'quiz_screen.dart';
import 'review_screen.dart';

class ResultScreen extends StatelessWidget {
  const ResultScreen({
    super.key,
    required this.result,
    required this.category,
    required this.isNewBest,
    required this.questionCount,
  });

  final QuizResult result;
  final QuizCategory category;
  final bool isNewBest;
  final int questionCount;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: Stack(
        children: [
          if (result.stars >= 2) const Positioned.fill(child: _Confetti()),
          SafeArea(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 560),
                child: ListView(
                  padding: const EdgeInsets.all(20),
                  children: [
                    FadeSlideIn(
                      child: GradientCard(
                        colors: category.colors,
                        padding: const EdgeInsets.symmetric(
                          vertical: 28,
                          horizontal: 20,
                        ),
                        child: Column(
                          children: [
                            _Stars(count: result.stars),
                            const SizedBox(height: 12),
                            Text(
                              result.headline,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 26,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            Text(
                              '${category.title} • ${result.difficulty?.label ?? 'مختلط'}',
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.85),
                              ),
                            ),
                            const SizedBox(height: 20),
                            _ScoreRing(
                              accuracy: result.accuracy,
                              correct: result.correct,
                              total: result.total,
                            ),
                            const SizedBox(height: 20),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(
                                  Icons.stars_rounded,
                                  color: AppColors.gold,
                                  size: 28,
                                ),
                                const SizedBox(width: 6),
                                TweenAnimationBuilder<int>(
                                  tween: IntTween(begin: 0, end: result.score),
                                  duration: const Duration(milliseconds: 1200),
                                  curve: Curves.easeOutCubic,
                                  builder: (context, v, _) => Text(
                                    '$v نقطة',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 24,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            if (isNewBest && result.score > 0) ...[
                              const SizedBox(height: 12),
                              const InfoPill(
                                icon: Icons.emoji_events_rounded,
                                text: 'رقم قياسي جديد!',
                                color: AppColors.gold,
                                foreground: Colors.black87,
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    FadeSlideIn(
                      index: 2,
                      child: GridView(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 3,
                              mainAxisSpacing: 12,
                              crossAxisSpacing: 12,
                              mainAxisExtent: 140,
                            ),
                        children: [
                          StatTile(
                            icon: Icons.check_rounded,
                            value: '${result.correct}',
                            label: 'صحيحة',
                            color: AppColors.correct,
                          ),
                          StatTile(
                            icon: Icons.close_rounded,
                            value: '${result.wrong}',
                            label: 'خاطئة',
                            color: AppColors.wrong,
                          ),
                          StatTile(
                            icon: Icons.remove_rounded,
                            value: '${result.unanswered}',
                            label: 'بدون إجابة',
                            color: AppColors.warning,
                          ),
                          StatTile(
                            icon: Icons.local_fire_department_rounded,
                            value: '${result.bestStreak}',
                            label: 'أفضل سلسلة',
                            color: Colors.deepOrange,
                          ),
                          StatTile(
                            icon: Icons.timer_rounded,
                            value: formatDuration(result.totalSeconds),
                            label: 'الوقت',
                            color: theme.colorScheme.primary,
                          ),
                          StatTile(
                            icon: Icons.bolt_rounded,
                            value: result.total == 0
                                ? '-'
                                : '${(result.totalSeconds / result.total).toStringAsFixed(1)}ث',
                            label: 'متوسط الإجابة',
                            color: Colors.teal,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    FadeSlideIn(
                      index: 4,
                      child: Column(
                        children: [
                          FilledButton.icon(
                            onPressed: () =>
                                Navigator.of(context).pushReplacement(
                                  MaterialPageRoute(
                                    builder: (_) => QuizScreen(
                                      category: category,
                                      difficulty: result.difficulty,
                                      questionCount: questionCount,
                                    ),
                                  ),
                                ),
                            icon: const Icon(Icons.replay_rounded),
                            label: const Text('العب مجدداً'),
                          ),
                          const SizedBox(height: 12),
                          OutlinedButton.icon(
                            onPressed: () => Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => ReviewScreen(result: result),
                              ),
                            ),
                            icon: const Icon(Icons.fact_check_rounded),
                            label: const Text('مراجعة الإجابات'),
                          ),
                          const SizedBox(height: 4),
                          TextButton.icon(
                            onPressed: () => Navigator.of(context).pop(),
                            icon: const Icon(Icons.home_rounded),
                            label: const Text('الرئيسية'),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Stars extends StatelessWidget {
  const _Stars({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        for (var i = 0; i < 3; i++)
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: 1),
            duration: Duration(milliseconds: 600 + i * 250),
            curve: Curves.elasticOut,
            builder: (context, t, child) =>
                Transform.scale(scale: t, child: child),
            child: Padding(
              padding: EdgeInsets.only(bottom: i == 1 ? 12 : 0),
              child: Icon(
                Icons.star_rounded,
                size: i == 1 ? 64 : 48,
                color: i < count
                    ? AppColors.gold
                    : Colors.white.withValues(alpha: 0.3),
              ),
            ),
          ),
      ],
    );
  }
}

class _ScoreRing extends StatelessWidget {
  const _ScoreRing({
    required this.accuracy,
    required this.correct,
    required this.total,
  });

  final double accuracy;
  final int correct;
  final int total;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: accuracy),
      duration: const Duration(milliseconds: 1200),
      curve: Curves.easeOutCubic,
      builder: (context, v, _) => SizedBox.square(
        dimension: 140,
        child: Stack(
          fit: StackFit.expand,
          children: [
            CircularProgressIndicator(
              value: v,
              strokeWidth: 12,
              strokeCap: StrokeCap.round,
              color: Colors.white,
              backgroundColor: Colors.white.withValues(alpha: 0.2),
            ),
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '${(v * 100).round()}%',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 34,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  Text(
                    '$correct من $total',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.85),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Lightweight confetti burst drawn with a CustomPainter.
class _Confetti extends StatefulWidget {
  const _Confetti();

  @override
  State<_Confetti> createState() => _ConfettiState();
}

class _ConfettiState extends State<_Confetti>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 3200),
  )..forward();

  late final List<_Particle> _particles = List.generate(90, (_) {
    final r = Random();
    return _Particle(
      x: r.nextDouble(),
      delay: r.nextDouble() * 0.35,
      speed: 0.6 + r.nextDouble() * 0.6,
      drift: (r.nextDouble() - 0.5) * 0.3,
      spin: r.nextDouble() * 8,
      size: 6 + r.nextDouble() * 6,
      color: _colors[r.nextInt(_colors.length)],
    );
  });

  static const _colors = [
    Color(0xFFFFC53D),
    Color(0xFF22C55E),
    Color(0xFF3B82F6),
    Color(0xFFEF4444),
    Color(0xFFA855F7),
    Color(0xFFF97316),
  ];

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) => CustomPaint(
          painter: _ConfettiPainter(_particles, _controller.value),
        ),
      ),
    );
  }
}

class _Particle {
  const _Particle({
    required this.x,
    required this.delay,
    required this.speed,
    required this.drift,
    required this.spin,
    required this.size,
    required this.color,
  });

  final double x, delay, speed, drift, spin, size;
  final Color color;
}

class _ConfettiPainter extends CustomPainter {
  _ConfettiPainter(this.particles, this.t);

  final List<_Particle> particles;
  final double t;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint();
    for (final p in particles) {
      final local = ((t - p.delay) / (1 - p.delay)).clamp(0.0, 1.0);
      if (local <= 0) continue;
      final y = -20 + local * p.speed * (size.height + 40);
      final x = (p.x + p.drift * local) * size.width;
      paint.color = p.color.withValues(alpha: (1 - local).clamp(0, 1));
      canvas
        ..save()
        ..translate(x, y)
        ..rotate(p.spin * local * pi)
        ..drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromCenter(
              center: Offset.zero,
              width: p.size,
              height: p.size * 0.5,
            ),
            const Radius.circular(2),
          ),
          paint,
        )
        ..restore();
    }
  }

  @override
  bool shouldRepaint(_ConfettiPainter old) => old.t != t;
}
