import 'package:shared_preferences/shared_preferences.dart';

import '../avatars/avatar_catalog.dart';

/// Profil local du joueur (issue #542) : pseudo et avatar, gardés sur l'appareil.
class PlayerProfile {
  const PlayerProfile({required this.name, required this.avatarId});

  final String name;
  final String avatarId;

  /// Avatar correspondant à [avatarId], avec repli si l'identifiant est inconnu.
  Avatar get avatar => avatarById(avatarId);
}

const profileNamePrefsKey = 'kahwetne.profile.name';
const profileAvatarPrefsKey = 'kahwetne.profile.avatarId';

/// Profil utilisé tant qu'aucun profil n'est sauvegardé.
const PlayerProfile defaultProfile = PlayerProfile(
  name: '',
  avatarId: 'cat',
);

/// Vrai si un profil a déjà été sauvegardé sur cet appareil.
Future<bool> hasSavedProfile() async {
  try {
    final prefs = await SharedPreferences.getInstance();
    return prefs.containsKey(profileAvatarPrefsKey);
  } catch (_) {
    return false;
  }
}

/// Relit le profil sauvegardé. Sans préférence lisible, retourne [defaultProfile].
Future<PlayerProfile> loadProfile() async {
  try {
    final prefs = await SharedPreferences.getInstance();
    final name = prefs.getString(profileNamePrefsKey);
    final avatarId = prefs.getString(profileAvatarPrefsKey);
    return PlayerProfile(
      name: name ?? defaultProfile.name,
      avatarId: avatarId ?? defaultProfile.avatarId,
    );
  } catch (_) {
    return defaultProfile;
  }
}

/// Sauvegarde le profil. En cas d'échec, le profil reste valable pour la session.
Future<void> saveProfile(PlayerProfile profile) async {
  try {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(profileNamePrefsKey, profile.name);
    await prefs.setString(profileAvatarPrefsKey, profile.avatarId);
  } catch (_) {
    // Préférence non sauvegardée : le profil vaut pour la session en cours.
  }
}
