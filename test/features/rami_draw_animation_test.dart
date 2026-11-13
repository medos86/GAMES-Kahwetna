import 'package:flutter_test/flutter_test.dart';
import 'package:kahwetne/core/services/card_animations.dart';
import 'package:kahwetne/features/menu/menu_models.dart';
import 'package:kahwetne/features/rami/rami_card_view.dart';
import 'package:kahwetne/features/rami/rami_screen.dart';
import 'package:material_ui/material_ui.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Pioche de Rami avec animation : la carte vole pendant l'action puis
// disparaît à l'arrivée sur la vraie carte de la main (#224, #238).
void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    cardAnimations.value = true;
  });

  tearDown(() => cardAnimations.value = false);

  testWidgets('la pioche lance un vol qui se termine sur la main', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844) * 3;
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      const MaterialApp(
        home: RamiScreen(difficulty: Difficulty.facile, targetScore: 100),
      ),
    );
    await tester.pump(const Duration(seconds: 1));

    final inOverlay = find.descendant(
      of: find.byType(Overlay),
      matching: find.byType(RamiBackView),
    );
    final stock = find.byType(RamiBackView).first;
    await tester.tap(stock);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
    expect(tester.takeException(), isNull);
    expect(inOverlay, findsWidgets);

    await tester.pump(const Duration(seconds: 1));
    expect(tester.takeException(), isNull);
    expect(inOverlay, findsNothing);
    await tester.pumpWidget(const SizedBox());
    await tester.pump();
  });
}
