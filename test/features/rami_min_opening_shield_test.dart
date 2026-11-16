import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kahwetne/features/rami/rami_min_opening_shield.dart';

void main() {
  Widget host(int minimum) => Directionality(
        textDirection: TextDirection.ltr,
        child: RamiMinOpeningShield(
          minimum: minimum,
          label: 'Ouverture minimale : $minimum',
        ),
      );

  testWidgets('affiche le seuil, libellé masqué', (tester) async {
    await tester.pumpWidget(host(76));
    expect(find.text('76'), findsOneWidget);
    expect(find.byKey(const Key('ramiMinOpeningLabel')), findsNothing);
  });

  testWidgets('au toucher, libellé visible puis masqué', (tester) async {
    await tester.pumpWidget(host(67));
    await tester.tap(find.text('67'));
    await tester.pump();
    expect(find.text('Ouverture minimale : 67'), findsOneWidget);
    await tester.pump(const Duration(seconds: 4));
    expect(find.byKey(const Key('ramiMinOpeningLabel')), findsNothing);
  });
}
