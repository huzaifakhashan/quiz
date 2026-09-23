import 'package:flutter/material.dart';

import '../core/app_scope.dart';
import '../core/theme.dart';
import '../data/question_bank.dart';
import '../services/stats_service.dart';
import '../widgets/common.dart';

class StatsScreen extends StatelessWidget {
  const StatsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final stats = AppScope.of(context);
    final allCategories = [QuestionBank.mixed, ...QuestionBank.categories];

    return Scaffold(
      appBar: AppBar(title: const Text('إحصائياتي')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 640),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
            children: [
              GridView(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  mainAxisExtent: 140,
                ),
                children: [
                  StatTile(
                    icon: Icons.military_tech_rounded,
                    value: '${stats.level}',
                    label: 'المستوى',
                    color: theme.colorScheme.primary,
                  ),
                  StatTile(
                    icon: Icons.stars_rounded,
                    value: '${stats.totalScore}',
                    label: 'مجموع النقاط',
                    color: AppColors.gold,
                  ),
                  StatTile(
                    icon: Icons.quiz_rounded,
                    value: '${stats.gamesPlayed}',
                    label: 'اختبارات مكتملة',
                    color: Colors.teal,
                  ),
                  StatTile(
                    icon: Icons.track_changes_rounded,
                    value: '${(stats.accuracy * 100).round()}%',
                    label: 'دقة الإجابات',
                    color: AppColors.correct,
                  ),
                ],
              ),
              const SizedBox(height: 24),
              _SectionTitle('أفضل النتائج'),
              Card(
                child: Column(
                  children: [
                    for (final c in allCategories)
                      ListTile(
                        leading: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(colors: c.colors),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(c.icon, color: Colors.white, size: 20),
                        ),
                        title: Text(
                          c.title,
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                        trailing: Text(
                          stats.bestFor(c.id) > 0
                              ? '${stats.bestFor(c.id)}'
                              : '—',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              _SectionTitle('آخر الاختبارات'),
              if (stats.history.isEmpty)
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Column(
                      children: [
                        Icon(
                          Icons.history_toggle_off_rounded,
                          size: 48,
                          color: theme.colorScheme.outline,
                        ),
                        const SizedBox(height: 8),
                        const Text('لم تكمل أي اختبار بعد'),
                      ],
                    ),
                  ),
                )
              else
                for (final g in stats.history) _HistoryTile(game: g),
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: Text(
      text,
      style: Theme.of(
        context,
      ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
    ),
  );
}

class _HistoryTile extends StatelessWidget {
  const _HistoryTile({required this.game});

  final GameSummary game;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final ratio = game.total == 0 ? 0.0 : game.correct / game.total;
    final color = ratio >= 0.6
        ? AppColors.correct
        : ratio >= 0.3
        ? AppColors.warning
        : AppColors.wrong;
    final d = game.playedAt;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Card(
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 4,
          ),
          leading: SizedBox.square(
            dimension: 44,
            child: Stack(
              fit: StackFit.expand,
              children: [
                CircularProgressIndicator(
                  value: ratio,
                  strokeWidth: 4,
                  color: color,
                  backgroundColor: color.withValues(alpha: 0.15),
                ),
                Center(
                  child: Text(
                    '${game.correct}/${game.total}',
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
          ),
          title: Text(
            game.categoryTitle,
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
          subtitle: Text(
            '${game.difficultyLabel} • ${d.year}/${d.month}/${d.day}',
            style: theme.textTheme.bodySmall,
          ),
          trailing: Text(
            '${game.score}',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ),
    );
  }
}
