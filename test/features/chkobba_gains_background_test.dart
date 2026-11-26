import 'package:flutter_test/flutter_test.dart';
import 'package:kahwetne/features/chkobba/chkobba_card_face.dart';
import 'package:material_ui/material_ui.dart';

// Issue #987 : le fond des zones de gains affiche l'image entière, sans recadrage.
void main() {
  testWidgets('dos plein format : image entière, sans zoom', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: 56,
              height: 44,
              child: const ChkobbaCardBack(fullImage: true),
            ),
          ),
        ),
      ),
    );
    final image = tester.widget<Image>(
      find.descendant(
        of: find.byType(ChkobbaCardBack),
        matching: find.byType(Image),
      ),
    );
    expect(image.fit, BoxFit.contain);
    expect(
      find.descendant(
        of: find.byType(ChkobbaCardBack),
        matching: find.byType(Transform),
      ),
      findsNothing,
    );
  });

  testWidgets('dos de la main : zoom conservé', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: const ChkobbaCardBack()),
      ),
    );
    final image = tester.widget<Image>(
      find.descendant(
        of: find.byType(ChkobbaCardBack),
        matching: find.byType(Image),
      ),
    );
    expect(image.fit, BoxFit.cover);
    expect(
      find.descendant(
        of: find.byType(ChkobbaCardBack),
        matching: find.byType(Transform),
      ),
      findsOneWidget,
    );
  });
}
