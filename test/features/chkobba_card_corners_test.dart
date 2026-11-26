import 'package:flutter_test/flutter_test.dart';
import 'package:kahwetne/features/chkobba/chkobba_card_face.dart';
import 'package:kahwetne/game/chkobba.dart';
import 'package:material_ui/material_ui.dart';

// Issue #985 : coins arrondis, appliqués de façon identique sur la face et le dos.
void main() {
  testWidgets('face et dos des cartes ont le même rayon d’angle', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: Column(
              children: [
                ChkobbaCardFace(
                  card: const ChkobbaCard(
                    suit: ChkobbaSuit.batons,
                    rank: 5,
                    id: 'b5',
                  ),
                ),
                const ChkobbaCardBack(),
              ],
            ),
          ),
        ),
      ),
    );
    final radii = [
      for (final clip in tester.widgetList<ClipRRect>(find.byType(ClipRRect)))
        clip.borderRadius,
    ];
    expect(radii, hasLength(2));
    expect(radii, everyElement(BorderRadius.circular(chkobbaCardRadius)));
  });

  test('le rayon des coins est arrondi (au moins 10 dp)', () {
    expect(chkobbaCardRadius, greaterThanOrEqualTo(10));
  });
}
