import 'dart:math';

import '../avatars/avatar_catalog.dart';
import 'profile_store.dart';
import 'pseudo.dart';

/// Résultat de [ensureProfile] : le profil actif et s'il vient d'être créé (issue #544).
typedef ProfileSetup = ({PlayerProfile profile, bool created});

/// Premier lancement : tire un pseudo et un avatar au hasard, puis les sauvegarde.
/// Aux lancements suivants, le profil sauvegardé est simplement relu.
Future<ProfileSetup> ensureProfile({Random? random}) async {
  if (await hasSavedProfile()) {
    return (profile: await loadProfile(), created: false);
  }
  final rnd = random ?? Random();
  final profile = PlayerProfile(
    name: generatePseudo(rnd),
    avatarId: avatarCatalog[rnd.nextInt(avatarCatalog.length)].id,
  );
  await saveProfile(profile);
  return (profile: profile, created: true);
}
