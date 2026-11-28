// Chaîne Domino (#1043) : jamais de défilement, le zoom arrière couvre aussi la hauteur.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kahwetne/features/domino/domino_chain_layout.dart';
import 'package:kahwetne/features/domino/domino_tiles.dart';
import 'package:kahwetne/game/domino.dart';

void main() {
  test('#1036 : la demi-hauteur d\'une pierre seule vaut une demi-pierre', () {
    final slots = layoutChainAroundCenter(
      count: 1,
      openIndex: 0,
      halfWidth: 6,
    );
    expect(chainHalfHeight(slots: slots, unit: 30), 15.0);
  });

  testWidgets('#1043 : une chaîne longue ne défile jamais, elle rétrécit',
      (tester) async {
    tester.view.physicalSize = const Size(360, 780);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final chain = [
      for (var i = 0; i < 60; i++)
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
              openingId: 't30',
            ),
          ),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 400));

    expect(tester.takeException(), isNull);
    expect(find.byType(ChainTile), findsNWidgets(60));
    expect(find.byType(Scrollable), findsNothing,
        reason: 'la chaîne ne doit jamais défiler');
  });
}
