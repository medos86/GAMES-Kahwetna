part of '../coinche_screen.dart';

/// Coin d'équipe : les deux avatars de l'équipe, face à face, et son score (#1004).
class _TeamCorner extends StatelessWidget {
  const _TeamCorner({
    required this.controller,
    required this.team,
    required this.avatarIds,
    required this.seatNames,
    required this.me,
  });

  final CoincheController controller;
  final Team team;

  // Avatar de chaque siège, indexé par Seat (issue #554).
  final List<String> avatarIds;
  final Map<Seat, String> seatNames;
  final String me;

  @override
  Widget build(BuildContext context) {
    final round = controller.round;
    final color = team == Team.ns
        ? const Color(0xFF047857)
        : const Color(0xFFB91C1C);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final seat in coincheTeamSeats(team))
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 2),
                child: _CornerAvatar(
                  seat: seat,
                  round: round,
                  tone: color,
                  avatarId: avatarIds[seat.index],
                  name: coincheSeatName(seatNames, seat, me),
                ),
              ),
          ],
        ),
        const SizedBox(height: 2),
        Container(
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
        ),
      ],
    );
  }
}

/// Médaillon d'un coin, agrandi quand c'est le tour de son siège (#1004).
class _CornerAvatar extends StatelessWidget {
  const _CornerAvatar({
    required this.seat,
    required this.round,
    required this.tone,
    required this.avatarId,
    required this.name,
  });

  final Seat seat;
  final RoundState round;
  final Color tone;
  final String avatarId;
  final String name;

  @override
  Widget build(BuildContext context) {
    final active = round.turn == seat &&
        (round.phase == CoinchePhase.bidding ||
            round.phase == CoinchePhase.playing);
    return TurnAvatar(
      tone: tone,
      active: active,
      avatarId: avatarId,
      state: gameAvatarState(
        seat: seat.index,
        finished: round.phase == CoinchePhase.done,
        winners: coincheWinnerSeats(round),
      ),
      semanticLabel: name,
      baseSize: 28,
      activeSize: 40,
    );
  }
}
