/// États visuels d'un avatar (issue #541).
enum AvatarState { neutral, happy, angry }

/// Un personnage : un identifiant stable et une image par état.
class Avatar {
  const Avatar(this.id);

  final String id;

  /// Chemin de l'image de ce personnage pour un état donné.
  String assetFor(AvatarState state) =>
      'assets/images/avatars/${state.name}/$id.webp';
}

/// Les 16 personnages, dans l'ordre de la grille de choix.
const List<Avatar> avatarCatalog = [
  Avatar('boy_tn'),
  Avatar('girl_scarf'),
  Avatar('young_man'),
  Avatar('girl_hat'),
  Avatar('boy_glasses'),
  Avatar('redhead'),
  Avatar('man_keffiyeh'),
  Avatar('woman_hijab'),
  Avatar('lion'),
  Avatar('horse'),
  Avatar('camel'),
  Avatar('dolphin'),
  Avatar('panda'),
  Avatar('penguin'),
  Avatar('tiger'),
  Avatar('cat'),
];

/// Repli quand l'identifiant demandé est absent ou inconnu (ex. ancienne sauvegarde).
const Avatar defaultAvatar = Avatar('cat');

/// Retourne l'avatar d'identifiant [id], ou [defaultAvatar] si inconnu.
Avatar avatarById(String? id) {
  for (final avatar in avatarCatalog) {
    if (avatar.id == id) return avatar;
  }
  return defaultAvatar;
}
