// Generates the README screenshots into docs/screenshots/.
//
// Run with:
//   flutter test test/screenshots_test.dart --dart-define=SCREENSHOTS=true
import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quiz/data/question_bank.dart';
import 'package:quiz/main.dart';
import 'package:quiz/services/stats_service.dart';
import 'package:quiz/widgets/option_tile.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _enabled = bool.fromEnvironment('SCREENSHOTS');
const _outDir = 'docs/screenshots';
const _size = Size(390, 844);
const _pixelRatio = 2.5;

final _boundaryKey = GlobalKey();

Future<void> _loadFont(String family, List<String> paths) async {
  final loader = FontLoader(family);
  for (final p in paths) {
    final bytes = File(p).readAsBytesSync();
    loader.addFont(Future.value(ByteData.view(bytes.buffer)));
  }
  await loader.load();
}

Future<void> _loadFonts() async {
  await _loadFont('Cairo', [
    for (final w in ['Regular', 'Medium', 'SemiBold', 'Bold', 'ExtraBold'])
      'assets/fonts/Cairo-$w.ttf',
  ]);
  const emoji = 'C:/Windows/Fonts/seguiemj.ttf';
  if (File(emoji).existsSync()) await _loadFont('Noto Color Emoji', [emoji]);
  final flutterRoot = Platform.environment['FLUTTER_ROOT']!;
  await _loadFont('MaterialIcons', [
    '$flutterRoot/bin/cache/artifacts/material_fonts/MaterialIcons-Regular.otf',
  ]);
}

Future<void> _pump(WidgetTester tester, int ms) async {
  for (var t = 0; t < ms; t += 50) {
    await tester.pump(const Duration(milliseconds: 50));
  }
}

Future<void> _shot(WidgetTester tester, String name) async {
  await tester.runAsync(() async {
    final boundary =
        _boundaryKey.currentContext!.findRenderObject()!
            as RenderRepaintBoundary;
    final image = await boundary.toImage(pixelRatio: _pixelRatio);
    final data = await image.toByteData(format: ui.ImageByteFormat.png);
    File('$_outDir/$name.png')
      ..createSync(recursive: true)
      ..writeAsBytesSync(data!.buffer.asUint8List());
  });
}

/// Seeds a few past games so the home and stats screens look lived-in.
Map<String, Object> _seedPrefs() {
  final now = DateTime(2026, 9, 23, 20);
  final games = [
    ('science', 'العلوم', 'متوسط', 265, 9, 10, 1),
    ('history', 'التاريخ', 'سهل', 118, 8, 10, 1),
    ('tech', 'التكنولوجيا', 'صعب', 212, 5, 5, 2),
    ('geography', 'الجغرافيا', 'مختلط', 96, 4, 10, 3),
  ];
  return {
    'history': jsonEncode([
      for (final g in games)
        {
          'categoryId': g.$1,
          'categoryTitle': g.$2,
          'difficulty': g.$3,
          'score': g.$4,
          'correct': g.$5,
          'total': g.$6,
          'playedAt': now.subtract(Duration(days: g.$7)).toIso8601String(),
        },
    ]),
    'best_scores': jsonEncode({for (final g in games) g.$1: g.$4}),
    'dark_mode': false,
  };
}

/// Finds the index of the correct option for the question on screen.
int _correctOptionIndex(WidgetTester tester) {
  final texts = tester
      .widgetList<Text>(find.byType(Text))
      .map((t) => t.data)
      .toSet();
  final question = QuestionBank.mixed.questions.firstWhere(
    (q) => texts.contains(q.text),
  );
  final tiles = tester.widgetList<OptionTile>(find.byType(OptionTile)).toList();
  return tiles.indexWhere((t) => t.text == question.correctAnswer);
}

void main() {
  testWidgets('generate screenshots', skip: !_enabled, (tester) async {
    await _loadFonts();
    tester.view.physicalSize = _size * _pixelRatio;
    tester.view.devicePixelRatio = _pixelRatio;
    addTearDown(tester.view.reset);

    SharedPreferences.setMockInitialValues(_seedPrefs());
    final stats = await StatsService.create();

    await tester.pumpWidget(
      RepaintBoundary(
        key: _boundaryKey,
        child: QuizApp(stats: stats),
      ),
    );
    await _pump(tester, 1500);
    await _shot(tester, '01_home');

    // Setup sheet.
    await tester.tap(find.text('العلوم'));
    await _pump(tester, 800);
    await tester.tap(find.text('متوسط'));
    await _pump(tester, 400);
    await _shot(tester, '02_setup');

    // Start the quiz.
    await tester.ensureVisible(find.text('ابدأ الاختبار'));
    await tester.tap(find.text('ابدأ الاختبار'));
    await _pump(tester, 3200);
    await _shot(tester, '03_question');

    // Science/medium has 4 questions: answer one wrong, the rest correct.
    expect(find.byType(OptionTile), findsNWidgets(4));
    for (var i = 0; i < 4; i++) {
      final correct = _correctOptionIndex(tester);
      final pick = i == 2 ? (correct + 1) % 4 : correct;
      await tester.tap(find.byType(OptionTile).at(pick));
      await _pump(tester, 900);
      if (i == 0) await _shot(tester, '04_answer');
      final next = find.text(i == 3 ? 'عرض النتيجة' : 'السؤال التالي');
      await tester.ensureVisible(next);
      await tester.tap(next);
      await _pump(tester, 700);
    }

    await _pump(tester, 1600);
    await _shot(tester, '05_result');

    // Review.
    await tester.scrollUntilVisible(
      find.text('مراجعة الإجابات'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await _pump(tester, 300);
    await tester.tap(find.text('مراجعة الإجابات'));
    await _pump(tester, 1500);
    await _shot(tester, '06_review');

    // Back to home, then stats.
    await tester.tap(find.byType(BackButton));
    await _pump(tester, 800);
    await tester.scrollUntilVisible(
      find.text('الرئيسية'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.text('الرئيسية'));
    await _pump(tester, 1000);
    await tester.tap(find.byTooltip('الإحصائيات'));
    await _pump(tester, 1500);
    await _shot(tester, '07_stats');

    // Dark mode home.
    await tester.tap(find.byType(BackButton));
    await _pump(tester, 800);
    await stats.setThemeMode(ThemeModeSetting.dark);
    await _pump(tester, 1500);
    await _shot(tester, '08_home_dark');
  });
}
