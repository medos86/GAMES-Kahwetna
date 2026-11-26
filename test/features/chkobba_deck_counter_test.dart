// Cartes restantes à distribuer (#983) : plus de pioche empilée, un compteur mis à jour.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kahwetne/features/chkobba/chkobba_screen.dart';

void main() {
  testWidgets('#983 : le compteur affiche les cartes restantes sans dos empilés', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: Center(child: ChkobbaDeckCounter(count: 12)),
        ),
      ),
    );

    expect(find.text('12 à distribuer'), findsOneWidget);
    expect(find.byType(ChkobbaCardBack), findsNothing);
    expect(find.byType(Icon), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('#983 : le compteur se met à jour à chaque distribution', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: Center(child: ChkobbaDeckCounter(count: 8)),
        ),
      ),
    );
    expect(find.text('8 à distribuer'), findsOneWidget);

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: Center(child: ChkobbaDeckCounter(count: 4)),
        ),
      ),
    );
    expect(find.text('4 à distribuer'), findsOneWidget);
    expect(find.text('8 à distribuer'), findsNothing);
  });
}
