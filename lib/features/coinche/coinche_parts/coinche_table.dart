part of '../coinche_screen.dart';

class _Table extends StatelessWidget {
  const _Table({
    required this.controller,
    required this.cardWidth,
    required this.keyOf,
    required this.landing,
    required this.avatarIds,
    required this.seatNames,
    required this.footer,
  });

  final CoincheController controller;
  final double cardWidth;
  final GlobalKey Function(String name) keyOf;
  final Set<String> landing;

  // Avatar de chaque siège, indexé par Seat (issue #554).
  final List<String> avatarIds;

  // Prénoms des adversaires, tirés au hasard à chaque partie (issue #770).
  final Map<Seat, String> seatNames;

  // Main du joueur, posée dans le même tapis (#838) : un seul grand tapis.
  final Widget footer;

  @override
  Widget build(BuildContext context) {
    final round = controller.round;
    final status =
        controller.isBiddingTurn ? null : _statusText(round, seatNames);
    final yourTurnToPlay = controller.isHumanPlayTurn;

    return Container(
      key: keyOf('table'),
      decoration: BoxDecoration(
        color: _feltColor,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: _frameColor, width: 6),
        boxShadow: [
          BoxShadow(
            color: _frameColor,
            spreadRadius: 3,
            blurRadius: 0,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Expanded(
            child: Stack(
              children: [
                Align(
                  alignment: Alignment.topCenter,
                  child: Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: KeyedSubtree(
                      key: keyOf('seat:north'),
                      child: _SeatInfo(
                        seat: Seat.north,
                        round: round,
                        cardWidth: cardWidth * 0.6,
                        avatarId: avatarIds[Seat.north.index],
                        name: coincheSeatName(seatNames, Seat.north),
                      ),
                    ),
                  ),
                ),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Padding(
                    padding: const EdgeInsets.only(left: 6),
                    child: KeyedSubtree(
                      key: keyOf('seat:west'),
                      child: _SeatInfo(
                        seat: Seat.west,
                        round: round,
                        cardWidth: cardWidth * 0.6,
                        avatarId: avatarIds[Seat.west.index],
                        name: coincheSeatName(seatNames, Seat.west),
                      ),
                    ),
                  ),
                ),
                Align(
                  alignment: Alignment.centerRight,
                  child: Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: KeyedSubtree(
                      key: keyOf('seat:east'),
                      child: _SeatInfo(
                        seat: Seat.east,
                        round: round,
                        cardWidth: cardWidth * 0.6,
                        avatarId: avatarIds[Seat.east.index],
                        name: coincheSeatName(seatNames, Seat.east),
                      ),
                    ),
                  ),
                ),
                Center(
                  child: _TrickArea(
                    trick: round.trick,
                    trumpMode: round.contract?.mode,
                    cardWidth: cardWidth,
                    keyOf: keyOf,
                    landing: landing,
                  ),
                ),
                if (status != null)
                  Positioned(
                    left: 8,
                    right: 8,
                    bottom: 8,
                    child: Center(
                      child: Semantics(
                        liveRegion: true,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: yourTurnToPlay
                                ? _goldColor
                                : const Color(0xFFF97316),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.black, width: 2),
                          ),
                          child: Text(
                            status,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontWeight: FontWeight.w900,
                              color: yourTurnToPlay
                                  ? const Color(0xFF3D351F)
                                  : Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                if (controller.isBiddingTurn)
                  Positioned.fill(
                    child: Padding(
                      padding: const EdgeInsets.all(8),
                      child: Align(
                        alignment: Alignment.bottomCenter,
                        child: SingleChildScrollView(
                          child: _BidPanel(
                            controller: controller,
                            seatNames: seatNames,
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          footer,
        ],
      ),
    );
  }
}

String? _statusText(RoundState round, Map<Seat, String> seatNames) {
  if (round.phase == CoinchePhase.redeal)
    return 'Tout le monde passe, nouvelle donne…';
  if (round.phase == CoinchePhase.done) return 'Manche terminée';
  if (round.trick.length == 4) return 'Pli ramassé…';
  final turn = round.turn;
  if (turn == null) return null;
  if (turn == Seat.south) {
    return round.phase == CoinchePhase.bidding
        ? 'À toi d’annoncer'
        : 'À toi de jouer';
  }
  return '${coincheSeatName(seatNames, turn)} réfléchit…';
}

class _SeatInfo extends StatelessWidget {
  const _SeatInfo({
    required this.seat,
    required this.round,
    required this.cardWidth,
    required this.avatarId,
    required this.name,
  });

  final Seat seat;
  final RoundState round;
  final double cardWidth;

  // Avatar du siège (issue #554).
  final String avatarId;

  // Nom affiché sous l'avatar (issue #770).
  final String name;

  @override
  Widget build(BuildContext context) {
    final call = round.phase == CoinchePhase.bidding ? round.calls[seat] : null;
    // Annonceur (#733) : son contrat reste affiché pendant tout le jeu.
    final contract =
        round.phase == CoinchePhase.bidding ? null : round.contract;
    final announces = contract != null && contract.seat == seat;
    final count = round.hands[seat]!.length;
    final active = round.turn == seat &&
        (round.phase == CoinchePhase.bidding ||
            round.phase == CoinchePhase.playing);

    return FittedBox(
      fit: BoxFit.scaleDown,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Médaillon 3D (#735) : le joueur dont c'est le tour est agrandi, comme au Ludo.
          TurnAvatar(
            tone: teamOf(seat) == Team.ns
                ? const Color(0xFF047857)
                : const Color(0xFFB91C1C),
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
          ),
          const SizedBox(height: 2),
          _SeatNamePill(
            seat: seat,
            name: name,
            active: active,
            isDealer: round.dealer == seat,
          ),
          if (call != null)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: _frameColor, width: 2),
                ),
                child: Text(
                  _callText(call),
                  style: const TextStyle(
                    color: _inkColor,
                    fontWeight: FontWeight.w900,
                    fontSize: 12,
                  ),
                ),
              ),
            ),
          if (announces)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Container(
                key: ValueKey('contract:${seat.name}'),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: _goldColor,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: _frameColor, width: 2),
                ),
                child: Text(
                  coincheContractLabel(contract),
                  style: const TextStyle(
                    color: _inkColor,
                    fontWeight: FontWeight.w900,
                    fontSize: 12,
                  ),
                ),
              ),
            ),
          if (count > 0)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CoincheCardView(width: cardWidth),
                  const SizedBox(width: 4),
                  Text(
                    '×$count',
                    style: const TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

/// Libellé du contrat sur la place de l'annonceur (#733).
String coincheContractLabel(Contract contract) {
  final mult = contract.multiplier > 1 ? ' ×${contract.multiplier}' : '';
  final team = teamOf(contract.seat) == Team.ns ? 'Nous' : 'Eux';
  return '${contract.value} ${coincheSuitSymbol(contract.mode)}$mult · $team';
}

String _callText(BidAction call) => switch (call) {
      PassBid() => 'Passe',
      ContreBid() => 'Contre !',
      SurcoincheBid() => 'Surcoinche !',
      ValueBid(:final value, :final mode) =>
        '$value ${coincheSuitSymbol(mode)}',
    };

class _TrickArea extends StatelessWidget {
  const _TrickArea({
    required this.trick,
    this.trumpMode,
    required this.cardWidth,
    required this.keyOf,
    required this.landing,
  });

  final List<Play> trick;

  /// Couleur d'atout du contrat (#734), null tant qu'il n'y en a pas.
  final CoincheSuit? trumpMode;
  final double cardWidth;
  final GlobalKey Function(String name) keyOf;
  final Set<String> landing;

  @override
  Widget build(BuildContext context) {
    final height = cardWidth * 1.4;
    return SizedBox(
      width: cardWidth * 3.1,
      height: height * 2.1,
      child: Stack(
        children: [
          for (final play in trick)
            Align(
              alignment: _trickAlignment(play.seat),
              child: KeyedSubtree(
                key: keyOf('trick:${play.card.id}'),
                child: MaskedSlot(
                  hidden: landing.contains(play.card.id),
                  child: CoincheCardView(
                    width: cardWidth,
                    card: play.card,
                    trump: play.card.suit == trumpMode,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Alignment _trickAlignment(Seat seat) => switch (seat) {
        Seat.south => Alignment.bottomCenter,
        Seat.north => Alignment.topCenter,
        Seat.west => Alignment.centerLeft,
        Seat.east => Alignment.centerRight,
      };
}

/// Pastille du nom d'un siège. Les sièges latéraux (ouest, est) sont écrits verticalement,
/// comme au Rami, pour libérer de la place pour les cartes (issue #770).
class _SeatNamePill extends StatelessWidget {
  const _SeatNamePill({
    required this.seat,
    required this.name,
    required this.active,
    required this.isDealer,
  });

  final Seat seat;
  final String name;
  final bool active;
  final bool isDealer;

  @override
  Widget build(BuildContext context) {
    final pill = Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: active ? _goldColor : Colors.black.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: active ? _frameColor : Colors.black26,
          width: 2,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            name,
            style: TextStyle(
              fontWeight: FontWeight.w900,
              fontSize: 12,
              color: active ? const Color(0xFF513B00) : Colors.white,
            ),
          ),
          if (isDealer) ...[
            const SizedBox(width: 4),
            const CircleAvatar(
              radius: 8,
              backgroundColor: Colors.white,
              child: Text(
                'D',
                style: TextStyle(
                  fontSize: 9,
                  color: _inkColor,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ],
        ],
      ),
    );
    return RotatedBox(
      quarterTurns: coincheSeatQuarterTurns(seat),
      child: pill,
    );
  }
}
