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

  testWidgets('affiche le seuil', (tester) async {
    await tester.pumpWidget(host(76));
    expect(find.text('76'), findsOneWidget);
  });

  testWidgets('passif : un toucher ne révèle aucun libellé (#522)',
      (tester) async {
    await tester.pumpWidget(host(67));
    expect(find.byType(GestureDetector), findsNothing);
    await tester.tap(find.text('67'));
    await tester.pump();
    expect(find.byKey(const Key('ramiMinOpeningLabel')), findsNothing);
    expect(find.text('Ouverture minimale : 67'), findsNothing);
  });

  testWidgets('bouclier petit, en haut à droite de son parent (#522)',
      (tester) async {
    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: Align(
          key: const Key('corner'),
          alignment: Alignment.topRight,
          child: RamiMinOpeningShield(
            minimum: 67,
            label: 'Ouverture minimale : 67',
          ),
        ),
      ),
    );
    final shield = find.byKey(const Key('ramiMinOpeningShield'));
    final size = tester.getSize(shield);
    expect(size.width, lessThanOrEqualTo(32));
    expect(size.height, lessThanOrEqualTo(40));
    final corner = tester.getTopRight(find.byKey(const Key('corner')));
    expect(tester.getTopRight(shield), corner);
  });
}
