import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kahwetne/app/game_routes.dart';
import 'package:kahwetne/core/audio/sounds.dart';
import 'package:kahwetne/core/i18n/app_language.dart';
import 'package:kahwetne/features/chkobba/chkobba_card_face.dart';
import 'package:kahwetne/features/comic_demo/comic_demo_screen.dart';
import 'package:kahwetne/features/domino/domino_tiles.dart';
import 'package:kahwetne/features/menu/menu_models.dart';
import 'package:kahwetne/game/chkobba.dart';
import 'package:kahwetne/game/domino.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Toutes les faces de dominos et de cartes, langues et routes (#167 : couverture).
Widget _host(Widget child) {
  return MaterialApp(home: Scaffold(body: Center(child: child)));
}

void main() {
  tearDown(() => appLanguage.value = AppLanguage.fr);

  testWidgets('dominos : toutes les valeurs de pions', (tester) async {
    for (var first = 0; first <= 6; first++) {
      await tester.pumpWidget(
        _host(
          DominoFace(
            first: first,
            second: 6 - first,
            width: 60,
            height: 30,
            horizontal: true,
            highlight: false,
          ),
        ),
      );
      await tester.pumpWidget(
        _host(
          DominoFace(
            first: 6 - first,
            second: first,
            width: 30,
            height: 60,
            horizontal: false,
            highlight: true,
          ),
        ),
      );
    }
    expect(find.byType(DominoFace), findsOneWidget);
  });

  testWidgets('tuiles de chaîne dans les quatre orientations', (tester) async {
    const tile = PlacedTile(id: 'q', a: 3, b: 6, left: 3, right: 6);
    for (final turn in [false, true]) {
      for (final reverse in [false, true]) {
        await tester.pumpWidget(
          _host(
            ChainTile(
              tile: tile,
              length: 60,
              turn: turn,
              reverse: reverse,
            ),
          ),
        );
      }
    }
    expect(find.byType(ChainTile), findsOneWidget);
  });

  testWidgets('cartes Chkobba de chaque couleur et de chaque rang', (
    tester,
  ) async {
    for (final suit in ChkobbaSuit.values) {
      for (final rank in [1, 7, 8, 9, 10]) {
        await tester.pumpWidget(
          _host(
            ChkobbaCardFace(
              card: ChkobbaCard(suit: suit, rank: rank, id: '$suit$rank'),
            ),
          ),
        );
      }
    }
    expect(find.byType(ChkobbaCardFace), findsOneWidget);
  });

  testWidgets('écran de démonstration BD', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: ComicDemoScreen()));
    await tester.pump(const Duration(seconds: 1));
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
    await tester.pump();
  });

  test('libellés en arabe, repli sur la clé si absente', () {
    appLanguage.value = AppLanguage.ar;
    expect(t('chkobbaRules'), 'القواعد');
    expect(isRtl(AppLanguage.ar), isTrue);
    expect(localeOf(AppLanguage.ar).languageCode, 'ar');
    expect(t('clé_inexistante'), 'clé_inexistante');
  });

  test('routes : niveau par défaut et jeu par chemin', () {
    expect(parseDifficulty('moyen'), Difficulty.moyen);
    expect(parseDifficulty(null), Difficulty.facile);
    expect(parseDifficulty('inconnu'), Difficulty.facile);
    expect(gameForRoute('/ludo')?.name, 'Ludo');
    expect(gameForRoute('/inexistant'), isNull);
  });

  test('langue : enregistrée puis rechargée', () async {
    SharedPreferences.setMockInitialValues({});
    await loadLanguage();
    await setLanguage(AppLanguage.ar);
    expect(appLanguage.value, AppLanguage.ar);
    await setLanguage(AppLanguage.fr);
    expect(appLanguage.value, AppLanguage.fr);
    expect(tf('ludoPlayers', {'n': '2'}), isNotEmpty);
  });

  test('sons : chaque effet a un fichier', () {
    for (final sfx in Sfx.values) {
      expect(sfx.assetPath, isNotEmpty);
    }
  });

  test('routes de jeu : chaque chemin donne une route', () {
    for (final path in ['/game', '/domino', '/coinche', '/ludo', '/rami']) {
      expect(buildGameRoute(path), isNotNull);
    }
    expect(buildGameRoute(null), isNull);
  });
}
