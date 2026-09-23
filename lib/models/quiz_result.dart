import 'question.dart';

class AnswerRecord {
  const AnswerRecord({
    required this.question,
    required this.selectedIndex,
    required this.secondsTaken,
  });

  final Question question;

  /// `null` when the time ran out or the question was skipped.
  final int? selectedIndex;
  final int secondsTaken;

  bool get isCorrect => selectedIndex == question.answerIndex;
  bool get isUnanswered => selectedIndex == null;
}

class QuizResult {
  const QuizResult({
    required this.categoryId,
    required this.categoryTitle,
    required this.difficulty,
    required this.answers,
    required this.score,
    required this.bestStreak,
    required this.totalSeconds,
  });

  final String categoryId;
  final String categoryTitle;

  /// `null` means mixed difficulty.
  final Difficulty? difficulty;
  final List<AnswerRecord> answers;
  final int score;
  final int bestStreak;
  final int totalSeconds;

  int get total => answers.length;
  int get correct => answers.where((a) => a.isCorrect).length;
  int get wrong => answers.where((a) => !a.isCorrect && !a.isUnanswered).length;
  int get unanswered => answers.where((a) => a.isUnanswered).length;
  double get accuracy => total == 0 ? 0 : correct / total;

  int get stars {
    if (accuracy >= 0.9) return 3;
    if (accuracy >= 0.6) return 2;
    if (accuracy >= 0.3) return 1;
    return 0;
  }

  String get headline => switch (stars) {
    3 => 'أداء أسطوري!',
    2 => 'عمل رائع!',
    1 => 'بداية جيدة',
    _ => 'حاول مرة أخرى',
  };
}
