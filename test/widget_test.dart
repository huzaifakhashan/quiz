import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:quiz/controllers/quiz_controller.dart';
import 'package:quiz/data/question_bank.dart';
import 'package:quiz/models/question.dart';

void main() {
  group('QuestionBank', () {
    test('every category has questions of every difficulty', () {
      for (final c in QuestionBank.categories) {
        for (final d in Difficulty.values) {
          expect(c.byDifficulty(d), isNotEmpty, reason: '${c.id} / ${d.name}');
        }
      }
    });

    test('options are unique within each question', () {
      for (final q in QuestionBank.mixed.questions) {
        expect(q.options.toSet().length, q.options.length, reason: q.text);
      }
    });
  });

  test('shuffling keeps the correct answer', () {
    final q = QuestionBank.mixed.questions.first;
    for (var seed = 0; seed < 20; seed++) {
      expect(q.shuffled(Random(seed)).correctAnswer, q.correctAnswer);
    }
  });

  group('QuizController', () {
    QuizController make({int count = 5}) => QuizController(
      category: QuestionBank.mixed,
      difficulty: Difficulty.easy,
      questionCount: count,
      random: Random(1),
    )..start();

    test('limits the number of questions', () {
      final quiz = make(count: 5);
      expect(quiz.total, 5);
      quiz.dispose();
    });

    test('correct answer adds points and streak', () {
      final quiz = make();
      quiz.select(quiz.current.answerIndex);
      expect(quiz.isRevealed, isTrue);
      expect(quiz.score, greaterThanOrEqualTo(Difficulty.easy.points));
      expect(quiz.streak, 1);
      quiz.dispose();
    });

    test('wrong answer resets streak and gives no points', () {
      final quiz = make();
      quiz.select(quiz.current.answerIndex);
      quiz.next();
      final wrong =
          (quiz.current.answerIndex + 1) % quiz.current.options.length;
      final before = quiz.score;
      quiz.select(wrong);
      expect(quiz.streak, 0);
      expect(quiz.score, before);
      quiz.dispose();
    });

    test('50:50 hides exactly two wrong options', () {
      final quiz = make();
      quiz.useFiftyFifty();
      expect(quiz.hiddenOptions.length, 2);
      expect(quiz.hiddenOptions, isNot(contains(quiz.current.answerIndex)));
      expect(quiz.fiftyAvailable, isFalse);
      quiz.dispose();
    });

    test('skip moves on and is recorded as unanswered', () {
      final quiz = make();
      quiz.useSkip();
      expect(quiz.index, 1);
      expect(quiz.skipAvailable, isFalse);
      expect(quiz.buildResult().unanswered, 1);
      quiz.dispose();
    });

    test('next returns false after the last question', () {
      final quiz = make(count: 2);
      quiz.select(0);
      expect(quiz.next(), isTrue);
      quiz.select(0);
      expect(quiz.next(), isFalse);
      expect(quiz.buildResult().total, 2);
      quiz.dispose();
    });
  });
}
