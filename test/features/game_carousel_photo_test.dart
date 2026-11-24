// Photos mascottes du carrousel : une par jeu, nom en français.
import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kahwetne/features/menu/main_menu/game_carousel.dart';
import 'package:kahwetne/features/menu/menu_models.dart';
import 'package:material_ui/material_ui.dart';

const _chkobbaPath = 'assets/images/mascots/chkobba.jpg';
const _ramiPath = 'assets/images/mascots/rami.jpg';

GameEntry _game(String name) => gameEntries.firstWhere((g) => g.name == name);

bool _isPhoto(Widget w, String path) {
  if (w is! Image) return false;
  final provider = w.image;
  return provider is AssetImage && provider.assetName == path;
}

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
  test('photos mascottes présentes', () {
    for (final name in ['Chkobba', 'Domino', 'Belote', 'Rami']) {
      final photo = _game(name).photoAsset;
      expect(photo, isNotNull, reason: name);
      expect(File(photo!).existsSync(), isTrue, reason: photo);
    }
  });

  test('Rami utilise sa photo mascotte', () {
    expect(_game('Rami').photoAsset, _ramiPath);
  });

  test('noms en français, sans arabe', () {
    final ascii = RegExp(r'^[A-Za-zÀ-ÿ ]+$');
    for (final g in gameEntries) {
      expect(ascii.hasMatch(g.name), isTrue, reason: g.name);
    }
  });

  testWidgets('le carrousel affiche la photo du jeu central', (tester) async {
    await _pump(tester);

    final photo = find.byWidgetPredicate((w) => _isPhoto(w, _chkobbaPath));
    expect(photo, findsWidgets);
    expect(find.text('Chkobba'), findsWidgets);
  });

  testWidgets('Rami affiche sa photo après le repli', (tester) async {
    await _pump(tester);
    // Rami est à l'index 4 : on remonte d'un cran depuis Chkobba (index 0).
    await tester.tap(find.bySemanticsLabel('Jeu précédent'));
    await tester.pumpAndSettle();

    final photo = find.byWidgetPredicate((w) => _isPhoto(w, _ramiPath));
    expect(find.text('Rami'), findsWidgets);
    expect(photo, findsWidgets);
  });
}
