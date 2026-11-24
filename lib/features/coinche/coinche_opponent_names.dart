import 'dart:math' as math;

import '../../game/coinche.dart';

/// Prénoms possibles pour les adversaires de la Belote (issue #770) : tirés au hasard à chaque partie.
const List<String> coincheOpponentNames = [
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

/// Tire trois prénoms distincts : partenaire (nord), adversaire de gauche (ouest), de droite (est).
Map<Seat, String> pickCoincheOpponentNames(math.Random random) {
  final pool = List<String>.of(coincheOpponentNames)..shuffle(random);
  return {
    Seat.north: pool[0],
    Seat.west: pool[1],
    Seat.east: pool[2],
  };
}

/// Nom affiché pour un siège : le pseudo du joueur (« Toi » par défaut) pour le sud, sinon le prénom tiré.
String coincheSeatName(Map<Seat, String> names, Seat seat, [String me = 'Toi']) {
  if (seat == Seat.south) return me;
  return names[seat]!;
}

/// Quart de tour du badge (#770) : sièges latéraux écrits verticalement, comme au Rami.
int coincheSeatQuarterTurns(Seat seat) {
  if (seat == Seat.west) return 3;
  if (seat == Seat.east) return 1;
  return 0;
}
