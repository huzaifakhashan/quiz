import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/quiz_result.dart';

class GameSummary {
  const GameSummary({
    required this.categoryId,
    required this.categoryTitle,
    required this.difficultyLabel,
    required this.score,
    required this.correct,
    required this.total,
    required this.playedAt,
  });

  final String categoryId;
  final String categoryTitle;
  final String difficultyLabel;
  final int score;
  final int correct;
  final int total;
  final DateTime playedAt;

  Map<String, dynamic> toJson() => {
    'categoryId': categoryId,
    'categoryTitle': categoryTitle,
    'difficulty': difficultyLabel,
    'score': score,
    'correct': correct,
    'total': total,
    'playedAt': playedAt.toIso8601String(),
  };

  factory GameSummary.fromJson(Map<String, dynamic> json) => GameSummary(
    categoryId: json['categoryId'] as String,
    categoryTitle: json['categoryTitle'] as String,
    difficultyLabel: json['difficulty'] as String,
    score: json['score'] as int,
    correct: json['correct'] as int,
    total: json['total'] as int,
    playedAt: DateTime.parse(json['playedAt'] as String),
  );
}

/// Persists player stats locally and notifies listeners on change.
class StatsService extends ChangeNotifier {
  StatsService._(this._prefs) {
    _load();
  }

  static const _historyKey = 'history';
  static const _bestKey = 'best_scores';
  static const _darkKey = 'dark_mode';
  static const _soundKey = 'haptics';
  static const _maxHistory = 30;

  static Future<StatsService> create() async =>
      StatsService._(await SharedPreferences.getInstance());

  final SharedPreferences _prefs;

  List<GameSummary> _history = [];
  Map<String, int> _best = {};

  List<GameSummary> get history => List.unmodifiable(_history);
  int bestFor(String categoryId) => _best[categoryId] ?? 0;

  int get gamesPlayed => _history.length;
  int get totalCorrect => _history.fold(0, (s, g) => s + g.correct);
  int get totalAnswered => _history.fold(0, (s, g) => s + g.total);
  int get totalScore => _history.fold(0, (s, g) => s + g.score);
  double get accuracy => totalAnswered == 0 ? 0 : totalCorrect / totalAnswered;

  /// Simple leveling: every 300 points is a level.
  int get level => totalScore ~/ 300 + 1;
  double get levelProgress => (totalScore % 300) / 300;

  ThemeModeSetting get themeMode => switch (_prefs.getBool(_darkKey)) {
    true => ThemeModeSetting.dark,
    false => ThemeModeSetting.light,
    null => ThemeModeSetting.system,
  };

  bool get hapticsEnabled => _prefs.getBool(_soundKey) ?? true;

  Future<void> setThemeMode(ThemeModeSetting mode) async {
    switch (mode) {
      case ThemeModeSetting.system:
        await _prefs.remove(_darkKey);
      case ThemeModeSetting.dark:
        await _prefs.setBool(_darkKey, true);
      case ThemeModeSetting.light:
        await _prefs.setBool(_darkKey, false);
    }
    notifyListeners();
  }

  Future<void> setHaptics(bool enabled) async {
    await _prefs.setBool(_soundKey, enabled);
    notifyListeners();
  }

  /// Records a finished game. Returns true if it set a new best score.
  Future<bool> record(QuizResult result) async {
    final summary = GameSummary(
      categoryId: result.categoryId,
      categoryTitle: result.categoryTitle,
      difficultyLabel: result.difficulty?.label ?? 'مختلط',
      score: result.score,
      correct: result.correct,
      total: result.total,
      playedAt: DateTime.now(),
    );
    _history = [summary, ..._history].take(_maxHistory).toList();

    final isNewBest = result.score > bestFor(result.categoryId);
    if (isNewBest) _best[result.categoryId] = result.score;

    await _save();
    notifyListeners();
    return isNewBest;
  }

  Future<void> reset() async {
    _history = [];
    _best = {};
    await _save();
    notifyListeners();
  }

  void _load() {
    try {
      final raw = _prefs.getString(_historyKey);
      if (raw != null) {
        _history = (jsonDecode(raw) as List)
            .map((e) => GameSummary.fromJson(e as Map<String, dynamic>))
            .toList();
      }
      final best = _prefs.getString(_bestKey);
      if (best != null) {
        _best = (jsonDecode(best) as Map<String, dynamic>).map(
          (k, v) => MapEntry(k, v as int),
        );
      }
    } catch (e) {
      debugPrint('Failed to load stats, starting fresh: $e');
      _history = [];
      _best = {};
    }
  }

  Future<void> _save() async {
    await _prefs.setString(
      _historyKey,
      jsonEncode(_history.map((g) => g.toJson()).toList()),
    );
    await _prefs.setString(_bestKey, jsonEncode(_best));
  }
}

enum ThemeModeSetting { system, light, dark }
