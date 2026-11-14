import 'package:flutter_test/flutter_test.dart';
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
    expect(size.height, lessThanOrEqualTo(96));
    expect(size.height, greaterThanOrEqualTo(64));
  });
}
