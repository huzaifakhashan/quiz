import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quiz/main.dart';
import 'package:quiz/screens/result_screen.dart';
import 'package:quiz/services/stats_service.dart';
import 'package:quiz/widgets/option_tile.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Pumps frames in 50ms steps. pumpAndSettle can't be used while the quiz
/// timer keeps animating.
Future<void> pumpFor(WidgetTester tester, int ms) async {
  for (var t = 0; t < ms; t += 50) {
    await tester.pump(const Duration(milliseconds: 50));
  }
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  for (final size in [const Size(390, 844), const Size(1280, 800)]) {
    testWidgets('full quiz flow at ${size.width}x${size.height}', (
      tester,
    ) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      final stats = await StatsService.create();
      await tester.pumpWidget(QuizApp(stats: stats));
      await tester.pumpAndSettle();
      expect(find.text('جاهز للتحدي؟'), findsOneWidget);

      await tester.tap(find.text('تحدي شامل'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('5'));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('ابدأ الاختبار'));
      await tester.tap(find.text('ابدأ الاختبار'));
      await pumpFor(tester, 1000);

      for (var i = 0; i < 5; i++) {
        await tester.tap(find.byType(OptionTile).first);
        await pumpFor(tester, 600);
        final next = find.text(i == 4 ? 'عرض النتيجة' : 'السؤال التالي');
        expect(next, findsOneWidget);
        await tester.ensureVisible(next);
        await tester.tap(next);
        await pumpFor(tester, 600);
      }
      await pumpFor(tester, 4000);

      expect(find.byType(ResultScreen), findsOneWidget);
      expect(stats.gamesPlayed, 1);

      await tester.scrollUntilVisible(
        find.text('مراجعة الإجابات'),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      await pumpFor(tester, 300);
      await tester.tap(find.text('مراجعة الإجابات'));
      await tester.pumpAndSettle();
      expect(find.text('مراجعة الإجابات'), findsWidgets);
    });
  }
}
