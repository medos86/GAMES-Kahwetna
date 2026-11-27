// Défilement vertical de la chaîne Domino (#1036) : pas de zoom en hauteur, pan au lieu.
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

  testWidgets('#1036 : une chaîne longue défile au lieu de rétrécir',
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
    final scroll = tester.state<ScrollableState>(find.byType(Scrollable));
    expect(scroll.position.maxScrollExtent > 0, isTrue,
        reason: 'la chaîne doit pouvoir défiler verticalement');
  });
}
