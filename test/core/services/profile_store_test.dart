import 'package:flutter_test/flutter_test.dart';
import 'package:kahwetne/core/avatars/avatar_catalog.dart';
import 'package:kahwetne/core/services/profile_store.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Issue #542 : stockage du profil (pseudo + avatar) dans SharedPreferences.
void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('sans profil sauvegardé, retourne le profil par défaut', () async {
    expect(await hasSavedProfile(), isFalse);
    final profile = await loadProfile();
    expect(profile.name, defaultProfile.name);
    expect(profile.avatarId, defaultProfile.avatarId);
  });

  test('sauvegarde puis relecture du pseudo et de l\'avatar', () async {
    await saveProfile(const PlayerProfile(name: 'Sfax_Lion', avatarId: 'lion'));
    expect(await hasSavedProfile(), isTrue);
    final profile = await loadProfile();
    expect(profile.name, 'Sfax_Lion');
    expect(profile.avatarId, 'lion');
  });

  test('un identifiant d\'avatar inconnu donne le repli à l\'affichage', () {
    const profile = PlayerProfile(name: 'Test', avatarId: 'inconnu');
    expect(profile.avatar, defaultAvatar);
  });

  test('une erreur de préférences ne plante pas le chargement', () async {
    SharedPreferences.setMockInitialValues({
      profileAvatarPrefsKey: 42,
    });
    final profile = await loadProfile();
    expect(profile.avatarId, defaultProfile.avatarId);
  });
}
