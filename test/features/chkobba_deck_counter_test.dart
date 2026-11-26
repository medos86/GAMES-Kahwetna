// Compteur des cartes à distribuer (#983) : remplace la pioche, barre proportionnelle au reste.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kahwetne/features/chkobba/chkobba_screen.dart';

void main() {
  testWidgets('#983 : le compteur affiche le nombre de cartes restantes', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: Center(child: ChkobbaDeckCounter(count: 12)),
        ),
      ),
    );

    expect(find.text('12'), findsOneWidget);
    expect(find.byType(Icon), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('#983 : la barre se vide proportionnellement au reste', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: Center(child: ChkobbaDeckCounter(count: 10, total: 40)),
        ),
      ),
    );

    final fill = tester.widget<FractionallySizedBox>(
      find.byType(FractionallySizedBox),
    );
    expect(fill.widthFactor, closeTo(0.25, 1e-9));
  });

  testWidgets('#983 : la barre reste à zéro sans carte restante', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: Center(child: ChkobbaDeckCounter(count: 0)),
        ),
      ),
    );

    final fill = tester.widget<FractionallySizedBox>(
      find.byType(FractionallySizedBox),
    );
    expect(fill.widthFactor, 0.0);
    expect(tester.takeException(), isNull);
  });
}
