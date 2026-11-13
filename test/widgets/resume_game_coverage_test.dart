import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kahwetne/core/services/persistent_game_controller.dart';
import 'package:kahwetne/core/services/saved_game_store.dart';
import 'package:kahwetne/core/strings.dart';
import 'package:kahwetne/widgets/resume_game.dart';

class _Store implements SavedGameStore {
  _Store(this.data);

  final Map<String, Map<String, dynamic>> data;

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

class _Game extends PersistentGameController {
  _Game(SavedGameStore store) : super(store: store, gameKey: 'test');

  int value = 0;

  @override
  Map<String, dynamic>? snapshot() => {'value': value};

  @override
  void applySnapshot(Map<String, dynamic> json) {
    value = json['value'] as int;
  }

  @override
  void startFresh() {}

  @override
  void newGame() {
    value = 0;
  }
}

class _Opener extends StatelessWidget {
  const _Opener(this.game);

  final PersistentGameController game;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: TextButton(
          onPressed: () => offerResume(context, game),
          child: const Text('ouvrir'),
        ),
      ),
    );
  }
}

Future<void> _openDialog(WidgetTester tester, _Game game) async {
  await tester.pumpWidget(MaterialApp(home: _Opener(game)));
  await tester.tap(find.text('ouvrir'));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('Reprendre applique la partie sauvegardée', (tester) async {
    final game = _Game(_Store({'test': {'value': 4}}));
    await game.restore();

    await _openDialog(tester, game);
    await tester.tap(find.text(Strings.resumeContinue));
    await tester.pumpAndSettle();

    expect(game.value, 4);
    expect(game.awaitingResume, isFalse);
  });
}
