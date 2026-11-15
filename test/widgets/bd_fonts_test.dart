import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kahwetne/widgets/comic_button.dart';
import 'package:kahwetne/widgets/dialog_button.dart';

// Boutons en Bangers (titres BD), texte courant inchangé (#355).
void main() {
  testWidgets(
    'le libellé du bouton BD utilise Bangers',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ComicButton(label: 'Jouer', onPressed: () {}),
          ),
        ),
      );
      final text = tester.widget<Text>(find.text('Jouer'));
      expect(text.style?.fontFamily, 'Bangers');
    },
  );

  testWidgets(
    'le bouton de dialogue utilise Bangers',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DialogButton(label: 'Suivant', onTap: () {}),
          ),
        ),
      );
      final text = tester.widget<Text>(find.text('Suivant'));
      expect(text.style?.fontFamily, 'Bangers');
    },
  );
}
