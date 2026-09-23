import 'dart:math';

enum Difficulty {
  easy('سهل', 20, 10),
  medium('متوسط', 18, 20),
  hard('صعب', 15, 30);

  const Difficulty(this.label, this.seconds, this.points);

  final String label;

  /// Time allowed per question.
  final int seconds;

  /// Base points awarded for a correct answer.
  final int points;
}

class Question {
  const Question({
    required this.text,
    required this.options,
    required this.answerIndex,
    required this.difficulty,
    this.explanation,
  }) : assert(answerIndex >= 0 && answerIndex < options.length);

  final String text;
  final List<String> options;
  final int answerIndex;
  final Difficulty difficulty;
  final String? explanation;

  String get correctAnswer => options[answerIndex];

  /// Returns a copy with options shuffled, keeping the correct answer tracked.
  Question shuffled(Random random) {
    final indices = List<int>.generate(options.length, (i) => i)
      ..shuffle(random);
    return Question(
      text: text,
      options: [for (final i in indices) options[i]],
      answerIndex: indices.indexOf(answerIndex),
      difficulty: difficulty,
      explanation: explanation,
    );
  }
}
