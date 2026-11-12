import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kahwetne/features/comic_demo/comic_demo_screen.dart';
import 'package:kahwetne/widgets/comic/action_burst.dart';
import 'package:kahwetne/widgets/comic/comic_panel.dart';
import 'package:kahwetne/widgets/comic/speech_bubble.dart';

/// Goldens du thème BD (issue #98). Les PNG sont générés par la CI (workflow « Goldens BD »),
/// jamais en local : le rendu des polices dépend de la plateforme.
void main() {
  Future<void> setSize(WidgetTester tester) async {
    tester.view.physicalSize = const Size(390 * 2, 844 * 2);
    tester.view.devicePixelRatio = 2;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
  }

  testWidgets('golden : page de démo BD en français', (tester) async {
    await setSize(tester);
    await tester.pumpWidget(const MaterialApp(home: ComicDemoScreen()));
    await tester.pumpAndSettle();
    await expectLater(find.byType(MaterialApp), matchesGoldenFile('goldens/comic_demo_fr.png'));
  });

  testWidgets('golden : page de démo BD en arabe', (tester) async {
    await setSize(tester);
    await tester.pumpWidget(const MaterialApp(home: ComicDemoScreen()));
    await tester.pumpAndSettle();
    await tester.tap(find.text('AR'));
    await tester.pumpAndSettle();
    await expectLater(find.byType(MaterialApp), matchesGoldenFile('goldens/comic_demo_ar.png'));
  });

  testWidgets('golden : case BD', (tester) async {
    await setSize(tester);
    await tester.pumpWidget(const MaterialApp(
      home: Scaffold(
        body: Center(
          child: ComicPanel(color: Color(0xFFFFFFFF), child: Text('Case', style: TextStyle(fontSize: 24))),
        ),
      ),
    ));
    await tester.pumpAndSettle();
    await expectLater(find.byType(ComicPanel), matchesGoldenFile('goldens/comic_panel.png'));
  });

  testWidgets('golden : bulle BD', (tester) async {
    await setSize(tester);
    await tester.pumpWidget(const MaterialApp(
      home: Scaffold(
        body: Center(
          child: SpeechBubble(
            fill: Color(0xFFFFFFFF),
            tailOnLeft: true,
            tailHeight: 16,
            tailWidth: 24,
            child: Text('Bonjour !', style: TextStyle(fontSize: 22)),
          ),
        ),
      ),
    ));
    await tester.pumpAndSettle();
    await expectLater(find.byType(SpeechBubble), matchesGoldenFile('goldens/speech_bubble.png'));
  });

  testWidgets('golden : onomatopée BD', (tester) async {
    await setSize(tester);
    await tester.pumpWidget(const MaterialApp(
      home: Scaffold(
        body: Center(child: ActionBurst(text: 'PAFF !', size: 140)),
      ),
    ));
    await tester.pumpAndSettle();
    await expectLater(find.byType(ActionBurst), matchesGoldenFile('goldens/action_burst.png'));
  });
}
