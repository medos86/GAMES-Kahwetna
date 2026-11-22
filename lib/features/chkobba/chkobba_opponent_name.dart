import 'dart:math' as math;

/// Prénoms possibles pour l'adversaire de la Chkobba (#766) : tirés au hasard à chaque partie.
const List<String> chkobbaOpponentNames = [
  'Karim',
  'Sami',
  'Ahmed',
  'Leila',
  'Youssef',
  'Nour',
  'Mehdi',
  'Amira',
  'Hedi',
  'Salma',
  'Rami',
  'Ines',
];

/// Tire au hasard le nom affiché pour l'adversaire.
String pickOpponentName(math.Random random) {
  return chkobbaOpponentNames[random.nextInt(chkobbaOpponentNames.length)];
}
