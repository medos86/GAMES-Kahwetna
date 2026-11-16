import 'package:flutter_test/flutter_test.dart';
import 'package:kahwetne/core/services/saved_game_store.dart';
import 'package:kahwetne/features/ludo/ludo_controller.dart';
import 'package:kahwetne/game/ludo.dart';

class _Store implements SavedGameStore {
  _Store(this.saved);

  Map<String, dynamic>? saved;

  @override
  Future<Map<String, dynamic>?> load(String game) async => saved;

  @override
  Future<void> save(String game, Map<String, dynamic> json) async {
    saved = json;
  }

  @override
  Future<void> clear(String game) async {
    saved = null;
  }
}

/// Reprise d'une partie : les pions sont placés d'emblée, sans trajet depuis la base.
void main() {
  test('Reprendre change la révision de saut des pions', () async {
    final seed = LudoController(
      playerCount: 2,
      difficulty: LudoAiLevel.facile,
      store: _Store(null),
    );
    await seed.restore();
    final json = seed.snapshot();
    seed.dispose();
    expect(json, isNotNull);

    final c = LudoController(
      playerCount: 2,
      difficulty: LudoAiLevel.facile,
      store: _Store(json),
    );
    await c.restore();
    final before = c.jumpRevision;
    c.resume();
    expect(c.jumpRevision, before + 1);
    c.dispose();
  });
}
