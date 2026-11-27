part of '../coinche_screen.dart';

/// Coin d'équipe : seulement le score de l'équipe (#1032). Les avatars sont sur chaque siège.
class _TeamCorner extends StatelessWidget {
  const _TeamCorner({
    required this.controller,
    required this.team,
  });

  final CoincheController controller;
  final Team team;

  @override
  Widget build(BuildContext context) {
    final color = _teamTone(team);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color, width: 2),
      ),
      child: Text(
        '${_teamLabel[team]} ${controller.match.scores[team]}',
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w900,
          fontSize: 12,
        ),
      ),
    );
  }
}

/// Médaillon d'un coin, agrandi quand c'est le tour de son siège (#1004).
class _CornerAvatar extends StatelessWidget {
  const _CornerAvatar({
    required this.seat,
    required this.round,
    required this.avatarId,
    required this.name,
  });

  final Seat seat;
  final RoundState round;
  final String avatarId;
  final String name;

  @override
  Widget build(BuildContext context) {
    final active = round.turn == seat &&
        (round.phase == CoinchePhase.bidding ||
            round.phase == CoinchePhase.playing);
    return TurnAvatar(
      tone: coincheSeatRingColor(seat),
      active: active,
      avatarId: avatarId,
      state: gameAvatarState(
        seat: seat.index,
        finished: round.phase == CoinchePhase.done,
        winners: coincheWinnerSeats(round),
      ),
      semanticLabel: name,
      baseSize: coincheAvatarSize(active: false),
      activeSize: coincheAvatarSize(active: true),
    );
  }
}

/// Couleur d'une équipe : vert pour le Nous, rouge pour les Eux.
Color _teamTone(Team team) =>
    team == Team.ns ? const Color(0xFF047857) : const Color(0xFFB91C1C);

/// Coin de l'annonce : atout et contrat, puis avatar de l'annonceur (#1005).
class _ContractCorner extends StatelessWidget {
  const _ContractCorner({
    required this.controller,
    required this.avatarIds,
    required this.seatNames,
    required this.me,
  });

  final CoincheController controller;
  final List<String> avatarIds;
  final Map<Seat, String> seatNames;
  final String me;

  @override
  Widget build(BuildContext context) {
    final round = controller.round;
    final contract = round.contract;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(
            color: contract == null ? Colors.white : _goldColor,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: _frameColor, width: 2),
          ),
          child: Text(
            coincheCornerTitle(contract),
            style: const TextStyle(
              color: _inkColor,
              fontWeight: FontWeight.w900,
              fontSize: 14,
            ),
          ),
        ),
        if (contract != null) ...[
          const SizedBox(height: 2),
          _CornerAvatar(
            seat: contract.seat,
            round: round,
            avatarId: avatarIds[contract.seat.index],
            name: coincheSeatName(seatNames, contract.seat, me),
          ),
        ],
      ],
    );
  }
}
