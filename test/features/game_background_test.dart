import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kahwetne/features/menu/main_menu_screen.dart';
import 'package:kahwetne/features/menu/menu_models.dart';
import 'package:shared_preferences/shared_preferences.dart';

GameEntry _byName(String name) => gameEntries.firstWhere((g) => g.name == name);

// Fond photo par jeu sur l'écran de choix du niveau (#335).
void main() {
  test('Chkobba, Domino et Belote ont chacun leur photo', () {
    expect(
      _byName('Chkobba').backgroundAsset,
      'assets/images/game_bg/chkobba_sfax.webp',
    );
    expect(
      _byName('Domino').backgroundAsset,
      'assets/images/game_bg/domino_medina_tunis.webp',
    );
    expect(
      _byName('Belote').backgroundAsset,
      'assets/images/game_bg/coinche_kairouan.webp',
    );
  });

  test('les photos référencées existent dans les assets', () {
    for (final game in gameEntries) {
      if (game.backgroundAsset == kMenuBackgroundAsset) continue;
      expect(
        File(game.backgroundAsset).existsSync(),
        isTrue,
        reason: game.backgroundAsset,
      );
    }
  });

  test('les trois photos sont distinctes', () {
    final assets = {
      _byName('Chkobba').backgroundAsset,
      _byName('Domino').backgroundAsset,
      _byName('Belote').backgroundAsset,
    };
    expect(assets.length, 3);
  });

  test('Ludo et Rami gardent le fond commun', () {
    expect(_byName('Ludo').backgroundAsset, kMenuBackgroundAsset);
    expect(_byName('Rami').backgroundAsset, kMenuBackgroundAsset);
  });

  testWidgets(
    'le choix du niveau affiche la photo du jeu sélectionné',
    (tester) async {
      SharedPreferences.setMockInitialValues({});
      tester.view.physicalSize = const Size(390, 844) * 3;
      tester.view.devicePixelRatio = 3;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(const MaterialApp(home: MainMenuScreen()));
      await tester.pump(const Duration(milliseconds: 300));

      // Menu principal : fond commun.
      expect(find.byKey(const ValueKey(kMenuBackgroundAsset)), findsOneWidget);

      await tester.tap(find.text('Chkobba').first);
      await tester.pump(const Duration(milliseconds: 500));

      // Écran de niveau : photo de Chkobba.
      expect(
        find.byKey(const ValueKey('assets/images/game_bg/chkobba_sfax.webp')),
        findsOneWidget,
      );

      await tester.pumpWidget(const SizedBox());
      await tester.pump();
    },
  );
}
