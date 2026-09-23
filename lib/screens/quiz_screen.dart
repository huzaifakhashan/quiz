import 'package:flutter/material.dart';

import '../controllers/quiz_controller.dart';
import '../core/app_scope.dart';
import '../core/haptics.dart';
import '../core/theme.dart';
import '../models/category.dart';
import '../models/question.dart';
import '../widgets/common.dart';
import '../widgets/option_tile.dart';
import '../widgets/timer_ring.dart';
import 'result_screen.dart';

class QuizScreen extends StatefulWidget {
  const QuizScreen({
    super.key,
    required this.category,
    required this.difficulty,
    required this.questionCount,
  });

  final QuizCategory category;
  final Difficulty? difficulty;
  final int questionCount;

  @override
  State<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen> {
  late final QuizController _quiz;
  late final AppLifecycleListener _lifecycle;
  QuestionPhase _lastPhase = QuestionPhase.answering;
  bool _finishing = false;

  @override
  void initState() {
    super.initState();
    _quiz = QuizController(
      category: widget.category,
      difficulty: widget.difficulty,
      questionCount: widget.questionCount,
    )..addListener(_onQuizChanged);
    _quiz.start();
    // Pause the clock automatically when the app goes to the background.
    _lifecycle = AppLifecycleListener(
      onHide: () {
        if (!_quiz.isPaused && !_quiz.isRevealed) _showPauseDialog();
      },
    );
  }

  @override
  void dispose() {
    _lifecycle.dispose();
    _quiz.dispose();
    super.dispose();
  }

  void _onQuizChanged() {
    if (_quiz.phase != _lastPhase && _quiz.isRevealed) {
      final stats = AppScope.read(context);
      _quiz.selected == _quiz.current.answerIndex
          ? Haptics.success(stats)
          : Haptics.error(stats);
    }
    _lastPhase = _quiz.phase;
  }

  void _next() {
    Haptics.tap(AppScope.read(context));
    if (!_quiz.next()) _finish();
  }

  void _skip() {
    Haptics.tap(AppScope.read(context));
    if (!_quiz.useSkip()) _finish();
  }

  Future<void> _finish() async {
    if (_finishing) return;
    _finishing = true;
    final result = _quiz.buildResult();
    final isNewBest = await AppScope.read(context).record(result);
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 500),
        pageBuilder: (_, _, _) => ResultScreen(
          result: result,
          category: widget.category,
          isNewBest: isNewBest,
          questionCount: widget.questionCount,
        ),
        transitionsBuilder: (_, anim, _, child) =>
            FadeTransition(opacity: anim, child: child),
      ),
    );
  }

  Future<void> _showPauseDialog() async {
    _quiz.pause();
    final quit = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        icon: const Icon(Icons.pause_circle_filled_rounded, size: 48),
        title: const Text('الاختبار متوقف'),
        content: const Text(
          'هل تريد المتابعة أم الخروج؟ لن يتم حفظ تقدمك عند الخروج.',
          textAlign: TextAlign.center,
        ),
        actionsAlignment: MainAxisAlignment.center,
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.wrong),
            child: const Text('خروج'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(minimumSize: const Size(120, 48)),
            onPressed: () => Navigator.pop(context, false),
            child: const Text('متابعة'),
          ),
        ],
      ),
    );
    if (!mounted) return;
    if (quit == true) {
      Navigator.of(context).pop();
    } else {
      _quiz.resume();
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _showPauseDialog();
      },
      child: Scaffold(
        body: ListenableBuilder(
          listenable: _quiz,
          builder: (context, _) {
            if (_quiz.total == 0) {
              return const Center(child: Text('لا توجد أسئلة متاحة'));
            }
            return Column(
              children: [
                _Header(
                  quiz: _quiz,
                  colors: widget.category.colors,
                  title: widget.category.title,
                  onPause: _showPauseDialog,
                ),
                Expanded(
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 640),
                      child: _Body(quiz: _quiz),
                    ),
                  ),
                ),
                _BottomBar(quiz: _quiz, onNext: _next, onSkip: _skip),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({
    required this.quiz,
    required this.colors,
    required this.title,
    required this.onPause,
  });

  final QuizController quiz;
  final List<Color> colors;
  final String title;
  final VoidCallback onPause;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: colors,
          begin: AlignmentDirectional.topStart,
          end: AlignmentDirectional.bottomEnd,
        ),
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(32)),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 4, 12, 20),
          child: Column(
            children: [
              Row(
                children: [
                  IconButton(
                    tooltip: 'إيقاف مؤقت',
                    onPressed: onPause,
                    icon: const Icon(Icons.pause_rounded, color: Colors.white),
                  ),
                  Expanded(
                    child: Column(
                      children: [
                        Text(
                          title,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        Text(
                          'السؤال ${quiz.index + 1} من ${quiz.total}',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.85),
                          ),
                        ),
                      ],
                    ),
                  ),
                  TimerRing(
                    fraction: quiz.timeFraction,
                    seconds: quiz.secondsLeft,
                    size: 52,
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: _SegmentedProgress(quiz: quiz),
              ),
              const SizedBox(height: 14),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  InfoPill(icon: Icons.stars_rounded, text: '${quiz.score}'),
                  const SizedBox(width: 10),
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300),
                    transitionBuilder: (child, anim) =>
                        ScaleTransition(scale: anim, child: child),
                    child: InfoPill(
                      key: ValueKey(quiz.streak),
                      icon: Icons.local_fire_department_rounded,
                      text: 'x${quiz.streak}',
                      color: quiz.streak >= 3
                          ? AppColors.warning
                          : Colors.white.withValues(alpha: 0.2),
                    ),
                  ),
                  const SizedBox(width: 10),
                  InfoPill(
                    icon: Icons.signal_cellular_alt_rounded,
                    text: quiz.current.difficulty.label,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SegmentedProgress extends StatelessWidget {
  const _SegmentedProgress({required this.quiz});

  final QuizController quiz;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (var i = 0; i < quiz.total; i++)
          Expanded(
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              height: 6,
              margin: const EdgeInsets.symmetric(horizontal: 2),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(99),
                color: i < quiz.index || (i == quiz.index && quiz.isRevealed)
                    ? Colors.white
                    : i == quiz.index
                    ? Colors.white.withValues(alpha: 0.6)
                    : Colors.white.withValues(alpha: 0.25),
              ),
            ),
          ),
      ],
    );
  }
}

