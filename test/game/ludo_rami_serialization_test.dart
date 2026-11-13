import 'package:flutter_test/flutter_test.dart';
import 'package:kahwetne/game/ludo.dart';
import 'package:kahwetne/game/rami.dart' as rules;

// Sauvegarde et reprise du Ludo et du Rami, et règles de base (#167).
void main() {
  test('Ludo : pion et note relus depuis le JSON', () {
    const token = Token(id: 'b1', color: LudoColor.blue, progress: 3);
    final back = Token.fromJson(token.toJson());
    expect(back.id, 'b1');
    expect(back.color, LudoColor.blue);
    expect(back.progress, 3);

    final noMove = LudoNote.fromJson({'kind': 'noMove', 'color': 'red'});
    expect(noMove.toJson(), {'kind': 'noMove', 'color': 'red'});
    final threeSixes =
        LudoNote.fromJson({'kind': 'threeSixes', 'color': 'green'});
    expect(threeSixes.toJson(), {'kind': 'threeSixes', 'color': 'green'});
  });

  test('Ludo : partie neuve, relue puis tour de dé', () {
    final game = newLudoGame();
    final json = game.toJson();
    expect(LudoState.fromJson(json).toJson(), json);

    final rolled = rollDice(game, () => 0.5);
    expect(rolled.toJson(), isNot(equals(json)));
    final ids = legalTokenIds(rolled);
    if (ids.isNotEmpty) {
      moveToken(rolled, ids.first);
    }
    chooseMove(rolled, LudoAiLevel.difficile, () => 0.2);
    chooseMove(rolled, LudoAiLevel.moyen, () => 0.7);
    chooseMove(rolled, LudoAiLevel.facile, () => 0.1);
  });

  test('Ludo : cases du parcours et colonne d\'arrivée', () {
    for (final color in LudoColor.values) {
      expect(ludoHomeColumn(color), isNotEmpty);
      expect(ludoStartIndex(color), isA<int>());
    }
    trackIndex(LudoColor.red, 0);
    trackIndex(LudoColor.red, 99);
    cellOf(const Token(id: 'r1', color: LudoColor.red, progress: 0));
  });

  test('Rami : donne neuve relue depuis le JSON', () {
    final match = rules.newMatch(100, () => 0.37);
    final json = match.toJson();
    expect(rules.RamiState.fromJson(json).toJson(), json);
  });

  test('Rami : carte, combinaison et valeur des points', () {
    const card = rules.RamiCard(id: 'c5', suit: rules.RamiSuit.coupes, rank: 5);
    final back = rules.RamiCard.fromJson(card.toJson());
    expect(back.rank, 5);
    expect(back.suit, rules.RamiSuit.coupes);
    expect(rules.isJoker(card), isFalse);
    expect(rules.cardValue(card), 5);
    expect(rules.nextSeat(3), 0);
    expect(rules.pointsOf([card]), 5);

    const run = [
      rules.RamiCard(id: 'a', suit: rules.RamiSuit.epees, rank: 4),
      rules.RamiCard(id: 'b', suit: rules.RamiSuit.epees, rank: 5),
      rules.RamiCard(id: 'c', suit: rules.RamiSuit.epees, rank: 6),
    ];
    expect(rules.isValidMeld(run), isTrue);
    expect(rules.arrangeMeld(run), hasLength(3));
    expect(rules.meldGroups(run), isA<List<List<rules.RamiCard>>>());
  });

  test('Rami : résultat de manche relu depuis le JSON', () {
    const result = rules.RamiRoundResult(
      winner: 1,
      penalties: [0, 12, 30, 5],
    );
    final json = result.toJson();
    expect(rules.RamiRoundResult.fromJson(json).toJson(), json);
  });

  test('Rami : piocher et défausser depuis une donne', () {
    final match = rules.newMatch(100, () => 0.37);
    final drawn = rules.drawStock(match, () => 0.37);
    rules.drawDiscard(drawn);
    rules.cancelStaged(drawn);
    rules.commitOpening(drawn);
    rules.discardCard(drawn, drawn.hands[0].first.id);
    rules.nextRound(match, () => 0.37);
  });
}
