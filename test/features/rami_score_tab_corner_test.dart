import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kahwetne/features/rami/rami_seat_badge.dart';

void main() {
  testWidgets('#590 : onglet Score sans chevauchement', (tester) async {
    tester.view.physicalSize = const Size(360, 780);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: Stack(
            children: [
              Positioned(
                top: 0,
                right: 0,
                child: SizedBox(
                  key: ValueKey('score'),
                  width: 120,
                  height: 36,
                ),
              ),
              Align(
                alignment: Alignment.topCenter,
                child: Padding(
                  padding: EdgeInsets.only(top: 4),
                  child: SizedBox(
                    key: ValueKey('front'),
                    width: 110,
                    height: 26,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
    final score = tester.getRect(find.byKey(const ValueKey('score')));
    final front = tester.getRect(find.byKey(const ValueKey('front')));
    expect(score.overlaps(front), isFalse);
  });

  test('#590 : le badge du joueur de devant reste en haut au centre', () {
    expect(ramiSeatAlignment(2), Alignment.topCenter);
  });
}
