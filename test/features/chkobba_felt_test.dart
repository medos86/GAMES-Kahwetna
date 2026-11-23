// Tapis plein écran (#658) : les mains de Chkobba sont posées sur le feutre,
// aucune bande en dehors.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kahwetne/features/chkobba/chkobba_screen.dart';
import 'package:kahwetne/features/menu/menu_models.dart';
import 'package:kahwetne/features/chkobba/chkobba_card_face.dart';
import 'package:kahwetne/widgets/game_rays_background.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets(
    '#658 : la main adverse est sur le feutre',
    (tester) async {
      tester.view.physicalSize = const Size(360, 780);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        const MaterialApp(
          home: ChkobbaScreen(difficulty: Difficulty.facile, targetScore: 11),
        ),
      );
      await tester.pump();
      final felt = find.byKey(const ValueKey('chkobba-felt'));
      expect(felt, findsOneWidget);
      expect(
        find.descendant(of: felt, matching: find.byType(ChkobbaCardBack)),
        findsWidgets,
      );
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('#805 : fond Chkobba = rayons du jeu', (tester) async {
    tester.view.physicalSize = const Size(360, 780);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      const MaterialApp(
        home: ChkobbaScreen(difficulty: Difficulty.facile, targetScore: 11),
      ),
    );
    await tester.pump();
    expect(find.byType(GameRaysBackground), findsOneWidget);
    final rays = tester.widget<GameRaysBackground>(
      find.byType(GameRaysBackground),
    );
    expect(rays.gameName, 'Chkobba');
    expect(tester.takeException(), isNull);
  });
}
