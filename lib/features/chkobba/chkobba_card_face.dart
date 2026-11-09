import 'package:flutter/material.dart';

import '../../game/chkobba.dart';

/// Symbole de chaque couleur (même correspondance que suitSymbols du source).
String chkobbaSuitSymbol(ChkobbaSuit suit) => switch (suit) {
      ChkobbaSuit.deniers => '♦',
      ChkobbaSuit.coupes => '♥',
      ChkobbaSuit.epees => '♠',
      ChkobbaSuit.batons => '♣',
    };

/// Couleur de chaque couleur (suitColors du source : yellow-600, red-600, gray-800, amber-800).
Color chkobbaSuitColor(ChkobbaSuit suit) => switch (suit) {
      ChkobbaSuit.deniers => const Color(0xFFCA8A04),
      ChkobbaSuit.coupes => const Color(0xFFDC2626),
      ChkobbaSuit.epees => const Color(0xFF1F2937),
      ChkobbaSuit.batons => const Color(0xFF92400E),
    };

/// Libellé de valeur : 1 = A, 8 = V (valet), 9 = C (cavalier), 10 = R (roi).
String chkobbaRankLabel(int rank) => switch (rank) {
      1 => 'A',
      8 => 'V',
      9 => 'C',
      10 => 'R',
      _ => '$rank',
    };

/// Face d'une carte, comme Card.tsx : valeur et couleur en haut à gauche, grand symbole au centre,
/// et le même coin retourné en bas à droite. Les tailles suivent la hauteur de la carte.
class ChkobbaCardFace extends StatelessWidget {
  const ChkobbaCardFace({super.key, required this.card, this.onTap, this.highlight = false});

  final ChkobbaCard card;
  final VoidCallback? onTap;

  /// Anneau jaune (carte choisie).
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    final ink = chkobbaSuitColor(card.suit);
    final symbol = chkobbaSuitSymbol(card.suit);
    final label = chkobbaRankLabel(card.rank);

    final face = Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFFFFBEB), Colors.white],
        ),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: highlight ? const Color(0xFFFACC15) : Colors.black,
          width: highlight ? 3 : 2,
        ),
        boxShadow: const [BoxShadow(color: Colors.black, offset: Offset(0, 3))],
      ),
      child: LayoutBuilder(
        builder: (context, c) {
          final h = c.maxHeight;
          final corner = Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(fontSize: h * 0.2, height: 1, fontWeight: FontWeight.w900, color: ink),
              ),
              Text(symbol, style: TextStyle(fontSize: h * 0.25, height: 1, color: ink)),
            ],
          );
          return Padding(
            padding: EdgeInsets.all(h * 0.045),
            child: Stack(
              children: [
                Align(alignment: Alignment.topLeft, child: corner),
                Center(
                  child: Text(symbol, style: TextStyle(fontSize: h * 0.5, height: 1, color: ink)),
                ),
                // Coin retourné en bas à droite.
                Align(alignment: Alignment.bottomRight, child: RotatedBox(quarterTurns: 2, child: corner)),
              ],
            ),
          );
        },
      ),
    );

    if (onTap == null) return face;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: face,
    );
  }
}

/// Dos d'une carte (main de l'adversaire), même motif que le source : rouge rayé, cadre doré.
class ChkobbaCardBack extends StatelessWidget {
  const ChkobbaCardBack({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFB91C1C), Color(0xFF7F1D1D)],
        ),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.black, width: 2),
        boxShadow: const [BoxShadow(color: Colors.black, offset: Offset(0, 3))],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(6),
        child: CustomPaint(
          painter: _StripesPainter(),
          child: Center(
            child: FractionallySizedBox(
              widthFactor: 0.68,
              heightFactor: 0.72,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  border: Border.all(color: const Color(0xCCCA8A04), width: 3),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _StripesPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0x4D8B0000)
      ..strokeWidth = 10;
    final h = size.height;
    for (double x = -h; x < size.width; x += 20) {
      canvas.drawLine(Offset(x, 0), Offset(x + h, h), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
