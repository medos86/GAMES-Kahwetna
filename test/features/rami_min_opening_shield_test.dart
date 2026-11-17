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

  testWidgets('bouclier petit, en bas à droite de son parent', (tester) async {
    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: Align(
          key: const Key('corner'),
          alignment: Alignment.bottomRight,
          child: RamiMinOpeningShield(
            minimum: 67,
            label: 'Ouverture minimale : 67',
          ),
        ),
      ),
    );
    final size = tester.getSize(find.byKey(const Key('ramiMinOpeningShield')));
    expect(size.width, lessThanOrEqualTo(32));
    expect(size.height, lessThanOrEqualTo(40));
    final shield = find.byKey(const Key('ramiMinOpeningShield'));
    final corner = tester.getBottomRight(find.byKey(const Key('corner')));
    expect(tester.getBottomRight(shield), corner);
  });
}
