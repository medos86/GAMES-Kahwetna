import 'package:flutter/material.dart';

import '../../game/rami.dart' as rules;
import '../../core/strings.dart';

/// Libellé d'une valeur : As, Valet, Dame, Roi, ou le chiffre.
String ramiRankLabel(int rank) => switch (rank) {
      1 => 'A',
      11 => 'V',
      12 => 'D',
      13 => 'R',
      _ => '$rank',
    };

/// Symbole de chaque couleur (valeurs de Card.tsx).
String ramiSuitSymbol(rules.RamiSuit suit) => switch (suit) {
      rules.RamiSuit.deniers => '♦',
      rules.RamiSuit.coupes => '♥',
      rules.RamiSuit.epees => '♠',
      rules.RamiSuit.batons => '♣',
    };

/// Couleur de chaque couleur (valeurs de Card.tsx).
Color ramiSuitColor(rules.RamiSuit suit) => switch (suit) {
      rules.RamiSuit.deniers => const Color(0xFFCA8A04),
      rules.RamiSuit.coupes => const Color(0xFFDC2626),
      rules.RamiSuit.epees => const Color(0xFF1F2937),
      rules.RamiSuit.batons => const Color(0xFF92400E),
    };

/// Carte Rami dessinée en texte. Seul le coin haut-gauche (valeur et couleur) est visible,
/// comme TopCard du source : les cartes qui se chevauchent restent lisibles.
class RamiCardView extends StatelessWidget {
  const RamiCardView({super.key, required this.card, required this.width, this.selected = false});

  final rules.RamiCard card;
  final double width;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final height = width * 1.4;
    final fontSize = height * 0.25;
    final joker = card.isJoker;
    final rules.RamiSuit? suit = card.suit;
    final semanticsLabel = joker ? Strings.jokerLabel : '${ramiRankLabel(card.rank)} ${ramiSuitSymbol(suit!)}';

    return Semantics(
      label: semanticsLabel,
      image: true,
      child: Transform.translate(
        offset: Offset(0, selected ? -width * 0.25 : 0),
        child: Container(
          width: width,
          height: height,
          padding: EdgeInsets.fromLTRB(width * 0.06, 1, 0, 0),
          decoration: BoxDecoration(
            color: joker ? null : const Color(0xFFFFFBEB),
            gradient: joker
                ? const LinearGradient(
                    colors: [Color(0xFFC026D3), Color(0xFF7E22CE), Color(0xFF312E81)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  )
                : null,
            borderRadius: BorderRadius.circular(width * 0.14),
            border: Border.all(
              color: selected ? const Color(0xFFFFE16B) : Colors.black,
              width: selected ? 3 : 2,
            ),
            boxShadow: const [BoxShadow(color: Colors.black, offset: Offset(0, 2))],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: joker
                ? <Widget>[
                    Text(
                      '★',
                      style: TextStyle(color: const Color(0xFFFFE16B), fontSize: fontSize, height: 1.05),
                    ),
                    Text(
                      'J',
                      style: TextStyle(
                        color: const Color(0xFFFFE16B),
                        fontSize: fontSize,
                        fontWeight: FontWeight.w900,
                        height: 1.05,
                      ),
                    ),
                  ]
                : <Widget>[
                    Text(
                      ramiRankLabel(card.rank),
                      style: TextStyle(
                        color: ramiSuitColor(suit!),
                        fontSize: fontSize,
                        fontWeight: FontWeight.w900,
                        height: 1.05,
                      ),
                    ),
                    Text(
                      ramiSuitSymbol(suit),
                      style: TextStyle(color: ramiSuitColor(suit), fontSize: fontSize, height: 1.05),
                    ),
                  ],
          ),
        ),
      ),
    );
  }
}

/// Dos d'une carte, pour la pioche.
class RamiBackView extends StatelessWidget {
  const RamiBackView({super.key, required this.width});

  final double width;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: width * 1.4,
      decoration: BoxDecoration(
        color: const Color(0xFF991B1B),
        borderRadius: BorderRadius.circular(width * 0.14),
        border: Border.all(color: Colors.black, width: 2),
        boxShadow: const [BoxShadow(color: Colors.black, offset: Offset(3, 3))],
      ),
      child: Center(
        child: Container(
          width: width * 0.6,
          height: width * 0.9,
          decoration: BoxDecoration(
            border: Border.all(color: const Color(0xFFFFE16B), width: 1.5),
            borderRadius: BorderRadius.circular(width * 0.1),
          ),
        ),
      ),
    );
  }
}
