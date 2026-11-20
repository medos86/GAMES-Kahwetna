import 'package:flutter_test/flutter_test.dart';
import 'package:kahwetne/core/i18n/app_language.dart';
import 'package:kahwetne/core/strings.dart';
import 'package:kahwetne/features/rami/rami_scores_overlay.dart';
import 'package:material_ui/material_ui.dart';

void main() {
  setUp(() => appLanguage.value = AppLanguage.fr);

  testWidgets(
    'onglet Scores : un tap appelle onTap',
    (tester) async {
      var taps = 0;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: RamiScoresTab(
              open: false,
              myTurn: true,
              onTap: () => taps++,
            ),
          ),
        ),
      );
      await tester.tap(find.text(Strings.showScores));
      expect(taps, 1);
    },
  );

  testWidgets(
    'onglet Scores : n affiche que le libellé, sans flèche ni score (#667)',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: RamiScoresTab(
              open: false,
              myTurn: false,
              onTap: () {},
            ),
          ),
        ),
      );
      expect(find.text(Strings.showScores), findsOneWidget);
      expect(find.byType(Icon), findsNothing);
      expect(find.textContaining('·'), findsNothing);
    },
  );

  testWidgets(
    'onglet Scores : fond doré quand c\'est le tour du joueur (#667)',
    (tester) async {
      Future<Color> colorFor(bool myTurn) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: RamiScoresTab(open: false, myTurn: myTurn, onTap: () {}),
            ),
          ),
        );
        final box = tester.widget<Container>(
          find.descendant(
            of: find.byType(RamiScoresTab),
            matching: find.byType(Container),
          ),
        );
        return (box.decoration! as BoxDecoration).color!;
      }

      expect(await colorFor(true), const Color(0xFFFFE16B));
      expect(await colorFor(false), const Color(0xFFFFF8E7));
    },
  );

  testWidgets(
    'panneau fermé : ignoré par les gestes',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: RamiScoresPanel(
              open: false,
              onClose: () {},
              child: const Text('scores'),
            ),
          ),
        ),
      );
      final ignore = tester.widget<IgnorePointer>(
        find
            .descendant(
              of: find.byType(RamiScoresPanel),
              matching: find.byType(IgnorePointer),
            )
            .first,
      );
      expect(ignore.ignoring, isTrue);
    },
  );

  testWidgets(
    'panneau ouvert : le bouton Fermer appelle onClose',
    (tester) async {
      var closes = 0;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: RamiScoresPanel(
              open: true,
              onClose: () => closes++,
              child: const Text('scores'),
            ),
          ),
        ),
      );
      await tester.tap(find.text(Strings.hideScores));
      expect(closes, 1);
    },
  );
}
