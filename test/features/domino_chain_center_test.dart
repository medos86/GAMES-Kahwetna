// Rendu de la chaîne centrée (#930) : pas d'erreur, toutes les pierres présentes.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kahwetne/features/domino/domino_tiles.dart';
import 'package:kahwetne/game/domino.dart';

void main() {
  testWidgets(
    '#930 : la chaîne se déploie au centre sans erreur',
    (tester) async {
      tester.view.physicalSize = const Size(360, 780);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final chain = [
        for (var i = 0; i < 25; i++)
          PlacedTile(
            id: 't$i',
            a: i % 6,
            b: (i + 1) % 6,
            left: i % 6,
            right: (i + 1) % 6,
          ),
      ];
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 360,
              height: 600,
              child: DominoChain(
                chain: chain,
                leftOpen: true,
                rightOpen: true,
                onEndTap: (_) {},
                openingId: 't12',
              ),
            ),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 400));
      expect(tester.takeException(), isNull);
      expect(find.byType(ChainTile), findsNWidgets(25));
    },
  );
}
