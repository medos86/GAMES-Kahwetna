// Tests du contrôleur de la Coinche (guide §10.5) : délais de l'IA, minuteurs et dispose().
import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kahwetne/features/coinche/coinche_controller.dart';
import 'package:kahwetne/features/menu/menu_models.dart';
import 'package:kahwetne/game/coinche.dart';

/// Tirage constant : donne déterministe, sans dépendre du hasard.
CoincheController makeController({Difficulty difficulty = Difficulty.moyen}) =>
    CoincheController(target: 1000, difficulty: difficulty, random: () => 0.5);

void main() {
  test('la partie démarre au tour de l\'humain, sans minuteur en attente', () {
    fakeAsync((async) {
      final c = makeController();
      expect(c.round.dealer, firstDealer);
      expect(c.round.turn, Seat.south);
      expect(c.isBiddingTurn, isTrue);
      expect(c.hand, hasLength(handSize));
      expect(async.pendingTimers, isEmpty);
      c.dispose();
    });
  });

  test('l\'IA annonce 900 ms après son tour', () {
    fakeAsync((async) {
      final c = makeController();
      c.callBid(const PassBid()); // l\'humain passe : tour de l\'ouest
      expect(c.round.turn, Seat.west);

      async.elapse(const Duration(milliseconds: 899));
      expect(c.round.calls.containsKey(Seat.west), isFalse);

      async.elapse(const Duration(milliseconds: 1));
      expect(c.round.calls.containsKey(Seat.west), isTrue);
      c.dispose();
    });
  });

  test('dispose annule le minuteur de l\'IA', () {
    fakeAsync((async) {
      final c = makeController();
      c.callBid(const PassBid());
      expect(async.pendingTimers, isNotEmpty);

      c.dispose();
      expect(async.pendingTimers, isEmpty);
    });
  });

  test('le jeu aléatoire n\'est activé qu\'au niveau facile', () {
    expect(makeController(difficulty: Difficulty.facile).randomPlay, isTrue);
    expect(makeController(difficulty: Difficulty.moyen).randomPlay, isFalse);
    expect(
      makeController(difficulty: Difficulty.difficile).randomPlay,
      isFalse,
    );
  });

  test('restart remet la partie à zéro avec la même cible', () {
    final c = makeController();
    c.restart();
    expect(c.match.round, 1);
    expect(c.match.target, 1000);
    expect(c.summary, isNull);
    expect(c.match.scores[Team.ns], 0);
    expect(c.match.scores[Team.ew], 0);
    c.dispose();
  });
}
