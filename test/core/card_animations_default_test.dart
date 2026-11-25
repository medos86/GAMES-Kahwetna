import 'package:flutter_test/flutter_test.dart';
import 'package:kahwetne/core/services/card_animations.dart';
import 'package:shared_preferences/shared_preferences.dart';

// #900 : les animations de cartes sont activées par défaut.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    cardAnimations.value = true;
  });

  test('défaut : activé', () {
    expect(cardAnimations.value, isTrue);
  });

  test('sans préférence : activé', () async {
    cardAnimations.value = false;
    await loadCardAnimations();
    expect(cardAnimations.value, isTrue);
  });

  test('choix utilisateur désactivé respecté', () async {
    SharedPreferences.setMockInitialValues({cardAnimationsPrefsKey: false});
    await loadCardAnimations();
    expect(cardAnimations.value, isFalse);
  });
}
