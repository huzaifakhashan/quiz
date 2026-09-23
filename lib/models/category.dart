import 'package:flutter/material.dart';

import 'question.dart';

class QuizCategory {
  const QuizCategory({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.colors,
    required this.questions,
  });

  final String id;
  final String title;
  final String subtitle;
  final IconData icon;

  /// Gradient colors used for the category card and quiz header.
  final List<Color> colors;
  final List<Question> questions;

  List<Question> byDifficulty(Difficulty? difficulty) => difficulty == null
      ? questions
      : questions.where((q) => q.difficulty == difficulty).toList();
}
