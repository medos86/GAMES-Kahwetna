import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:kahwetne/core/avatars/avatar_catalog.dart';
import 'package:kahwetne/core/services/first_launch_profile.dart';
import 'package:kahwetne/core/services/profile_store.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Issues #544 et #631 : au premier lancement, un brouillon sans pseudo est proposé
/// (le joueur le saisit à l'écran de bienvenue) ; ensuite le profil sauvegardé est relu.
void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test(
    'premier lancement : brouillon sans pseudo, avatar tiré, rien sauvé',
    () async {
      final setup = await ensureProfile(random: Random(1));
      expect(setup.created, isTrue);
      expect(setup.profile.name, isEmpty);
      expect(avatarCatalog.map((a) => a.id), contains(setup.profile.avatarId));
      expect(await hasSavedProfile(), isFalse);
    },
  );

  test('après enregistrement du pseudo, le profil est conservé', () async {
    final first = await ensureProfile(random: Random(1));
    await saveProfile(
      PlayerProfile(name: 'Tigre_Brave', avatarId: first.profile.avatarId),
    );
    final second = await ensureProfile(random: Random(999));
    expect(second.created, isFalse);
    expect(second.profile.name, 'Tigre_Brave');
    expect(second.profile.avatarId, first.profile.avatarId);
  });
}
