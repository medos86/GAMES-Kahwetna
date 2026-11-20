import 'package:flutter_test/flutter_test.dart';
import 'package:kahwetne/core/avatars/avatar_catalog.dart';
import 'package:kahwetne/core/avatars/game_avatars.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Issue #551 : état d'avatar partagé par les jeux et avatars par siège.
void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  group('gameAvatarState', () {
    test('neutre pendant la partie', () {
      expect(
        gameAvatarState(seat: 0, finished: false, winners: const []),
        AvatarState.neutral,
      );
    });

    test('heureux pour le gagnant, fâché pour le perdant', () {
      expect(
        gameAvatarState(seat: 0, finished: true, winners: const [0]),
        AvatarState.happy,
      );
      expect(
        gameAvatarState(seat: 1, finished: true, winners: const [0]),
        AvatarState.angry,
      );
    });

    test('neutre à égalité', () {
      expect(
        gameAvatarState(seat: 1, finished: true, winners: const []),
        AvatarState.neutral,
      );
    });
  });

  test('loadGameAvatars donne des avatars distincts, le joueur en premier',
      () async {
    final ids = await loadGameAvatars(seats: 2);
    expect(ids, hasLength(2));
    expect(ids.toSet(), hasLength(2));
    expect(ids.every((id) => avatarCatalog.any((a) => a.id == id)), isTrue);
  });
}
