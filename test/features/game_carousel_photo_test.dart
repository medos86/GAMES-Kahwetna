// Photos mascottes du carrousel : une par jeu (Ludo et Rami exclus), nom en français.
import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kahwetne/features/menu/main_menu/game_carousel.dart';
import 'package:kahwetne/features/menu/menu_models.dart';
import 'package:material_ui/material_ui.dart';

GameEntry _game(String name) => gameEntries.firstWhere((g) => g.name == name);

Future<void> _pump(WidgetTester tester) async {
  tester.view.physicalSize = const Size(800, 1200);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: SizedBox(
          width: 400,
          height: 600,
          child: GameCarousel(onSelect: (_) {}, onChanged: (_) {}),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  test('Chkobba, Domino, Belote et Rami ont une photo mascotte existante', () {
    for (final name in ['Chkobba', 'Domino', 'Belote', 'Rami']) {
      final photo = _game(name).photoAsset;
      expect(photo, isNotNull, reason: name);
      expect(File(photo!).existsSync(), isTrue, reason: photo);
    }
  });

  test('Rami utilise sa photo mascotte', () {
    expect(_game('Rami').photoAsset, 'assets/images/mascots/rami.jpg');
  });

  test('les noms affichés sont en français, sans nom arabe', () {
    for (final g in gameEntries) {
      expect(RegExp(r'^[A-Za-zÀ-ÿ ]+$').hasMatch(g.name), isTrue,
          reason: g.name);
    }
  });

  testWidgets('le carrousel affiche la photo du jeu central', (tester) async {
    await _pump(tester);

    final chkobbaPhoto = find.byWidgetPredicate(
      (w) =>
          w is Image &&
          w.image is AssetImage &&
          (w.image as AssetImage).assetName ==
              'assets/images/mascots/chkobba.jpg',
    );
    expect(chkobbaPhoto, findsWidgets);
    expect(find.text('Chkobba'), findsWidgets);
  });

  testWidgets('Rami affiche sa photo après le repli', (tester) async {
    await _pump(tester);
    // Rami est à l'index 4 : on remonte d'un cran depuis Chkobba (index 0).
    await tester.tap(find.bySemanticsLabel('Jeu précédent'));
    await tester.pumpAndSettle();

    final ramiPhoto = find.byWidgetPredicate(
      (w) =>
          w is Image &&
          w.image is AssetImage &&
          (w.image as AssetImage).assetName ==
              'assets/images/mascots/rami.jpg',
    );
    expect(find.text('Rami'), findsWidgets);
    expect(ramiPhoto, findsWidgets);
  });
}
