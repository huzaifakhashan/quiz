import 'package:flutter/material.dart';

import '../core/app_scope.dart';
import '../core/theme.dart';
import '../data/question_bank.dart';
import '../models/category.dart';
import '../models/question.dart';
import '../widgets/common.dart';
import 'quiz_screen.dart';
import 'settings_sheet.dart';
import 'stats_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final stats = AppScope.of(context);

    return Scaffold(
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
              sliver: SliverToBoxAdapter(
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'أهلاً بك 👋',
                            style: theme.textTheme.bodyLarge?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                          Text(
                            'جاهز للتحدي؟',
                            style: theme.textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton.filledTonal(
                      tooltip: 'الإحصائيات',
                      onPressed: () => Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const StatsScreen()),
                      ),
                      icon: const Icon(Icons.insights_rounded),
                    ),
                    const SizedBox(width: 8),
                    IconButton.filledTonal(
                      tooltip: 'الإعدادات',
                      onPressed: () => showSettingsSheet(context),
                      icon: const Icon(Icons.tune_rounded),
                    ),
                  ],
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
              sliver: SliverToBoxAdapter(
                child: FadeSlideIn(
                  child: _LevelCard(
                    level: stats.level,
                    progress: stats.levelProgress,
                    totalScore: stats.totalScore,
                    games: stats.gamesPlayed,
                    accuracy: stats.accuracy,
                  ),
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
              sliver: SliverToBoxAdapter(
                child: FadeSlideIn(
                  index: 1,
                  child: _MixedBanner(
                    best: stats.bestFor(QuestionBank.mixed.id),
                    onTap: () => showQuizSetup(context, QuestionBank.mixed),
                  ),
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 28, 20, 12),
              sliver: SliverToBoxAdapter(
                child: Text(
                  'الفئات',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 28),
              sliver: SliverGrid.builder(
                gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                  maxCrossAxisExtent: 240,
                  mainAxisSpacing: 16,
                  crossAxisSpacing: 16,
                  childAspectRatio: 0.85,
                ),
                itemCount: QuestionBank.categories.length,
                itemBuilder: (context, i) {
                  final category = QuestionBank.categories[i];
                  return FadeSlideIn(
                    index: i + 2,
                    child: _CategoryCard(
                      category: category,
                      best: stats.bestFor(category.id),
                      onTap: () => showQuizSetup(context, category),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LevelCard extends StatelessWidget {
  const _LevelCard({
    required this.level,
    required this.progress,
    required this.totalScore,
    required this.games,
    required this.accuracy,
  });

  final int level;
  final double progress;
  final int totalScore;
  final int games;
  final double accuracy;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  width: 52,
                  height: 52,
                  alignment: Alignment.center,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(colors: AppColors.brandGradient),
                  ),
                  child: Text(
                    '$level',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'المستوى $level',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      Text(
                        '${300 - (progress * 300).round()} نقطة للمستوى التالي',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.stars_rounded, color: AppColors.gold),
                const SizedBox(width: 4),
                Text(
                  '$totalScore',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            ClipRRect(
              borderRadius: BorderRadius.circular(99),
              child: TweenAnimationBuilder<double>(
                tween: Tween(begin: 0, end: progress),
                duration: const Duration(milliseconds: 900),
                curve: Curves.easeOutCubic,
                builder: (context, v, _) =>
                    LinearProgressIndicator(value: v, minHeight: 10),
              ),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                _MiniStat(label: 'اختبارات', value: '$games'),
                _MiniStat(
                  label: 'الدقة',
                  value: '${(accuracy * 100).round()}%',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  const _MiniStat({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Expanded(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            label,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            value,
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _MixedBanner extends StatelessWidget {
  const _MixedBanner({required this.best, required this.onTap});

  final int best;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final mixed = QuestionBank.mixed;
    return GradientCard(
      colors: mixed.colors,
      onTap: onTap,
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const InfoPill(icon: Icons.bolt_rounded, text: 'الوضع السريع'),
                const SizedBox(height: 10),
                Text(
                  mixed.title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                Text(
                  '${mixed.subtitle} • ${mixed.questions.length} سؤالاً',
                  style: TextStyle(color: Colors.white.withValues(alpha: 0.85)),
                ),
                if (best > 0) ...[
                  const SizedBox(height: 8),
                  Text(
                    'أفضل نتيجة: $best',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 12),
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.play_arrow_rounded,
              color: Colors.white,
              size: 38,
            ),
          ),
        ],
      ),
    );
  }
}

class _CategoryCard extends StatelessWidget {
  const _CategoryCard({
    required this.category,
    required this.best,
    required this.onTap,
  });

  final QuizCategory category;
  final int best;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GradientCard(
      colors: category.colors,
      padding: const EdgeInsets.all(16),
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.25),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(category.icon, color: Colors.white, size: 28),
          ),
          const Spacer(),
          Text(
            category.title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 19,
              fontWeight: FontWeight.w800,
            ),
          ),
          Text(
            category.subtitle,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.9),
              fontSize: 12,
              height: 1.3,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(
                Icons.emoji_events_rounded,
                size: 16,
                color: Colors.white.withValues(alpha: 0.9),
              ),
              const SizedBox(width: 4),
              Flexible(
                child: Text(
                  best > 0 ? '$best' : 'لم تلعب بعد',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Bottom sheet for picking difficulty and number of questions.
Future<void> showQuizSetup(BuildContext context, QuizCategory category) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    builder: (_) => _QuizSetupSheet(category: category),
  );
}

class _QuizSetupSheet extends StatefulWidget {
  const _QuizSetupSheet({required this.category});

  final QuizCategory category;

  @override
  State<_QuizSetupSheet> createState() => _QuizSetupSheetState();
}

class _QuizSetupSheetState extends State<_QuizSetupSheet> {
  Difficulty? _difficulty;
  int _count = 10;

  int get _available => widget.category.byDifficulty(_difficulty).length;

  List<int> get _countOptions {
    final opts = {5, 10, 20}.where((n) => n <= _available).toSet();
    if (_available < 20) opts.add(_available);
    return opts.toList()..sort();
  }

  void _normalizeCount() {
    final opts = _countOptions;
    if (!opts.contains(_count)) {
      _count = opts.lastWhere((n) => n <= _count, orElse: () => opts.last);
    }
  }

  @override
  void initState() {
    super.initState();
    _normalizeCount();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final category = widget.category;

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(colors: category.colors),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(category.icon, color: Colors.white),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        category.title,
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      Text(
                        category.subtitle,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Text(
              'مستوى الصعوبة',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: SegmentedButton<Difficulty?>(
                showSelectedIcon: false,
                segments: [
                  const ButtonSegment(value: null, label: Text('مختلط')),
                  for (final d in Difficulty.values)
                    ButtonSegment(value: d, label: Text(d.label)),
                ],
                selected: {_difficulty},
                onSelectionChanged: (s) => setState(() {
                  _difficulty = s.first;
                  _normalizeCount();
                }),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _difficulty == null
                  ? 'الوقت ونقاط كل سؤال حسب صعوبته'
                  : '${_difficulty!.seconds} ثانية لكل سؤال • ${_difficulty!.points} نقطة أساسية',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'عدد الأسئلة',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 10,
              children: [
                for (final n in _countOptions)
                  ChoiceChip(
                    label: Text('$n'),
                    selected: _count == n,
                    onSelected: (_) => setState(() => _count = n),
                  ),
              ],
            ),
            const SizedBox(height: 20),
            const _RulesRow(),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: () {
                final navigator = Navigator.of(context);
                navigator.pop();
                navigator.push(
                  MaterialPageRoute(
                    builder: (_) => QuizScreen(
                      category: category,
                      difficulty: _difficulty,
                      questionCount: _count,
                    ),
                  ),
                );
              },
              icon: const Icon(Icons.play_arrow_rounded),
              label: const Text('ابدأ الاختبار'),
            ),
          ],
        ),
      ),
    );
  }
}

class _RulesRow extends StatelessWidget {
  const _RulesRow();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    Widget rule(IconData icon, String text) => Expanded(
      child: Column(
        children: [
          Icon(icon, color: scheme.primary),
          const SizedBox(height: 4),
          Text(
            text,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
      decoration: BoxDecoration(
        color: scheme.primaryContainer.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          rule(Icons.speed_rounded, 'أجب أسرع\nلنقاط أكثر'),
          rule(
            Icons.local_fire_department_rounded,
            'سلسلة إجابات\nتمنح مكافأة',
          ),
          rule(Icons.support_rounded, '3 وسائل\nمساعدة'),
        ],
      ),
    );
  }
}
