import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kahwetne/core/theme/comic_palette.dart';
import 'package:kahwetne/widgets/result_dialog.dart';

/// Issue #295 : le récapitulatif de fin de manche/partie est en style BD, pour tous les styles.
void main() {
  testWidgets('ResultDialog : fond papier', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ResultDialog(
            title: 'Bravo',
            children: const [Text('Contenu')],
          ),
        ),
      ),
    );
    final box = tester.widget<Container>(
      find
          .descendant(
            of: find.byType(ResultDialog),
            matching: find.byType(Container),
          )
          .first,
    );
    final decoration = box.decoration as BoxDecoration;
    expect(decoration.color, ComicPalette.paper);
    final border = decoration.border as Border;
    expect(border.top.color, ComicPalette.ink);
  });

  testWidgets('ResultDialog : titre en Bangers, encre noire', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: ResultDialog(title: 'Victoire !')),
      ),
    );
    final text = tester.widget<Text>(find.text('Victoire !'));
    expect(text.style?.fontFamily, 'Bangers');
    expect(text.style?.color, ComicPalette.ink);
  });

  test('ResultDialog : texte sur papier, contraste WCAG ≥ 4,5', () {
    expect(
      contrastRatio(ComicPalette.ink, ComicPalette.paper),
      greaterThanOrEqualTo(4.5),
    );
  });
}
