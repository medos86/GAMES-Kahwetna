import 'package:flutter_test/flutter_test.dart';
import 'package:kahwetne/core/services/reaction_stickers.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  tearDown(() {
    reactionStickers.value = true;
  });

  test('réactions BD activées par défaut', () {
    expect(reactionStickers.value, isTrue);
  });

  test('setReactionStickers change la valeur', () async {
    SharedPreferences.setMockInitialValues({});
    await setReactionStickers(false);
    expect(reactionStickers.value, isFalse);
  });

  test('loadReactionStickers relit la préférence sauvegardée', () async {
    SharedPreferences.setMockInitialValues({reactionStickersPrefsKey: false});
    await loadReactionStickers();
    expect(reactionStickers.value, isFalse);
  });

  test('sans préférence sauvegardée, le réglage reste activé', () async {
    SharedPreferences.setMockInitialValues({});
    reactionStickers.value = false;
    await loadReactionStickers();
    expect(reactionStickers.value, isTrue);
  });
}
