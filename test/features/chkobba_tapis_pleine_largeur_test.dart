// Issue #801 : le tapis prend toute la largeur du feutre, cartes aux proportions 5/7.
// Mise à jour : cartes du tapis plafonnées (plus petites), tapis allégé comme Rami.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kahwetne/core/services/card_animations.dart';
import 'package:kahwetne/features/chkobba/chkobba_card_face.dart';
import 'package:kahwetne/features/chkobba/chkobba_screen.dart';
import 'package:kahwetne/features/chkobba/chkobba_table.dart';
import 'package:kahwetne/features/menu/menu_models.dart';
import 'package:kahwetne/game/chkobba.dart';
import 'package:kahwetne/game/common.dart';
import 'package:shared_preferences/shared_preferences.dart';

ChkobbaCard _card(ChkobbaSuit suit, int rank) =>
    ChkobbaCard(suit: suit, rank: rank, id: '${suit.name}-$rank');

ChkobbaState _state() => ChkobbaState(
      targetScore: 11,
      deck: [_card(ChkobbaSuit.epees, 3)],
      hands: {
        Player.player: [_card(ChkobbaSuit.batons, 5)],
        Player.opponent: [_card(ChkobbaSuit.deniers, 2)],
      },
      table: [
        _card(ChkobbaSuit.coupes, 5),
        _card(ChkobbaSuit.coupes, 7),
      ],
      won: {Player.player: [], Player.opponent: []},
      chkobbas: {Player.player: 0, Player.opponent: 0},
      scores: {Player.player: 0, Player.opponent: 0},
      lastCapturer: null,
      turn: Player.player,
      starter: Player.player,
      round: 1,
      winner: null,
    );

Future<void> _pump(WidgetTester tester) async {
  tester.view.physicalSize = const Size(390, 844) * 3;
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(
    MaterialApp(
      home: ChkobbaScreen(
        difficulty: Difficulty.facile,
        targetScore: 11,
        initialState: _state(),
      ),
    ),
  );
  await tester.pump();
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    cardAnimations.value = false;
  });

  testWidgets('#801 : le tapis prend toute la largeur du feutre', (
    tester,
  ) async {
    await _pump(tester);
    final felt = tester.getRect(find.byKey(const ValueKey('chkobba-felt')));
    final table = tester.getRect(find.byType(ChkobbaTable));
    // Seules la bordure et les marges du feutre restent : le tapis garde plus de 90 % de sa largeur.
    expect(table.width, greaterThan(felt.width * 0.9));
    expect(table.width, lessThanOrEqualTo(felt.width));
    expect(tester.takeException(), isNull);
  });

  testWidgets('#801 : cartes du tapis aux proportions 5/7', (tester) async {
    await _pump(tester);
    final faces = find.descendant(
      of: find.byType(ChkobbaTable),
      matching: find.byType(ChkobbaCardFace),
    );
    expect(faces, findsNWidgets(2));
    final size = tester.getSize(faces.first);
    expect(size.width / size.height, closeTo(5 / 7, 0.02));
    expect(tester.takeException(), isNull);
  });

  testWidgets('cartes du tapis plafonnées à la taille compacte', (
    tester,
  ) async {
    await _pump(tester);
    final faces = find.descendant(
      of: find.byType(ChkobbaTable),
      matching: find.byType(ChkobbaCardFace),
    );
    // Tapis allégé : les cartes posées ne dépassent pas la largeur compacte.
    expect(
      tester.getSize(faces.first).width,
      closeTo(kChkobbaTableCardWidth, 0.5),
    );
    expect(tester.takeException(), isNull);
  });
}