class _Body extends StatelessWidget {
  const _Body({required this.quiz});

  final QuizController quiz;

  OptionState _stateFor(int i) {
    final q = quiz.current;
    if (!quiz.isRevealed) {
      return quiz.hiddenOptions.contains(i)
          ? OptionState.hidden
          : OptionState.idle;
    }
    if (i == q.answerIndex) {
      return quiz.selected == i
          ? OptionState.selectedCorrect
          : OptionState.revealedCorrect;
    }
    if (i == quiz.selected) return OptionState.selectedWrong;
    return quiz.hiddenOptions.contains(i)
        ? OptionState.hidden
        : OptionState.dimmed;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final q = quiz.current;

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 400),
      switchInCurve: Curves.easeOutCubic,
      switchOutCurve: Curves.easeInCubic,
      transitionBuilder: (child, anim) => FadeTransition(
        opacity: anim,
        child: SlideTransition(
          position: Tween(
            begin: const Offset(0, 0.05),
            end: Offset.zero,
          ).animate(anim),
          child: child,
        ),
      ),
      child: ListView(
        key: ValueKey(quiz.index),
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 16),
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 28,
                  ),
                  child: Text(
                    q.text,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                      height: 1.5,
                    ),
                  ),
                ),
              ),
              if (quiz.isRevealed && quiz.lastPointsGained > 0)
                PositionedDirectional(
                  top: -14,
                  end: 16,
                  child: _PointsBadge(points: quiz.lastPointsGained),
                ),
            ],
          ),
          const SizedBox(height: 20),
          for (var i = 0; i < q.options.length; i++) ...[
            FadeSlideIn(
              index: i,
              child: OptionTile(
                index: i,
                text: q.options[i],
                state: _stateFor(i),
                onTap: () {
                  Haptics.tap(AppScope.read(context));
                  quiz.select(i);
                },
              ),
            ),
            const SizedBox(height: 12),
          ],
          if (quiz.isRevealed) _Feedback(quiz: quiz),
        ],
      ),
    );
  }
}

