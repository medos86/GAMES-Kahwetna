// Fond rayons du Ludo (#808) : l'écran de jeu affiche les rayons du Ludo.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kahwetne/features/ludo/ludo_screen.dart';
import 'package:kahwetne/features/menu/menu_models.dart';
import 'package:kahwetne/widgets/game_rays_background.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets('#808 : fond Ludo = rayons du Ludo', (tester) async {
    tester.view.physicalSize = const Size(360, 780);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      const MaterialApp(
        home: LudoScreen(difficulty: Difficulty.facile, players: 2),
      ),
    );
    await tester.pump();
    final rays = tester.widget<GameRaysBackground>(
      find.byType(GameRaysBackground),
    );
    expect(rays.gameName, 'Ludo');
    expect(tester.takeException(), isNull);
  });
}
