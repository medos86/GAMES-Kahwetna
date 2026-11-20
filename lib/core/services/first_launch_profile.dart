import 'dart:math';

import '../avatars/avatar_catalog.dart';
import 'profile_store.dart';

/// Résultat de [ensureProfile] : le profil actif et s'il faut le créer (issue #544).
typedef ProfileSetup = ({PlayerProfile profile, bool created});

/// Premier lancement (issue #631) : aucun profil n'est enregistré.
/// Renvoie un brouillon (avatar tiré au hasard, pseudo vide) que l'écran de
/// bienvenue complète avant de l'enregistrer. Aux lancements suivants, le profil
/// sauvegardé est simplement relu.
Future<ProfileSetup> ensureProfile({Random? random}) async {
  if (await hasSavedProfile()) {
    return (profile: await loadProfile(), created: false);
  }
  final rnd = random ?? Random();
  final draft = PlayerProfile(
    name: '',
    avatarId: avatarCatalog[rnd.nextInt(avatarCatalog.length)].id,
  );
  return (profile: draft, created: true);
}
