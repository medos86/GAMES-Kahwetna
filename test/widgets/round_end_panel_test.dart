import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:kahwetne/widgets/round_end_panel.dart';

/// Issue #295 : écran de fin commun — variations signées, motifs, bouton d'action.
void main() {
  test('variation signée : +100, -10, 0', () {
    expect(RoundEndPanel.signed(100), '+100');
    expect(RoundEndPanel.signed(-10), '-10');
    expect(RoundEndPanel.signed(0), '0');
  });

  testWidgets('affiche le titre, les lignes et lance l\'action principale', (
    tester,
  ) async {
    var tapped = false;
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: const [
          DefaultMaterialLocalizations.delegate,
          DefaultWidgetsLocalizations.delegate,
        ],
        home: RoundEndPanel(
          badge: 'MANCHE 1',
          title: 'Bravo',
          rows: const [
            RoundEndRow(
              name: 'Toi',
              delta: -10,
              total: 90,
              reason: 'Gagnant',
              highlight: true,
            ),
            RoundEndRow(name: 'Ali', delta: 100, total: 200, reason: 'Pas ouvert'),
          ],
          primaryLabel: 'Suivant',
          onPrimary: () => tapped = true,
        ),
      ),
    );
    expect(find.text('Bravo'), findsOneWidget);
    expect(find.text('-10'), findsOneWidget);
    expect(find.text('+100'), findsOneWidget);
    expect(find.text('Gagnant'), findsOneWidget);
    expect(find.text('Total 200'), findsOneWidget);

    await tester.tap(find.text('Suivant'));
    await tester.pump();
    expect(tapped, isTrue);
  });
}
