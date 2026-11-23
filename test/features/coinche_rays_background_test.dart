// Fond rayons de la Belote (#807) : l'écran de jeu affiche les rayons de la Belote.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kahwetne/features/coinche/coinche_screen.dart';
import 'package:kahwetne/features/menu/menu_models.dart';
import 'package:kahwetne/widgets/game_rays_background.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets('#807 : fond Belote = rayons de la Belote', (tester) async {
    tester.view.physicalSize = const Size(360, 780);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      const MaterialApp(
        home: CoincheScreen(difficulty: Difficulty.facile, targetScore: 1000),
      ),
    );
    await tester.pump();
    final rays = tester.widget<GameRaysBackground>(
      find.byType(GameRaysBackground),
    );
    expect(rays.gameName, 'Belote');
    expect(tester.takeException(), isNull);
  });
}
