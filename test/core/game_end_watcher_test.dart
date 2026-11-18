import 'package:flutter_test/flutter_test.dart';
import 'package:kahwetne/core/services/game_end_watcher.dart';

void main() {
  test('ne signale jamais pendant la partie', () {
    var ended = false;
    var calls = 0;
    final w = GameEndWatcher(isEnded: () => ended, onEnded: () => calls++);
    w.check();
    w.check();
    expect(calls, 0);
  });

  test('signale une seule fois à la fin de la partie', () {
    var ended = false;
    var calls = 0;
    final w = GameEndWatcher(isEnded: () => ended, onEnded: () => calls++);
    ended = true;
    w.check();
    w.check();
    w.check();
    expect(calls, 1);
  });

  test('se réarme après une nouvelle partie', () {
    var ended = false;
    var calls = 0;
    final w = GameEndWatcher(isEnded: () => ended, onEnded: () => calls++);
    ended = true;
    w.check();
    ended = false;
    w.check();
    ended = true;
    w.check();
    expect(calls, 2);
  });
}
