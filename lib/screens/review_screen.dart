import 'package:flutter/material.dart';

import '../core/theme.dart';
import '../models/quiz_result.dart';
import '../widgets/common.dart';
import '../widgets/option_tile.dart';

enum _Filter { all, correct, wrong }

class ReviewScreen extends StatefulWidget {
  const ReviewScreen({super.key, required this.result});

  final QuizResult result;

  @override
  State<ReviewScreen> createState() => _ReviewScreenState();
}

class _ReviewScreenState extends State<ReviewScreen> {
  _Filter _filter = _Filter.all;

  @override
  Widget build(BuildContext context) {
    final indexed = widget.result.answers.indexed
        .where(
          (e) => switch (_filter) {
            _Filter.all => true,
            _Filter.correct => e.$2.isCorrect,
            _Filter.wrong => !e.$2.isCorrect,
          },
        )
        .toList();

    return Scaffold(
      appBar: AppBar(title: const Text('مراجعة الإجابات')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 640),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
                child: SizedBox(
                  width: double.infinity,
                  child: SegmentedButton<_Filter>(
                    showSelectedIcon: false,
                    segments: [
                      ButtonSegment(
                        value: _Filter.all,
                        label: Text('الكل (${widget.result.total})'),
                      ),
                      ButtonSegment(
                        value: _Filter.correct,
                        label: Text('صحيحة (${widget.result.correct})'),
                      ),
                      ButtonSegment(
                        value: _Filter.wrong,
                        label: Text(
                          'خاطئة (${widget.result.total - widget.result.correct})',
                        ),
                      ),
                    ],
                    selected: {_filter},
                    onSelectionChanged: (s) =>
                        setState(() => _filter = s.first),
                  ),
                ),
              ),
              Expanded(
                child: indexed.isEmpty
                    ? const Center(child: Text('لا توجد أسئلة هنا'))
                    : ListView.separated(
                        padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                        itemCount: indexed.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 14),
                        itemBuilder: (context, i) => FadeSlideIn(
                          index: i.clamp(0, 6),
                          child: _ReviewCard(
                            number: indexed[i].$1 + 1,
                            answer: indexed[i].$2,
                          ),
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

class _ReviewCard extends StatelessWidget {
  const _ReviewCard({required this.number, required this.answer});

  final int number;
  final AnswerRecord answer;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final q = answer.question;
    final (Color color, String label) = answer.isCorrect
        ? (AppColors.correct, 'صحيحة')
        : answer.isUnanswered
        ? (AppColors.warning, 'بدون إجابة')
        : (AppColors.wrong, 'خاطئة');

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 14,
                  backgroundColor: color.withValues(alpha: 0.15),
                  child: Text(
                    '$number',
                    style: TextStyle(color: color, fontWeight: FontWeight.w800),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  label,
                  style: TextStyle(color: color, fontWeight: FontWeight.w700),
                ),
                const Spacer(),
                Icon(
                  Icons.timer_outlined,
                  size: 16,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: 4),
                Text(
                  '${answer.secondsTaken}ث',
                  style: theme.textTheme.bodySmall,
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              q.text,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 12),
            for (var i = 0; i < q.options.length; i++)
              if (i == q.answerIndex || i == answer.selectedIndex)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: OptionTile(
                    index: i,
                    text: q.options[i],
                    state: i == q.answerIndex
                        ? (answer.isCorrect
                              ? OptionState.selectedCorrect
                              : OptionState.revealedCorrect)
                        : OptionState.selectedWrong,
                  ),
                ),
            if (q.explanation != null)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primaryContainer.withValues(
                    alpha: 0.4,
                  ),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.info_outline_rounded,
                      size: 18,
                      color: theme.colorScheme.primary,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        q.explanation!,
                        style: const TextStyle(height: 1.5),
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
