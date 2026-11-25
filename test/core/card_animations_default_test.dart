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

  test('valeur par défaut du notifier : activé', () {
    expect(cardAnimations.value, isTrue);
  });

  test('sans préférence sauvegardée, loadCardAnimations active le réglage', () async {
    cardAnimations.value = false;
    await loadCardAnimations();
    expect(cardAnimations.value, isTrue);
  });

  test('un choix utilisateur désactivé est respecté', () async {
    SharedPreferences.setMockInitialValues({cardAnimationsPrefsKey: false});
    await loadCardAnimations();
    expect(cardAnimations.value, isFalse);
  });
}
