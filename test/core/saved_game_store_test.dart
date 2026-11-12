import 'package:flutter_test/flutter_test.dart';
import 'package:kahwetne/core/services/saved_game_store.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Sauvegarde des parties (#112) : une clé par jeu, effacement ciblé.
void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('sauvegarde puis relecture à l\'identique', () async {
    const store = SharedPreferencesSavedGameStore();
    await store.save('chkobba', {
      'a': 1,
      'b': [1, 2],
    });
    expect(await store.load('chkobba'), {
      'a': 1,
      'b': [1, 2],
    });
  });

  test('rien sauvegardé : null', () async {
    const store = SharedPreferencesSavedGameStore();
    expect(await store.load('domino'), isNull);
  });

  test('effacer un jeu ne touche pas les autres', () async {
    const store = SharedPreferencesSavedGameStore();
    await store.save('chkobba', {'x': 1});
    await store.save('ludo', {'y': 2});
    await store.clear('chkobba');
    expect(await store.load('chkobba'), isNull);
    expect(await store.load('ludo'), {'y': 2});
  });

  test('une sauvegarde abîmée est ignorée et supprimée', () async {
    SharedPreferences.setMockInitialValues({
      SharedPreferencesSavedGameStore.keyFor('rami'): '{pas du json',
    });
    const store = SharedPreferencesSavedGameStore();
    expect(await store.load('rami'), isNull);
    expect(await store.load('rami'), isNull);
  });
}
