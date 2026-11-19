import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:kahwetne/core/avatars/avatar_catalog.dart';
import 'package:kahwetne/core/services/first_launch_profile.dart';
import 'package:kahwetne/core/services/profile_store.dart';
import 'package:kahwetne/core/services/pseudo.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Issue #544 : attribution du profil au premier lancement uniquement.
void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('premier lancement : pseudo valide et avatar créés', () async {
    final setup = await ensureProfile(random: Random(1));
    expect(setup.created, isTrue);
    expect(validatePseudo(setup.profile.name), isNull);
    expect(avatarCatalog.map((a) => a.id), contains(setup.profile.avatarId));
    expect(await hasSavedProfile(), isTrue);
  });

  test('au lancement suivant, le profil existant est conservé', () async {
    final first = await ensureProfile(random: Random(1));
    final second = await ensureProfile(random: Random(999));
    expect(second.created, isFalse);
    expect(second.profile.name, first.profile.name);
    expect(second.profile.avatarId, first.profile.avatarId);
  });
}
