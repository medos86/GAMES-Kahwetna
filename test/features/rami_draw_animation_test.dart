import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kahwetne/core/services/card_animations.dart';
import 'package:kahwetne/features/menu/menu_models.dart';
import 'package:kahwetne/features/rami/rami_card_view.dart';
import 'package:kahwetne/features/rami/rami_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Pioche de Rami avec animation activée : l'écran reste stable pendant le vol (#224).
void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    cardAnimations.value = true;
  });

  tearDown(() => cardAnimations.value = false);

  testWidgets('pioche avec animation : pas d\'erreur pendant le vol', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844) * 3;
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      const MaterialApp(
        home: const RamiScreen(difficulty: Difficulty.facile, targetScore: 100),
      ),
    );
    await tester.pump(const Duration(seconds: 1));
    final stock = find.byType(RamiBackView).first;
    await tester.tap(stock);
    await tester.pump(const Duration(milliseconds: 100));
    expect(tester.takeException(), isNull);
    await tester.pump(const Duration(seconds: 1));
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
    await tester.pump();
  });
}
