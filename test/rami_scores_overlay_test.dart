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
            body: RamiScoresTab(open: false, onTap: () => taps++),
          ),
        ),
      );
      await tester.tap(find.text(Strings.showScores));
      expect(taps, 1);
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
