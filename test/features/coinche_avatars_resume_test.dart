// Issue #1027 : les avatars de la Belote (Coinche) reprennent leur place à « Reprendre ».
import 'package:flutter_test/flutter_test.dart';
import 'package:kahwetne/core/services/saved_game_store.dart';
import 'package:kahwetne/features/coinche/coinche_controller.dart';
import 'package:kahwetne/features/menu/menu_models.dart';

class _MemoryStore implements SavedGameStore {
  final Map<String, Map<String, dynamic>> data = {};

  @override
  Future<Map<String, dynamic>?> load(String game) async => data[game];

  @override
  Future<void> save(String game, Map<String, dynamic> json) async {
    data[game] = json;
  }

  @override
  Future<void> clear(String game) async => data.remove(game);
}

CoincheController _make(SavedGameStore? store) => CoincheController(
      target: 1000,
      difficulty: Difficulty.moyen,
      random: () => 0.5,
      store: store,
    );

void main() {
  test('les avatars fixés sont sauvegardés avec la partie', () async {
    final store = _MemoryStore();
    final c = _make(store);
    await c.restore();
    c.setAvatarIds(const ['lion', 'tiger', 'panda', 'cat']);

    final saved = store.data['coinche'];
    expect(saved, isNotNull);
    expect(saved!['avatars'], ['lion', 'tiger', 'panda', 'cat']);
    c.dispose();
  });

  test(
    'à la reprise, les avatars sauvegardés sont relus à l\'identique',
    () async {
      final store = _MemoryStore();
      final first = _make(store);
      await first.restore();
      first.setAvatarIds(const ['horse', 'dolphin', 'camel', 'penguin']);
      first.dispose();

      final again = _make(store);
      await again.restore();
      expect(again.awaitingResume, isTrue);
      expect(again.savedAvatarIds, ['horse', 'dolphin', 'camel', 'penguin']);

      again.resume();
      expect(again.avatarIds, ['horse', 'dolphin', 'camel', 'penguin']);
      again.dispose();
    },
  );

  test(
    'une ancienne sauvegarde sans avatars ne donne aucun avatar repris',
    () async {
      final store = _MemoryStore();
      final c = _make(null);
      await c.restore();
      final json = c.snapshot()!..remove('avatars');
      store.data['coinche'] = json;
      c.dispose();

      final again = _make(store);
      await again.restore();
      expect(again.savedAvatarIds, isNull);
      again.dispose();
    },
  );
}
