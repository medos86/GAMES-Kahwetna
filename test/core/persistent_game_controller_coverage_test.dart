import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kahwetne/core/services/persistent_game_controller.dart';
import 'package:kahwetne/core/services/saved_game_store.dart';
import 'package:kahwetne/widgets/resume_game.dart';

class MemoryStore implements SavedGameStore {
  final Map<String, Map<String, dynamic>> data = {};

  @override
  Future<Map<String, dynamic>?> load(String game) async => data[game];

  @override
  Future<void> save(String game, Map<String, dynamic> json) async {
    data[game] = json;
  }

  @override
  Future<void> clear(String game) async {
    data.remove(game);
  }
}

class CounterGame extends PersistentGameController {
  CounterGame({super.store}) : super(gameKey: 'test');

  int value = 0;
  int freshStarts = 0;
  int newGames = 0;
  bool finished = false;

  @override
  Map<String, dynamic>? snapshot() => finished ? null : {'value': value};

  @override
  void applySnapshot(Map<String, dynamic> json) {
    value = json['value'] as int;
  }

  @override
  void startFresh() {
    freshStarts++;
  }

  @override
  void newGame() {
    newGames++;
    value = 0;
  }
}

void main() {
  test('sans store : aucune sauvegarde, rien à reprendre', () async {
    final game = CounterGame();
    await game.restore();
    expect(game.awaitingResume, isFalse);
    expect(game.freshStarts, 0);
  });

  test('notification : la partie est sauvegardée', () async {
    final store = MemoryStore();
    final game = CounterGame(store: store);
    await game.restore();
    game.value = 3;
    game.notifyListeners();
    expect(store.data['test'], {'value': 3});
  });

  test('partie terminée : la sauvegarde est effacée', () async {
    final store = MemoryStore()..data['test'] = {'value': 5};
    final game = CounterGame(store: store);
    await game.restore();
    game.resume();
    game.finished = true;
    game.notifyListeners();
    expect(store.data.containsKey('test'), isFalse);
  });

  test('Reprendre remet l\'état sauvegardé en place', () async {
    final store = MemoryStore()..data['test'] = {'value': 7};
    final game = CounterGame(store: store);
    await game.restore();
    expect(game.awaitingResume, isTrue);
    game.resume();
    expect(game.value, 7);
    expect(game.awaitingResume, isFalse);
  });

  test('Nouvelle partie efface la sauvegarde et repart à zéro', () async {
    final store = MemoryStore()..data['test'] = {'value': 9};
    final game = CounterGame(store: store);
    await game.restore();
    await game.discardSaved();
    expect(store.data.containsKey('test'), isFalse);
    expect(game.awaitingResume, isFalse);
    expect(game.newGames, 1);
    expect(game.value, 0);
  });

  testWidgets('reprise confirmée par le menu : pas de dialogue', (tester) async {
    final store = MemoryStore()..data['test'] = {'value': 6};
    final game = CounterGame(store: store);
    await game.restore();
    markResumeConfirmed('test');
    late BuildContext context;
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (ctx) {
            context = ctx;
            return const SizedBox();
          },
        ),
      ),
    );
    await offerResume(context, game);
    expect(game.value, 6);
    expect(game.awaitingResume, isFalse);
  });
}
