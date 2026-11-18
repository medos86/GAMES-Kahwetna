import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kahwetne/widgets/ad_banner.dart';

// Golden de la bannière pub (issue #479). Les PNG sont générés par la CI
// (goldens.yml, « Goldens pub ») pour rester identiques à la plateforme de référence.
void main() {
  testWidgets('bannière pub en bas d\'écran', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: Align(
            alignment: Alignment.bottomCenter,
            child: AdBanner(),
          ),
        ),
      ),
    );
    await expectLater(
      find.byType(Scaffold),
      matchesGoldenFile('goldens/ad_banner.png'),
    );
  });
}
