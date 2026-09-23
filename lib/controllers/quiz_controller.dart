import 'dart:async';
import 'dart:math';

import 'package:flutter/foundation.dart';

import '../models/category.dart';
import '../models/question.dart';
import '../models/quiz_result.dart';

enum QuestionPhase { answering, revealed }

/// Drives a single quiz session: timer, scoring, streaks and lifelines.
class QuizController extends ChangeNotifier {
  QuizController({
    required this.category,
    required this.difficulty,
    this.questionCount = 10,
    Random? random,
  }) : _random = random ?? Random() {
    final pool = category.byDifficulty(difficulty).toList()..shuffle(_random);
    _questions = pool
        .take(min(questionCount, pool.length))
        .map((q) => q.shuffled(_random))
        .toList();
  }

  final QuizCategory category;

  /// `null` means all difficulties mixed.
  final Difficulty? difficulty;
  final int questionCount;
  final Random _random;

  late final List<Question> _questions;
  final List<AnswerRecord> _answers = [];
  Timer? _timer;

  int _index = 0;
  int _secondsLeft = 0;
  int _score = 0;
  int _streak = 0;
  int _bestStreak = 0;
  int _lastPointsGained = 0;
  int? _selected;
  QuestionPhase _phase = QuestionPhase.answering;
  bool _paused = false;
  bool _disposed = false;

  bool _fiftyUsed = false;
  bool _skipUsed = false;
  bool _timeUsed = false;
  Set<int> _hidden = {};

  List<Question> get questions => List.unmodifiable(_questions);
  Question get current => _questions[_index];
  int get index => _index;
  int get total => _questions.length;
  int get secondsLeft => _secondsLeft;
  int get timeLimit => current.difficulty.seconds;
  double get timeFraction => timeLimit == 0 ? 0 : _secondsLeft / timeLimit;
  int get score => _score;
  int get streak => _streak;
  int get lastPointsGained => _lastPointsGained;
  int? get selected => _selected;
  QuestionPhase get phase => _phase;
  bool get isRevealed => _phase == QuestionPhase.revealed;
  bool get isLast => _index == _questions.length - 1;
  bool get isPaused => _paused;
  Set<int> get hiddenOptions => _hidden;
  bool get fiftyAvailable => !_fiftyUsed;
  bool get skipAvailable => !_skipUsed;
  bool get timeAvailable => !_timeUsed;
  double get progress =>
      total == 0 ? 0 : (_index + (isRevealed ? 1 : 0)) / total;

  void start() {
    if (_questions.isEmpty) return;
    _beginQuestion();
  }

  void _beginQuestion() {
    _secondsLeft = timeLimit;
    _selected = null;
    _hidden = {};
    _lastPointsGained = 0;
    _phase = QuestionPhase.answering;
    _startTimer();
    notifyListeners();
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_paused) return;
      _secondsLeft--;
      if (_secondsLeft <= 0) {
        _secondsLeft = 0;
        _reveal(null);
      } else {
        notifyListeners();
      }
    });
  }

  void select(int optionIndex) {
    if (isRevealed || _paused || _hidden.contains(optionIndex)) return;
    _reveal(optionIndex);
  }

  void _reveal(int? optionIndex) {
    _timer?.cancel();
    _selected = optionIndex;
    _phase = QuestionPhase.revealed;

    final record = AnswerRecord(
      question: current,
      selectedIndex: optionIndex,
      secondsTaken: timeLimit - _secondsLeft,
    );
    _answers.add(record);

    if (record.isCorrect) {
      _streak++;
      _bestStreak = max(_bestStreak, _streak);
      _lastPointsGained = _pointsFor(current, _secondsLeft, _streak);
      _score += _lastPointsGained;
    } else {
      _streak = 0;
      _lastPointsGained = 0;
    }
    notifyListeners();
  }

  /// Base points + speed bonus (up to 50%) + streak bonus (from 3 in a row).
  static int _pointsFor(Question q, int secondsLeft, int streak) {
    final base = q.difficulty.points;
    final speedBonus = (base * 0.5 * secondsLeft / q.difficulty.seconds)
        .round();
    final streakBonus = streak >= 3 ? 5 * (streak - 2) : 0;
    return base + speedBonus + streakBonus;
  }

  /// Advances to the next question. Returns false when the quiz is over.
  bool next() {
    if (!isRevealed) return true;
    if (isLast) return false;
    _index++;
    _beginQuestion();
    return true;
  }

  void useFiftyFifty() {
    if (_fiftyUsed || isRevealed) return;
    _fiftyUsed = true;
    final wrong = [
      for (var i = 0; i < current.options.length; i++)
        if (i != current.answerIndex) i,
    ]..shuffle(_random);
    _hidden = wrong.take(2).toSet();
    notifyListeners();
  }

  void useExtraTime() {
    if (_timeUsed || isRevealed) return;
    _timeUsed = true;
    _secondsLeft += 10;
    notifyListeners();
  }

  /// Skips the current question without breaking the streak.
  bool useSkip() {
    if (_skipUsed || isRevealed) return true;
    _skipUsed = true;
    _timer?.cancel();
    _answers.add(
      AnswerRecord(
        question: current,
        selectedIndex: null,
        secondsTaken: timeLimit - _secondsLeft,
      ),
    );
    _phase = QuestionPhase.revealed;
    return next();
  }

  void pause() {
    _paused = true;
    notifyListeners();
  }

  void resume() {
    _paused = false;
    notifyListeners();
  }

  QuizResult buildResult() => QuizResult(
    categoryId: category.id,
    categoryTitle: category.title,
    difficulty: difficulty,
    answers: List.unmodifiable(_answers),
    score: _score,
    bestStreak: _bestStreak,
    totalSeconds: _answers.fold(0, (s, a) => s + a.secondsTaken),
  );

  @override
  void notifyListeners() {
    if (!_disposed) super.notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _timer?.cancel();
    super.dispose();
  }
}
