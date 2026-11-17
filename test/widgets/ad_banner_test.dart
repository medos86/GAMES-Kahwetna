import 'package:flutter_test/flutter_test.dart';
import 'package:kahwetne/core/strings.dart';
import 'package:kahwetne/widgets/ad_banner.dart';
import 'package:material_ui/material_ui.dart';

// La bannière publicitaire reste compacte même dans une pile pleine écran.
void main() {
  testWidgets('bannière bornée en hauteur dans une pile pleine écran', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Stack(
          fit: StackFit.expand,
          children: [
            Align(alignment: Alignment.bottomCenter, child: AdBanner()),
          ],
        ),
      ),
    );
    final size = tester.getSize(find.byType(AdBanner));
    expect(size.height, kAdBannerHeight);
    expect(kAdBannerHeight, inInclusiveRange(50, 60));
  });

  testWidgets(
    'la bannière ne déborde pas de sa hauteur fixe',
    (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Align(alignment: Alignment.bottomCenter, child: AdBanner()),
        ),
      );
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('texte agrandi x2 : bannière toujours à sa hauteur fixe', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: MediaQuery(
          data: MediaQueryData(textScaler: TextScaler.linear(2)),
          child: Align(alignment: Alignment.bottomCenter, child: AdBanner()),
        ),
      ),
    );
    expect(tester.takeException(), isNull);
    expect(tester.getSize(find.byType(AdBanner)).height, kAdBannerHeight);
  });

  testWidgets('aucune fausse publicité affichée sans pub chargée', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Align(alignment: Alignment.bottomCenter, child: AdBanner()),
      ),
    );
    expect(find.text(Strings.adTitle), findsNothing);
    expect(find.text(Strings.adLabel), findsNothing);
  });
}
