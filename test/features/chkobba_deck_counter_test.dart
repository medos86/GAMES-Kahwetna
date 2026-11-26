// Cartes restantes à distribuer (#983) : plus de pioche empilée, un compteur mis à jour.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kahwetne/features/chkobba/chkobba_screen.dart';

Widget _counter(int count) {
  return MaterialApp(
    home: Scaffold(
      body: Center(child: ChkobbaDeckCounter(count: count)),
    ),
  );
}

void main() {
  testWidgets('compteur sans dos de cartes empilés', (tester) async {
    await tester.pumpWidget(_counter(12));

    expect(find.text('12 à distribuer'), findsOneWidget);
    expect(find.byType(ChkobbaCardBack), findsNothing);
    expect(find.byType(Icon), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('compteur mis à jour à chaque distribution', (tester) async {
    await tester.pumpWidget(_counter(8));
    expect(find.text('8 à distribuer'), findsOneWidget);

    await tester.pumpWidget(_counter(4));
    expect(find.text('4 à distribuer'), findsOneWidget);
    expect(find.text('8 à distribuer'), findsNothing);
  });
}
