import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kahwetne/widgets/comic/action_burst.dart';
import 'package:kahwetne/widgets/comic/comic_panel.dart';
import 'package:kahwetne/widgets/comic/halftone_overlay.dart';
import 'package:kahwetne/widgets/comic/ink_outline.dart';
import 'package:kahwetne/widgets/comic/speech_bubble.dart';

Widget _host(Widget child, {bool reduceMotion = false}) {
  return MaterialApp(
    home: MediaQuery(
      data: MediaQueryData(disableAnimations: reduceMotion),
      child: Scaffold(body: Center(child: child)),
    ),
  );
}

void main() {
  testWidgets('HalftoneOverlay affiche son enfant sans bloquer les touches', (
    tester,
  ) async {
    var tapped = false;
    await tester.pumpWidget(
      _host(
        HalftoneOverlay(
          child: ElevatedButton(
            onPressed: () => tapped = true,
            child: const Text('Jouer'),
          ),
        ),
      ),
    );
    expect(find.text('Jouer'), findsOneWidget);
    await tester.tap(find.text('Jouer'));
    expect(tapped, isTrue);
  });

  testWidgets('ComicPanel et InkOutline affichent leur contenu', (
    tester,
  ) async {
    await tester.pumpWidget(_host(const ComicPanel(child: Text('Case'))));
    expect(find.text('Case'), findsOneWidget);
    expect(find.byType(InkOutline), findsOneWidget);
  });

  testWidgets('SpeechBubble affiche le message, queue à gauche ou à droite', (
    tester,
  ) async {
    await tester.pumpWidget(
      _host(const SpeechBubble(tailOnLeft: false, child: Text('À toi !'))),
    );
    expect(find.text('À toi !'), findsOneWidget);
    await tester.pumpWidget(
      _host(const SpeechBubble(child: Text('Chkobba !'))),
    );
    expect(find.text('Chkobba !'), findsOneWidget);
  });

  testWidgets(
    'ActionBurst : onomatopée visible et lisible par les lecteurs d\'écran',
    (tester) async {
      await tester.pumpWidget(_host(const ActionBurst(text: 'PAFF !')));
      await tester.pumpAndSettle();
      expect(find.text('PAFF !'), findsOneWidget);
      expect(find.bySemanticsLabel('PAFF !'), findsOneWidget);
    },
  );

  testWidgets(
    'ActionBurst s\'affiche d\'emblée si les animations sont réduites',
    (tester) async {
      await tester.pumpWidget(
        _host(const ActionBurst(text: 'POW !'), reduceMotion: true),
      );
      // Pas de pumpAndSettle : l'éclat doit être complet dès le premier rendu.
      await tester.pump();
      expect(find.text('POW !'), findsOneWidget);
      final transform = tester.widget<Transform>(find.byType(Transform).first);
      expect(transform.transform.getMaxScaleOnAxis(), closeTo(1, 0.001));
    },
  );
}
