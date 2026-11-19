import 'package:material_ui/material_ui.dart';

/// Ordre de distribution : une carte à gauche, en haut, à droite, puis à moi en bas (#532, #589).
/// Les indices sont ceux des sièges (0 = moi, 1 = Ali à gauche, 2 = Karim en haut, 3 = Sami à droite).
const ramiDealSeatOrder = [1, 2, 3, 0];

/// Côté du tapis où s'affiche le badge d'un adversaire (#589).
/// Sens horaire depuis moi (en bas) : le joueur suivant est à ma gauche.
Alignment ramiSeatAlignment(int seat) {
  switch (seat) {
    case 1:
      return Alignment.centerLeft;
    case 2:
      return Alignment.topCenter;
    case 3:
      return Alignment.centerRight;
    default:
      throw ArgumentError.value(
        seat,
        'seat',
        'siège adverse attendu (1 à 3)',
      );
  }
}

/// Badge d'un adversaire posé sur le bord du tapis : nom et nombre de cartes (#532).
/// Passif et superposé, il ne prend aucune place dans la mise en page.
class RamiSeatBadge extends StatelessWidget {
  const RamiSeatBadge({
    super.key,
    required this.name,
    required this.cards,
  });

  final String name;
  final int cards;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF8E7),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFF4A2A10), width: 2),
      ),
      child: Text(
        '$name ×$cards',
        style: const TextStyle(
          color: Color(0xFF20284B),
          fontSize: 11,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}
