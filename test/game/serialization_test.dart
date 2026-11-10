import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:kahwetne/game/chkobba.dart';
import 'package:kahwetne/game/common.dart';
import 'package:kahwetne/game/domino.dart';

/// Passe par une vraie chaîne JSON : ce que verrait une sauvegarde ou un fichier de parité.
Map<String, dynamic> _viaJsonString(Map<String, dynamic> json) =>
    jsonDecode(jsonEncode(json)) as Map<String, dynamic>;

void main() {
  group('Domino : toJson / fromJson', () {
    test('aller-retour sur tous les états des fixtures TypeScript', () {
      final data = jsonDecode(
        File('test/parity/fixtures/domino_parity.json').readAsStringSync(),
      ) as Map<String, dynamic>;

      var checked = 0;
      for (final raw in data['scenarios'] as List<dynamic>) {
        final scenario = raw as Map<String, dynamic>;
        final initial = scenario['initial'] as Map<String, dynamic>;
        expect(DominoState.fromJson(initial).toJson(), equals(initial), reason: 'donne initiale');
        checked++;
        for (final step in scenario['steps'] as List<dynamic>) {
          final json = (step as Map<String, dynamic>)['state'] as Map<String, dynamic>;
          expect(DominoState.fromJson(json).toJson(), equals(json));
          checked++;
        }
      }
      expect(checked, greaterThan(200));
    });

    test('une donne survit à une chaîne JSON et reste jouable', () {
      final state = newDominoRound(targetScore: 50, random: math.Random(7).nextDouble);
      final restored = DominoState.fromJson(_viaJsonString(state.toJson()));
      expect(restored.toJson(), equals(state.toJson()));

      final tile = state.hands[state.turn]!.first;
      final fromOriginal = playDomino(state, state.turn, tile.id, DominoSide.left);
      final fromRestored = playDomino(restored, restored.turn, tile.id, DominoSide.left);
      expect(fromRestored.toJson(), equals(fromOriginal.toJson()));
    });

    test('champs nuls conservés (extrémités, gagnants)', () {
      final state = newDominoRound(targetScore: 50, random: () => 0.5);
      final restored = DominoState.fromJson(_viaJsonString(state.toJson()));
      expect(restored.leftEnd, isNull);
      expect(restored.rightEnd, isNull);
      expect(restored.roundWinner, isNull);
      expect(restored.matchWinner, isNull);
    });

    test('un domino posé garde son orientation', () {
      final placed = PlacedTile.fromJson({'id': '2-5', 'a': 2, 'b': 5, 'left': 5, 'right': 2});
      expect(placed.left, 5);
      expect(placed.right, 2);
      expect(placed.toJson(), {'id': '2-5', 'a': 2, 'b': 5, 'left': 5, 'right': 2});
    });

    test('accepte les entiers écrits 1.0 par certains encodeurs', () {
      final tile = DominoTile.fromJson({'id': '1-2', 'a': 1.0, 'b': 2.0});
      expect(tile.a, 1);
      expect(tile.b, 2);
    });
  });

  group('Chkobba : toJson / fromJson', () {
    test('carte : aller-retour', () {
      const card = ChkobbaCard(suit: ChkobbaSuit.deniers, rank: 7, id: 'deniers-7');
      final restored = ChkobbaCard.fromJson(card.toJson());
      expect(restored.suit, ChkobbaSuit.deniers);
      expect(restored.rank, 7);
      expect(restored.id, 'deniers-7');
      expect(restored.isHaya, isTrue);
      expect(card.toJson(), {'suit': 'deniers', 'rank': 7, 'id': 'deniers-7'});
    });

    test('nouvelle partie : aller-retour via une chaîne JSON', () {
      final state = newMatch(random: math.Random(3).nextDouble);
      final restored = ChkobbaState.fromJson(_viaJsonString(state.toJson()));
      expect(restored.toJson(), equals(state.toJson()));
      expect(restored.deck.length, state.deck.length);
      expect(restored.table.length, 4);
      expect(restored.lastCapturer, isNull);
      expect(restored.winner, isNull);
    });

    test('toutes les clés de l\'état sont présentes', () {
      final json = newMatch(random: () => 0.5).toJson();
      expect(
        json.keys.toSet(),
        {
          'targetScore',
          'deck',
          'hands',
          'table',
          'won',
          'chkobbas',
          'scores',
          'lastCapturer',
          'turn',
          'starter',
          'round',
          'winner',
        },
      );
    });

    test('après un coup : l\'état restauré joue comme l\'original', () {
      final state = newMatch(random: math.Random(11).nextDouble);
      final restored = ChkobbaState.fromJson(_viaJsonString(state.toJson()));

      final cardId = state.hands[state.turn]!.first.id;
      final fromOriginal = playCard(state, state.turn, cardId);
      final fromRestored = playCard(restored, restored.turn, cardId);

      expect(fromRestored.state.toJson(), equals(fromOriginal.state.toJson()));
      expect(fromRestored.chkobba, fromOriginal.chkobba);
      expect(fromRestored.haya, fromOriginal.haya);

      // L'état obtenu après le coup se sérialise lui aussi sans perte.
      final after = fromOriginal.state.toJson();
      expect(ChkobbaState.fromJson(_viaJsonString(after)).toJson(), equals(after));
    });

    test('lastCapturer et winner renseignés sont restaurés', () {
      final base = newMatch(random: () => 0.5).toJson();
      base['lastCapturer'] = 'opponent';
      base['winner'] = 'player';
      final restored = ChkobbaState.fromJson(base);
      expect(restored.lastCapturer, Player.opponent);
      expect(restored.winner, Player.player);
      expect(restored.toJson(), equals(base));
    });
  });
}