class _PointsBadge extends StatelessWidget {
  const _PointsBadge({required this.points});

  final int points;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 500),
      curve: Curves.elasticOut,
      builder: (context, t, child) => Transform.scale(scale: t, child: child),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: AppColors.correct,
          borderRadius: BorderRadius.circular(99),
          boxShadow: [
            BoxShadow(
              color: AppColors.correct.withValues(alpha: 0.4),
              blurRadius: 10,
            ),
          ],
        ),
        child: Text(
          '+$points',
          textDirection: TextDirection.ltr,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }
}

class _Feedback extends StatelessWidget {
  const _Feedback({required this.quiz});

  final QuizController quiz;

  @override
  Widget build(BuildContext context) {
    final q = quiz.current;
    final correct = quiz.selected == q.answerIndex;
    final timedOut = quiz.selected == null;

    final (Color color, IconData icon, String title) = correct
        ? (AppColors.correct, Icons.celebration_rounded, _praise(quiz.streak))
        : timedOut
        ? (AppColors.warning, Icons.timer_off_rounded, 'انتهى الوقت!')
        : (
            AppColors.wrong,
            Icons.sentiment_dissatisfied_rounded,
            'إجابة خاطئة',
          );

    return FadeSlideIn(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: color.withValues(alpha: 0.4)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
            if (!correct) ...[
              const SizedBox(height: 6),
              Text(
                'الإجابة الصحيحة: ${q.correctAnswer}',
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
            ],
            if (q.explanation != null) ...[
              const SizedBox(height: 6),
              Text(q.explanation!, style: const TextStyle(height: 1.5)),
            ],
          ],
        ),
      ),
    );
  }

  static String _praise(int streak) => switch (streak) {
    >= 5 => 'لا يمكن إيقافك! 🔥',
    >= 3 => 'سلسلة رائعة! 🔥',
    _ => 'إجابة صحيحة!',
  };
}

class _BottomBar extends StatelessWidget {
  const _BottomBar({
    required this.quiz,
    required this.onNext,
    required this.onSkip,
  });

  final QuizController quiz;
  final VoidCallback onNext;
  final VoidCallback onSkip;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 16),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 640),
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 250),
            child: quiz.isRevealed
                ? FilledButton.icon(
                    key: const ValueKey('next'),
                    onPressed: onNext,
                    icon: Icon(
                      quiz.isLast
                          ? Icons.flag_rounded
                          : Icons.arrow_forward_rounded,
                    ),
                    label: Text(quiz.isLast ? 'عرض النتيجة' : 'السؤال التالي'),
                  )
                : Row(
                    key: const ValueKey('lifelines'),
                    children: [
                      _Lifeline(
                        icon: Icons.filter_2_rounded,
                        label: '50:50',
                        enabled: quiz.fiftyAvailable,
                        onTap: quiz.useFiftyFifty,
                      ),
                      const SizedBox(width: 10),
                      _Lifeline(
                        icon: Icons.more_time_rounded,
                        label: 'وقت إضافي',
                        enabled: quiz.timeAvailable,
                        onTap: quiz.useExtraTime,
                      ),
                      const SizedBox(width: 10),
                      _Lifeline(
                        icon: Icons.skip_next_rounded,
                        label: 'تخطي',
                        enabled: quiz.skipAvailable,
                        onTap: onSkip,
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}

class _Lifeline extends StatelessWidget {
  const _Lifeline({
    required this.icon,
    required this.label,
    required this.enabled,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: OutlinedButton(
        onPressed: enabled ? onTap : null,
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 10),
          minimumSize: const Size.fromHeight(56),
          textStyle: Theme.of(
            context,
          ).textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w700),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 20),
            const SizedBox(height: 2),
            FittedBox(child: Text(label)),
          ],
        ),
      ),
    );
  }
}
