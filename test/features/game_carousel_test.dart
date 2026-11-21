// Carrousel 3D des jeux : flèches, glisser, sélection et teinte d'ambiance.
import 'package:flutter_test/flutter_test.dart';
import 'package:kahwetne/features/menu/main_menu/game_carousel.dart';
import 'package:kahwetne/features/menu/menu_models.dart';
import 'package:material_ui/material_ui.dart';

Future<void> _pump(
  WidgetTester tester, {
  required void Function(GameEntry) onSelect,
  required void Function(GameEntry) onChanged,
}) async {
  tester.view.physicalSize = const Size(800, 1200);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: SizedBox(
          width: 400,
          height: 600,
          child: GameCarousel(onSelect: onSelect, onChanged: onChanged),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  test('carouselIndexOf boucle sur la liste des jeux', () {
    final n = gameEntries.length;
    expect(carouselIndexOf(0), 0);
    expect(carouselIndexOf(n), 0);
    expect(carouselIndexOf(n + 2), 2);
  });

  testWidgets('la flèche droite passe au jeu suivant et prévient le parent',
      (tester) async {
    final changed = <String>[];
    await _pump(
      tester,
      onSelect: (_) {},
      onChanged: (g) => changed.add(g.name),
    );

    await tester.tap(find.bySemanticsLabel('Jeu suivant'));
    await tester.pumpAndSettle();

    expect(changed, [gameEntries[1].name]);
    expect(find.text(gameEntries[1].name), findsOneWidget);
  });

  testWidgets('la flèche gauche revient au jeu précédent', (tester) async {
    final changed = <String>[];
    await _pump(
      tester,
      onSelect: (_) {},
      onChanged: (g) => changed.add(g.name),
    );

    await tester.tap(find.bySemanticsLabel('Jeu précédent'));
    await tester.pumpAndSettle();

    expect(changed, [gameEntries.last.name]);
  });

  testWidgets('glisser le carrousel change de jeu', (tester) async {
    final changed = <String>[];
    await _pump(
      tester,
      onSelect: (_) {},
      onChanged: (g) => changed.add(g.name),
    );

    await tester.fling(find.byType(PageView), const Offset(-300, 0), 1200);
    await tester.pumpAndSettle();

    expect(changed, [gameEntries[1].name]);
  });

  testWidgets('toucher le jeu affiché le sélectionne', (tester) async {
    GameEntry? selected;
    await _pump(
      tester,
      onSelect: (g) => selected = g,
      onChanged: (_) {},
    );

    await tester.tap(find.bySemanticsLabel(gameEntries.first.name));
    await tester.pumpAndSettle();

    expect(selected?.name, gameEntries.first.name);
  });

  testWidgets('la teinte d\'ambiance prend la couleur du jeu', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Stack(
          children: [
            MoodTint(color: gameEntries.first.gradientFrom),
          ],
        ),
      ),
    );
    expect(find.byType(MoodTint), findsOneWidget);
  });
}
