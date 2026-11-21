// Pioche intégrée au tapis (#685) : plus de cadre carré ni d'icône, le compteur reste lisible.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kahwetne/features/chkobba/chkobba_screen.dart';

void main() {
  testWidgets('#685 : la pioche affiche le compteur sans icône de cadre', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: Center(child: ChkobbaDeckPile(count: 12)),
        ),
      ),
    );

    expect(find.text('12'), findsOneWidget);
    expect(find.byIcon(Icons.layers), findsNothing);
    expect(find.byType(Icon), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
