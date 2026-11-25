import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kahwetne/features/chkobba/chkobba_table.dart';

// Une carte retirée du tapis ne fait pas bouger les autres.
void main() {
  Future<void> pump(WidgetTester tester, List<Widget?> cards) async {
    tester.view.physicalSize = const Size(360, 780);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 360,
            height: 400,
            child: ChkobbaTable(cards: cards, columns: 4),
          ),
        ),
      ),
    );
  }

  testWidgets('retirer une carte ne déplace pas les cartes restantes', (
    tester,
  ) async {
    final keyB = const ValueKey('b');
    await pump(tester, [
      Container(key: const ValueKey('a'), color: Colors.red),
      Container(key: keyB, color: Colors.blue),
      Container(key: const ValueKey('c'), color: Colors.amber),
    ]);
    final before = tester.getTopLeft(find.byKey(keyB));

    await pump(tester, [
      null,
      Container(key: keyB, color: Colors.blue),
      Container(key: const ValueKey('c'), color: Colors.amber),
    ]);
    expect(tester.getTopLeft(find.byKey(keyB)), before);
    expect(tester.takeException(), isNull);
  });
}
