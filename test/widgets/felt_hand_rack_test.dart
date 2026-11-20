import 'package:flutter_test/flutter_test.dart';
import 'package:kahwetne/widgets/felt_hand_rack.dart';
import 'package:material_ui/material_ui.dart';

Widget _host(double width, Widget child) {
  return MaterialApp(
    home: Scaffold(
      body: Center(
        child: SizedBox(width: width, child: child),
      ),
    ),
  );
}

void main() {
  testWidgets('FeltHandRack réduit la main à 360 dp sans overflow', (
    tester,
  ) async {
    await tester.pumpWidget(
      _host(
        360,
        FeltHandRack(
          children: List.generate(
            10,
            (i) => SizedBox(key: ValueKey(i), width: 60, height: 90),
          ),
        ),
      ),
    );
    expect(tester.takeException(), isNull);
    expect(find.byType(FittedBox), findsOneWidget);
    final size = tester.getSize(find.byType(FeltHandRack));
    expect(size.width, lessThanOrEqualTo(360));
  });

  testWidgets('FeltHandRack reste cliquable à 390 dp', (tester) async {
    var taps = 0;
    const cardHeight = FeltHandRack.minTapTarget;
    await tester.pumpWidget(
      _host(
        390,
        FeltHandRack(
          children: [
            GestureDetector(
              key: const ValueKey('carte'),
              onTap: () => taps++,
              child: const SizedBox(width: 48, height: cardHeight),
            ),
          ],
        ),
      ),
    );
    expect(tester.takeException(), isNull);
    await tester.tap(find.byKey(const ValueKey('carte')));
    expect(taps, 1);
  });
}
