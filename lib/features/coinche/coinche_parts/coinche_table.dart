part of '../coinche_screen.dart';

class _Table extends StatelessWidget {
  const _Table({
    required this.controller,
    required this.cardWidth,
    required this.keyOf,
    required this.landing,
  });

  final CoincheController controller;
  final double cardWidth;
  final GlobalKey Function(String name) keyOf;
  final Set<String> landing;

  @override
  Widget build(BuildContext context) {
    final round = controller.round;
    final status = controller.isBiddingTurn ? null : _statusText(round);
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
                ),
              ),
            ),
          ),
          Center(
            child: _TrickArea(
              trick: round.trick,
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
                      color:
                          yourTurnToPlay ? _goldColor : const Color(0xFFF97316),
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
                    child: _BidPanel(controller: controller),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

String? _statusText(RoundState round) {
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
  return '${_seatLabel[turn]} réfléchit…';
}

class _SeatInfo extends StatelessWidget {
  const _SeatInfo({
    required this.seat,
    required this.round,
    required this.cardWidth,
  });

  final Seat seat;
  final RoundState round;
  final double cardWidth;

  @override
  Widget build(BuildContext context) {
    final call = round.phase == CoinchePhase.bidding ? round.calls[seat] : null;
    final count = round.hands[seat]!.length;
    final active = round.turn == seat &&
        (round.phase == CoinchePhase.bidding ||
            round.phase == CoinchePhase.playing);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
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
                _seatLabel[seat]!,
                style: TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 12,
                  color: active ? const Color(0xFF513B00) : Colors.white,
                ),
              ),
              if (round.dealer == seat) ...[
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
    );
  }
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
    required this.cardWidth,
    required this.keyOf,
    required this.landing,
  });

  final List<Play> trick;
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
                  child: CoincheCardView(width: cardWidth, card: play.card),
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
