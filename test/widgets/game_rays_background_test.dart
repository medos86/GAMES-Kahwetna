import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kahwetne/features/menu/menu_models.dart';
import 'package:kahwetne/widgets/game_rays_background.dart';
import 'package:kahwetne/widgets/texture_patterns.dart';

void main() {
  test('chaque jeu retrouve les rayons de son écran de niveau', () {
    for (final game in gameEntries) {
      expect(
        GameRaysBackground.assetFor(game.name),
        game.backgroundAsset,
        reason: game.name,
      );
    }
  });

  test('les rayons de chaque jeu existent dans les assets', () {
    for (final game in gameEntries) {
      expect(
        File(GameRaysBackground.assetFor(game.name)).existsSync(),
        isTrue,
        reason: game.name,
      );
    }
  });

  test('un jeu inconnu lève une erreur', () {
    expect(() => GameRaysBackground.assetFor('Inconnu'), throwsStateError);
  });

  testWidgets('affiche un dégradé et une trame de points, sans image', (tester) async {
    await tester.pumpWidget(
      const Directionality(
        textDirection: TextDirection.ltr,
        child: GameRaysBackground(gameName: 'Rami'),
      ),
    );
    expect(find.byType(Image), findsNothing);
    expect(find.byType(DotPattern), findsOneWidget);
  });
}
