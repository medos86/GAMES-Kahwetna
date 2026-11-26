import 'package:material_ui/material_ui.dart';

import '../../game/coinche.dart';
import 'coinche_card_view.dart';

/// Tapis rouge en dégradé radial, même style que le Chkobba (#1001).
RadialGradient coincheFeltGradient() => const RadialGradient(
      colors: [Color(0xFFEF4444), Color(0xFFB91C1C), Color(0xFF7F1D1D)],
    );

/// La barre du score en haut est retirée : les scores vivent dans les coins (#1002).
const bool coincheShowTopScoreBar = false;

/// Marge autour du tapis, resserrée pour agrandir la surface de jeu (#1003).
const EdgeInsets coincheTablePadding = EdgeInsets.fromLTRB(6, 6, 6, 0);

/// Les deux sièges d'une équipe, dans l'ordre des sièges (#1004).
List<Seat> coincheTeamSeats(Team team) => [
      for (final seat in Seat.values)
        if (teamOf(seat) == team) seat,
    ];

/// Titre du coin d'annonce : « Enchères » tant qu'aucun contrat n'est posé (#1005).
String coincheCornerTitle(Contract? contract) => contract == null
    ? 'Enchères'
    : '${contract.value} ${coincheSuitSymbol(contract.mode)}';

/// Taille des avatars des coins : un peu plus grands qu'avant, le joueur actif encore plus (#1006).
double coincheAvatarSize({required bool active}) => active ? 44 : 32;

/// Couleur d'anneau de chaque joueur : rouge, vert, bleu, jaune (#1007).
Color coincheSeatRingColor(Seat seat) => switch (seat) {
      Seat.south => const Color(0xFFDC2626),
      Seat.west => const Color(0xFF16A34A),
      Seat.north => const Color(0xFF2563EB),
      Seat.east => const Color(0xFFEAB308),
    };

/// Agrandissement des cartes de la main du joueur, par rapport à la largeur de base (#1008).
const double coincheHandScale = 1.4;
