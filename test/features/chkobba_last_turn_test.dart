// Dernier tour (pioche vide) : bulle BD « DERNIER TOUR » avec clochette animée, sans compteur.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kahwetne/features/chkobba/chkobba_screen.dart';

Widget _alert() {
  return const MaterialApp(
    home: Scaffold(
      body: Center(child: ChkobbaLastTurnAlert()),
    ),
  );
}

void main() {
  testWidgets('affiche DERNIER TOUR sans compteur de cartes', (tester) async {
    await tester.pumpWidget(_alert());

    expect(find.text('DERNIER TOUR'), findsOneWidget);
    expect(find.textContaining('à distribuer'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('clochette animée en boucle', (tester) async {
    await tester.pumpWidget(_alert());
    expect(find.byIcon(Icons.notifications_active), findsOneWidget);

    await tester.pump(const Duration(milliseconds: 90));
    await tester.pump(const Duration(milliseconds: 90));
    expect(tester.takeException(), isNull);
  });
}
