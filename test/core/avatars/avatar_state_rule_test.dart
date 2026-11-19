import 'package:flutter_test/flutter_test.dart';
import 'package:kahwetne/core/avatars/avatar_catalog.dart';
import 'package:kahwetne/core/avatars/avatar_state_rule.dart';

/// Issue #556 : table de vérité des états d'avatar.
void main() {
  test('pendant la partie : jamais fâché', () {
    final outcome = outcomeFor(playerId: 0, winners: [], finished: false);
    expect(outcome, RoundOutcome.playing);
    expect(avatarStateFor(outcome), AvatarState.neutral);
  });

  test('fin : gagnant heureux, perdant fâché', () {
    expect(
      avatarStateFor(
        outcomeFor(playerId: 1, winners: [1], finished: true),
      ),
      AvatarState.happy,
    );
    expect(
      avatarStateFor(
        outcomeFor(playerId: 0, winners: [1], finished: true),
      ),
      AvatarState.angry,
    );
  });

  test('égalité : neutre pour tout le monde', () {
    final outcome = outcomeFor(playerId: 0, winners: [], finished: true);
    expect(outcome, RoundOutcome.tie);
    expect(avatarStateFor(outcome), AvatarState.neutral);
  });

  test('équipe gagnante (plusieurs gagnants) : chaque membre est heureux', () {
    expect(
      avatarStateFor(
        outcomeFor(playerId: 2, winners: [0, 2], finished: true),
      ),
      AvatarState.happy,
    );
  });
}
