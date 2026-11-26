import 'package:flutter_test/flutter_test.dart';
import 'package:kahwetne/game/ludo.dart';

// Ordre d'arrivée au centre et sérialisation du rang d'arrivée (#996).
void main() {
  test('un pion qui arrive au centre reçoit le rang 1 puis les suivants', () {
    var state = newLudoGame().copyWith(
      turn: LudoColor.red,
      phase: LudoPhase.move,
      dice: 1,
      tokens: [
        const Token(id: 'red-0', color: LudoColor.red, progress: 56),
        const Token(id: 'red-1', color: LudoColor.red, progress: 56),
        const Token(id: 'blue-0', color: LudoColor.blue, progress: 0),
      ],
    );
    state = moveToken(state, 'red-0');
    expect(state.tokens.firstWhere((t) => t.id == 'red-0').arrival, 1);
    expect(state.tokens.firstWhere((t) => t.id == 'red-1').arrival, isNull);
  });

  test('le rang d arrivée survit à une sérialisation JSON', () {
    const token = Token(id: 'red-0', color: LudoColor.red, progress: ludoFinish, arrival: 3);
    final back = Token.fromJson(token.toJson());
    expect(back.arrival, 3);
  });

  test('un pion non arrivé ne porte pas de clé arrival (format existant inchangé)', () {
    const token = Token(id: 'red-0', color: LudoColor.red, progress: 5);
    expect(token.toJson().containsKey('arrival'), isFalse);
  });
}
