// Tests unitaires de lib/game/ludo.dart (guide §6.1, Ludo).
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:kahwetne/game/ludo.dart';

/// État précis : progressions données par id de pion, les autres restent à la base.
LudoState makeState({
  required LudoColor turn,
  LudoPhase phase = LudoPhase.move,
  int? dice,
  Map<String, int> progress = const {},
  List<LudoColor> rankings = const [],
  int sixes = 0,
}) {
  final base = newLudoGame(turn);
  final tokens = [for (final t in base.tokens) t.copyWith(progress: progress[t.id] ?? 0)];
  return base.copyWith(
    tokens: tokens,
    phase: phase,
    dice: dice,
    rankings: rankings,
    sixes: sixes,
  );
}

void main() {
  group('sortie et coups légaux', () {
    test('un pion ne sort de la base que sur un 6', () {
      final state = makeState(turn: LudoColor.blue, dice: 4);
      expect(legalTokenIds(state), isEmpty);

      final six = makeState(turn: LudoColor.blue, dice: 6);
      expect(legalTokenIds(six), ['blue-0', 'blue-1', 'blue-2', 'blue-3']);
    });

    test('l\'arrivée doit être exacte : pas de dépassement du centre', () {
      final state = makeState(turn: LudoColor.blue, dice: 5, progress: {'blue-0': 54});
      expect(legalTokenIds(state), isEmpty);
    });

    test('hors de la phase move, aucun coup légal', () {
      final state = makeState(turn: LudoColor.blue, phase: LudoPhase.roll, dice: 6);
      expect(legalTokenIds(state), isEmpty);
    });

    test('rollDice hors de la phase roll renvoie l\'instance reçue', () {
      final state = makeState(turn: LudoColor.blue, phase: LudoPhase.move, dice: 2);
      expect(identical(rollDice(state, () => 0.5), state), isTrue);
    });
  });

  group('lancer de dé', () {
    test('trois 6 de suite : tour perdu et note ThreeSixesNote', () {
      final state = makeState(turn: LudoColor.blue, phase: LudoPhase.roll, sixes: 2);
      final next = rollDice(state, () => 0.99); // floor(0.99 * 6) + 1 = 6
      expect(next.dice, 6);
      expect(next.phase, LudoPhase.roll);
      expect(next.turn, LudoColor.red); // suivant de bleu dans l'ordre des tours
      expect(next.note, isA<ThreeSixesNote>());
      expect(next.note?.color, LudoColor.blue);
    });

    test('aucun coup possible : tour passé et note NoMoveNote', () {
      final state = makeState(turn: LudoColor.blue, phase: LudoPhase.roll);
      final next = rollDice(state, () => 0.0); // dé = 1, aucun pion ne sort
      expect(next.note, isA<NoMoveNote>());
      expect(next.turn, LudoColor.red);
    });
  });

  group('captures', () {
    test('arriver sur une case non sûre occupée renvoie l\'adversaire à la base', () {
      // Rouge (départ 1) à la progression 10 : case 10 de la piste, non sûre.
      // Bleu (départ 40) à la progression 22 + 1 = 23 : case (40 + 22) % 52 = 10.
      final state = makeState(
        turn: LudoColor.blue,
        dice: 1,
        progress: {'blue-0': 22, 'red-0': 10},
      );
      final next = moveToken(state, 'blue-0');
      expect(next.tokens.firstWhere((t) => t.id == 'red-0').progress, 0);
      expect(next.tokens.firstWhere((t) => t.id == 'blue-0').progress, 23);
      expect(next.note, isA<CapturedNote>());
      expect((next.note as CapturedNote).victims, [LudoColor.red]);
    });

    test('pas de capture sur une case sûre (case de départ + 8)', () {
      // Case 9 = départ rouge (1) + 8 : sûre.
      final state = makeState(
        turn: LudoColor.blue,
        dice: 1,
        progress: {'blue-0': 21, 'red-0': 9},
      );
      final next = moveToken(state, 'blue-0');
      expect(next.tokens.firstWhere((t) => t.id == 'red-0').progress, 9);
      expect(next.note, isNull);
    });
  });

  group('fin de partie', () {
    test('trois couleurs arrivées : phase end et classement complet', () {
      final state = makeState(
        turn: LudoColor.blue,
        dice: 3,
        rankings: [LudoColor.red, LudoColor.green],
        progress: {
          'blue-0': 57,
          'blue-1': 57,
          'blue-2': 57,
          'blue-3': 54,
          'red-0': 57,
          'red-1': 57,
          'red-2': 57,
          'red-3': 57,
          'green-0': 57,
          'green-1': 57,
          'green-2': 57,
          'green-3': 57,
        },
      );
      final next = moveToken(state, 'blue-3');
      expect(next.phase, LudoPhase.end);
      expect(next.rankings, hasLength(4));
      expect(next.rankings.last, LudoColor.yellow);
      expect(next.note, isA<FinishedNote>());
      expect((next.note as FinishedNote).place, 3);
    });
  });

  group('cases et sérialisation', () {
    test('cellOf : base sans case, centre et colonne d\'arrivée', () {
      expect(cellOf(const Token(id: 'red-0', color: LudoColor.red, progress: 0)), isNull);
      expect(cellOf(const Token(id: 'red-0', color: LudoColor.red, progress: ludoFinish)), ludoGoal);
      expect(
        cellOf(const Token(id: 'red-0', color: LudoColor.red, progress: 52)),
        const Cell(7, 1),
      );
    });

    test('LudoState : toJson puis fromJson redonne le même JSON', () {
      final state = newLudoGame();
      final json = state.toJson();
      final decoded = jsonDecode(jsonEncode(json)) as Map<String, dynamic>;
      expect(LudoState.fromJson(decoded).toJson(), equals(json));
    });
  });
}
