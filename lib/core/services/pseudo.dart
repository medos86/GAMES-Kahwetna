import 'dart:math';

/// Raison de rejet d'un pseudo (issue #543).
enum PseudoError { tooShort, tooLong, invalidCharacters, forbiddenWord }

const int pseudoMinLength = 3;
const int pseudoMaxLength = 14;

const List<String> _adjectives = [
  'Sfaxi',
  'Tunisi',
  'Malin',
  'Brave',
  'Rapide',
  'Joyeux',
  'Vif',
  'Fort',
];

const List<String> _nouns = [
  'Lion',
  'Tigre',
  'Faucon',
  'Lynx',
  'Pirate',
  'Dragon',
  'Chef',
  'Ninja',
];

/// Lettres latines (accents inclus), chiffres, `_`, espaces et lettres arabes.
final RegExp _allowedChars = RegExp(r'^[A-Za-z0-9_ À-ÿ؀-ۿ]+$');

/// Liste de mots interdits, à compléter. Comparée en minuscules, sans espaces ni `_`.
const List<String> _forbiddenWords = ['admin', 'root'];

/// Génère un pseudo « Adjectif_Nom », toujours valide (14 caractères au plus).
String generatePseudo(Random random) {
  final adjective = _adjectives[random.nextInt(_adjectives.length)];
  final noun = _nouns[random.nextInt(_nouns.length)];
  return '${adjective}_$noun';
}

/// Vérifie un pseudo saisi. Retourne null s'il est valide, sinon la raison du rejet.
PseudoError? validatePseudo(String raw) {
  final name = raw.trim();
  if (name.length < pseudoMinLength) return PseudoError.tooShort;
  if (name.length > pseudoMaxLength) return PseudoError.tooLong;
  if (!_allowedChars.hasMatch(name)) return PseudoError.invalidCharacters;
  final compact = name.toLowerCase().replaceAll(RegExp(r'[ _]'), '');
  if (_forbiddenWords.any(compact.contains)) return PseudoError.forbiddenWord;
  return null;
}
