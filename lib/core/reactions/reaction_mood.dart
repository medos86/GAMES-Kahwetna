/// Humeurs des stickers de réaction BD (#759).
///
/// Chaque humeur correspond à un sticker PNG transparent (#758).
enum ReactionMood { angry, laugh, cry, surprise, kiss, disgust, thinking, shock, shush }

/// Nom de fichier (sans extension) du sticker de chaque humeur.
extension ReactionMoodAsset on ReactionMood {
  String get assetName => switch (this) {
        ReactionMood.angry => 'grrr',
        ReactionMood.laugh => 'hahaha',
        ReactionMood.cry => 'boouhou',
        ReactionMood.surprise => 'oh_wow',
        ReactionMood.kiss => 'kiss',
        ReactionMood.disgust => 'beerk',
        ReactionMood.thinking => 'eum_hm',
        ReactionMood.shock => 'aaah_eek',
        ReactionMood.shush => 'chut_shh',
      };

  /// Chemin de l'image du sticker, déclarée dans le pubspec.
  String get assetPath => 'assets/images/reactions/$assetName.png';
}
