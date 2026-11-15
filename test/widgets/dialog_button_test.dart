import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kahwetne/core/theme/comic_palette.dart';
import 'package:kahwetne/widgets/dialog_button.dart';

/// Issue #303 : bouton partagé des dialogues de fin (Rami, Coinche).
void main() {
  testWidgets('DialogButton affiche son libellé et appelle onTap', (
    tester,
  ) async {
    var taps = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: DialogButton(label: 'Manche suivante', onTap: () => taps++),
        ),
      ),
    );
    expect(find.text('Manche suivante'), findsOneWidget);
    await tester.tap(find.text('Manche suivante'));
    expect(taps, 1);
  });

  testWidgets('DialogButton utilise la couleur or de la palette BD', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: DialogButton(label: 'OK', onTap: () {})),
      ),
    );
    final button = tester.widget<FilledButton>(find.byType(FilledButton));
    expect(button.style?.backgroundColor?.resolve({}), ComicPalette.gold);
  });
}
