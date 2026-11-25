// Carte du carrousel : pas de bandeau titre, mascotte agrandie, nom du jeu à la place de « JOUER ».
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kahwetne/features/menu/main_menu/game_carousel.dart';
import 'package:material_ui/material_ui.dart';

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
  await tester.pump(const Duration(seconds: 1));
}

void main() {
  testWidgets('le bouton JOUER a disparu de la carte', (tester) async {
    await _pump(tester);
    expect(find.text('JOUER'), findsNothing);
  });

  testWidgets('plus de bandeau titre 38 px au-dessus de la mascotte',
      (tester) async {
    await _pump(tester);
    final banner = find.byWidgetPredicate(
      (w) => w is Text && w.style?.fontSize == 38,
    );
    expect(banner, findsNothing);
  });

  testWidgets('le nom du jeu remplace JOUER, en Bangers, en bas de carte',
      (tester) async {
    await _pump(tester);
    final name = find.text('Chkobba');
    expect(name, findsWidgets);
    final text = tester.widget<Text>(name.first);
    expect(text.style?.fontFamily, 'Bangers');
    expect(text.style?.fontSize, 30);
  });

  testWidgets('la mascotte est agrandie (au moins 0,5 de la carte)',
      (tester) async {
    await _pump(tester);
    final photo = find.byWidgetPredicate(
      (w) =>
          w is Image &&
          w.image is AssetImage &&
          (w.image as AssetImage).assetName ==
              'assets/images/mascots/chkobba.png',
    );
    expect(photo, findsWidgets);
    // Carte : 62 % de la largeur 400 => 248 px ; la photo fait 1,4 × 0,56 × 248.
    final size = tester.getSize(photo.first);
    expect(size.height, greaterThanOrEqualTo(248 * 0.5));
  });
}
