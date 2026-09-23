// Renders the app icon source images into assets/icon/.
//
// Run with:
//   flutter test test/icon_generator_test.dart --dart-define=ICON=true
//   dart run flutter_launcher_icons
import 'dart:io';
import 'dart:math';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

const _enabled = bool.fromEnvironment('ICON');
const _size = 1024.0;
const _gradient = [Color(0xFF6A11CB), Color(0xFF2575FC)];
const _gold = Color(0xFFFFC53D);

Future<void> _loadFont(String family, List<String> paths) async {
  final loader = FontLoader(family);
  for (final p in paths) {
    final bytes = File(p).readAsBytesSync();
    loader.addFont(Future.value(ByteData.view(bytes.buffer)));
  }
  await loader.load();
}

/// Gradient backdrop, optionally clipped to a rounded square.
class _Background extends StatelessWidget {
  const _Background({this.rounded = false});

  final bool rounded;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: rounded ? BorderRadius.circular(_size * 0.225) : null,
        gradient: const LinearGradient(
          colors: _gradient,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
    );
  }
}

/// White speech bubble with an Arabic question mark and a gold star.
/// [monochrome] draws a single-color silhouette for Android themed icons.
class _Mark extends StatelessWidget {
  const _Mark({this.scale = 1, this.monochrome = false});

  final double scale;
  final bool monochrome;

  @override
  Widget build(BuildContext context) {
    const bubbleW = 600.0, bubbleH = 520.0;
    final bubbleColor = monochrome ? Colors.black : Colors.white;

    Widget questionMark = Text(
      '؟',
      textDirection: TextDirection.rtl,
      style: const TextStyle(
        fontFamily: 'Cairo',
        fontWeight: FontWeight.w800,
        fontSize: 400,
        height: 1,
        color: Colors.white,
      ),
    );
    questionMark = monochrome
        ? questionMark
        : ShaderMask(
            shaderCallback: (r) => const LinearGradient(
              colors: _gradient,
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ).createShader(r),
            child: questionMark,
          );

    return Center(
      child: Transform.scale(
        scale: scale,
        child: SizedBox(
          width: bubbleW + 120,
          height: bubbleH + 200,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              // Bubble tail (bottom-left).
              Positioned(
                left: 150,
                top: 60 + bubbleH - 110,
                child: Transform.rotate(
                  angle: pi / 4,
                  child: Container(
                    width: 170,
                    height: 170,
                    decoration: BoxDecoration(
                      color: bubbleColor,
                      borderRadius: BorderRadius.circular(28),
                    ),
                  ),
                ),
              ),
              // Bubble body.
              Positioned(
                left: 60,
                top: 60,
                child: Container(
                  width: bubbleW,
                  height: bubbleH,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: bubbleColor,
                    borderRadius: BorderRadius.circular(170),
                    boxShadow: monochrome
                        ? null
                        : [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.18),
                              blurRadius: 40,
                              offset: const Offset(0, 24),
                            ),
                          ],
                  ),
                  child: monochrome
                      ? null
                      : Transform.translate(
                          offset: const Offset(0, 22),
                          child: questionMark,
                        ),
                ),
              ),
              // Gold star badge (top-right).
              if (!monochrome)
                Positioned(
                  right: -10,
                  top: -20,
                  child: Transform.rotate(
                    angle: 0.25,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        Icon(
                          Icons.star_rounded,
                          size: 250,
                          color: Colors.black.withValues(alpha: 0.12),
                        ),
                        const Icon(Icons.star_rounded, size: 230, color: _gold),
                      ],
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

Future<void> _render(WidgetTester tester, Widget child, String path) async {
  final key = GlobalKey();
  await tester.pumpWidget(
    Directionality(
      textDirection: TextDirection.ltr,
      child: Center(
        child: RepaintBoundary(
          key: key,
          child: SizedBox.square(dimension: _size, child: child),
        ),
      ),
    ),
  );
  await tester.pump();
  await tester.runAsync(() async {
    final boundary =
        key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
    final image = await boundary.toImage();
    final data = await image.toByteData(format: ui.ImageByteFormat.png);
    File(path)
      ..createSync(recursive: true)
      ..writeAsBytesSync(data!.buffer.asUint8List());
  });
}

void main() {
  testWidgets('generate app icon', skip: !_enabled, (tester) async {
    await _loadFont('Cairo', ['assets/fonts/Cairo-ExtraBold.ttf']);
    final flutterRoot = Platform.environment['FLUTTER_ROOT']!;
    await _loadFont('MaterialIcons', [
      '$flutterRoot/bin/cache/artifacts/material_fonts/MaterialIcons-Regular.otf',
    ]);
    tester.view.physicalSize = const Size(_size, _size);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    // Rounded full icon: Windows, web, legacy Android launchers.
    await _render(
      tester,
      const Stack(
        fit: StackFit.expand,
        children: [_Background(rounded: true), _Mark(scale: 0.95)],
      ),
      'assets/icon/icon.png',
    );
    // Android adaptive icon layers. The foreground must fit the inner
    // safe zone (~66%) because launchers crop it to various shapes.
    await _render(tester, const _Background(), 'assets/icon/background.png');
    await _render(tester, const _Mark(scale: 0.62), 'assets/icon/foreground.png');
    await _render(
      tester,
      const _Mark(scale: 0.62, monochrome: true),
      'assets/icon/monochrome.png',
    );
  });
}
