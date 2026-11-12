import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:kahwetne/game/common.dart';
import 'package:kahwetne/game/domino.dart';

/// Rejoue les tirages enregistrés côté TypeScript (Math.random).
class _Replay {
  _Replay(this._values);

  final List<dynamic> _values;
  int consumed = 0;

  double next() {
    if (consumed >= _values.length) fail('tirages épuisés');
    return (_values[consumed++] as num).toDouble();
  }
}

/// Parties générées par tsrun/gen_domino.ts à partir de src/app/game/domino.ts.
/// Chaque étape compare l'état Dart à l'état TypeScript, et l'identité du retour
/// (même instance quand l'action est refusée).
void main() {
  final data = jsonDecode(
    File('test/parity/fixtures/domino_parity.json').readAsStringSync(),
  ) as Map<String, dynamic>;
  final scenarios = data['scenarios'] as List<dynamic>;

  for (final raw in scenarios) {
    final scenario = raw as Map<String, dynamic>;
    test(
      'partie seed ${scenario['seed']} (cible ${scenario['targetScore']})',
      () {
        final randoms = scenario['randoms'] as List<dynamic>;
        final replay = _Replay(randoms);
        var state = newDominoRound(
          targetScore: scenario['targetScore'] as int,
          random: replay.next,
        );
        expect(
          state.toJson(),
          equals(scenario['initial']),
          reason: 'donne initiale',
        );

        final steps = scenario['steps'] as List<dynamic>;
        for (var i = 0; i < steps.length; i++) {
          final step = steps[i] as Map<String, dynamic>;
          final player = Player.values.byName(step['player'] as String);
          final kind = step['kind'] as String;
          final DominoState next;
          switch (kind) {
            case 'play':
              final side = (step['side'] as String) == 'left'
                  ? DominoSide.left
                  : DominoSide.right;
              next = playDomino(state, player, step['tileId'] as String, side);
            case 'draw':
              next = drawDomino(state, player);
            case 'pass':
              next = passDomino(state, player);
            default:
              fail('type d\'action inconnu : $kind');
          }

          expect(
            identical(next, state),
            step['same'] as bool,
            reason: 'étape $i ($kind) : identité',
          );
          expect(
            next.toJson(),
            equals(step['state']),
            reason: 'étape $i ($kind) : état',
          );
          state = next;
        }

        expect(
          replay.consumed,
          randoms.length,
          reason: 'tous les tirages utilisés',
        );
      },
    );
  }

  group('règles de base', () {
    test('donne : 7 tuiles par joueur, 14 en pioche, 28 au total', () {
      final state = newDominoRound(targetScore: 50, random: () => 0.5);
      expect(state.hands[Player.player], hasLength(7));
      expect(state.hands[Player.opponent], hasLength(7));
      expect(state.boneyard, hasLength(14));
    });

    test('le premier domino est libre', () {
      final state = newDominoRound(targetScore: 50, random: () => 0.5);
      final tile = state.hands[state.turn]!.first;
      final next = playDomino(state, state.turn, tile.id, DominoSide.left);
      expect(next, isNot(same(state)));
      expect(next.chain, hasLength(1));
      expect(next.leftEnd, tile.a);
      expect(next.rightEnd, tile.b);
    });
  });
}
