import 'package:material_ui/material_ui.dart';

import '../../game/coinche.dart';

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
