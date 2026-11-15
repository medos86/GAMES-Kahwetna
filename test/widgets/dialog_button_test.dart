import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
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

  testWidgets('DialogButton : un seul libellé, pleine largeur', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: DialogButton(label: 'OK', onTap: () {})),
      ),
    );
    expect(
      find.descendant(of: find.byType(DialogButton), matching: find.text('OK')),
      findsOneWidget,
    );
    expect(
      tester.getSize(find.byType(DialogButton)).width,
      greaterThan(0),
    );
  });
}
