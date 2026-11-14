import 'dart:math' as math;

import 'package:material_ui/material_ui.dart';

import 'package:flutter/foundation.dart' show ValueListenable;

import '../../core/layout/device_metrics.dart';
import '../../game/coinche.dart';
import '../../core/i18n/app_language.dart';
import '../../core/theme/game_style.dart';
import '../menu/menu_models.dart';
import 'coinche_card_view.dart';
import 'coinche_controller.dart';
import '../../core/services/ad_free_service.dart';
import '../../core/theme/comic_palette.dart';
import '../../widgets/comic/comic_panel.dart';
import '../../widgets/exit_guard.dart';
import '../../widgets/game_scaffold.dart';
import '../../core/services/saved_game_store.dart';
import '../../widgets/resume_game.dart';
import '../../widgets/difficulty_chip.dart';
import '../../widgets/game_header.dart';
import '../../widgets/card_flight.dart';
import '../../widgets/card_motion.dart';

/// Clé partagée avec le mode sans pub (même nom que le web).
const _feltColor = Color(0xFF10B981);
const _frameColor = Color(0xFF4A2A10);
const _creamColor = Color(0xFFFFF8E7);
const _inkColor = Color(0xFF20284B);
const _goldColor = Color(0xFFFFE16B);

const _teamLabel = {Team.ns: 'Nous', Team.ew: 'Eux'};
const _seatLabel = {
  Seat.south: 'Toi',
  Seat.north: 'Partenaire',
  Seat.west: 'Adversaire',
  Seat.east: 'Adversaire',
};
final _suitNames = CoincheSuit.values;

/// Écran de la Coinche (Belote au menu). Logique dans CoincheController et lib/game/coinche.dart.
class CoincheScreen extends StatefulWidget {
  const CoincheScreen({
    super.key,
    required this.difficulty,
    required this.targetScore,
  });

  final Difficulty difficulty;
  final int targetScore;

  @override
  State<CoincheScreen> createState() => _CoincheScreenState();
}

class _CoincheScreenState extends State<CoincheScreen>
    with CardMotionMixin<CoincheScreen> {
  late final CoincheController _controller = CoincheController(
    store: const SharedPreferencesSavedGameStore(),
    target: widget.targetScore,
    difficulty: widget.difficulty,
  );
  final ValueListenable<bool> _adFree = AdFreeService.instance.active;

  // Mouvements animés (#266) : donne, jeu, pli ramassé, pour toutes les places.
  static const _dealStep = Duration(milliseconds: 90);
  static const _stagger = Duration(milliseconds: 40);
  final Map<String, GlobalKey> _keys = {};
  bool _ready = false;
  bool _restored = false;
  RoundState? _lastRound;

  GlobalKey _key(String name) => _keys.putIfAbsent(name, () => GlobalKey());

  DeviceMetrics get _metrics {
    final size = MediaQuery.sizeOf(context);
    return DeviceMetrics(width: size.width, height: size.height);
  }

  double get _handWidth => _metrics.coincheCardWidth;
  double get _trickWidth => _metrics.coincheCardWidth * 0.8;
  double get _seatWidth => _trickWidth * 0.6;

  @override
  void initState() {
    super.initState();
    _controller.addListener(_onChanged);
    _controller.restore().then((_) {
      if (!mounted) return;
      _ready = true;
      _lastRound = _controller.round;
      if (!_restored) _distribute();
      offerResume(context, _controller);
    });
    _adFree.addListener(_onAdFreeChanged);
  }

  @override
  void dispose() {
    _adFree.removeListener(_onAdFreeChanged);
    _controller.removeListener(_onChanged);
    _controller.dispose();
    super.dispose();
  }

  void _onAdFreeChanged() {
    if (mounted) setState(() {});
  }

  /// Rectangle d'une carte de largeur [width] centrée sur [rect].
  Rect _cardBox(Rect rect, double width) =>
      Rect.fromCenter(center: rect.center, width: width, height: width * 1.4);

  /// Place d'une place (chip du siège, ou la main pour le joueur) pour une carte.
  Rect? _seatBox(Seat seat, double width) {
    final rect = rectOfKey(_key('seat:${seat.name}'));
    return rect == null ? null : _cardBox(rect, width);
  }

  /// Tout mouvement de carte : donne, cartes jouées, pli ramassé (#266).
  void _onChanged() {
    final round = _controller.round;
    final before = _lastRound;
    if (identical(round, before)) return;
    if (!_ready) {
      _restored = true;
      return;
    }
    _lastRound = round;
    if (before == null) return;
    if (round.dealer != before.dealer ||
        before.phase == CoinchePhase.done ||
        before.phase == CoinchePhase.redeal) {
      _distribute();
      return;
    }
    _flyPlayed(before, round);
    _flyCollected(before, round);
  }

  /// Carte posée sur le tapis : depuis la main (joueur) ou la place (adversaire).
  void _flyPlayed(RoundState before, RoundState now) {
    final known = {for (final play in before.trick) play.card.id};
    final width = _trickWidth;
    final flights = <CardFlight>[];
    for (final play in now.trick) {
      final id = play.card.id;
      if (known.contains(id)) continue;
      final seatName = 'seat:${play.seat.name}';
      final originName = play.seat == Seat.south ? 'hand:$id' : seatName;
      final origin = rectOfKey(_key(originName));
      if (origin == null) continue;
      flights.add(
        CardFlight(
          from: _cardBox(origin, width),
          to: () => rectOfKey(_key('trick:$id')),
          child: CoincheCardView(width: width, card: play.card),
          landingId: id,
        ),
      );
    }
    flyAfterRender(flights);
  }

  /// Pli ramassé : les quatre cartes rejoignent la place du gagnant.
  void _flyCollected(RoundState before, RoundState now) {
    final winner = now.lastWinner;
    if (before.trick.length != 4 || now.trick.isNotEmpty || winner == null) {
      return;
    }
    final width = _trickWidth;
    final flights = <CardFlight>[];
    for (final play in before.trick) {
      final from = rectOfKey(_key('trick:${play.card.id}'));
      if (from == null) continue;
      flights.add(
        CardFlight(
          from: from,
          to: () => _seatBox(winner, width),
          child: CoincheCardView(width: width, card: play.card),
          delay: _stagger * flights.length,
        ),
      );
    }
    flyAfterRender(flights);
  }

  /// Donne : pour chaque tour, une carte à chaque place (la tienne face visible).
  void _distribute() {
    final table = rectOfKey(_key('table'));
    if (table == null) return;
    final round = _controller.round;
    final handWidth = _handWidth;
    final origin = _cardBox(table, handWidth);
    final mine = _controller.hand;
    const others = [Seat.north, Seat.west, Seat.east];
    var rounds = mine.length;
    for (final seat in others) {
      rounds = math.max(rounds, round.hands[seat]!.length);
    }
    final flights = <CardFlight>[];
    for (var k = 0; k < rounds; k++) {
      final delay = _dealStep * k;
      if (k < mine.length) {
        final card = mine[k];
        flights.add(
          CardFlight(
            from: origin,
            to: () => rectOfKey(_key('hand:${card.id}')),
            child: CoincheCardView(width: handWidth, card: card),
            delay: delay,
            landingId: card.id,
          ),
        );
      }
      for (final seat in others) {
        if (k >= round.hands[seat]!.length) continue;
        flights.add(
          CardFlight(
            from: origin,
            to: () => _seatBox(seat, _seatWidth),
            child: CoincheCardView(width: _seatWidth),
            delay: delay,
          ),
        );
      }
    }
    flyAfterRender(flights);
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final metrics = DeviceMetrics(width: size.width, height: size.height);

    return ExitGuard(
      active: _controller.match.winner == null,
      child: ListenableBuilder(
        listenable: _controller,
        builder: (context, _) {
          final c = _controller;
          return GameScaffold(
            showAd: !_adFree.value,
            background: const ColoredBox(color: Color(0xFF8B4513)),
            overlays: [
              if (c.summary != null)
                Positioned.fill(
                  child: _SummaryDialog(
                    controller: c,
                    onMenu: () => Navigator.of(context).maybePop(),
                  ),
                ),
            ],
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
              child: Column(
                children: [
                  _Header(controller: c, difficulty: widget.difficulty),
                  const SizedBox(height: 8),
                  _ScoreBar(controller: c),
                  const SizedBox(height: 8),
                  Expanded(
                    child: _Table(
                      controller: c,
                      cardWidth: metrics.coincheCardWidth * 0.8,
                      keyOf: _key,
                      landing: landing,
                    ),
                  ),
                  const SizedBox(height: 8),
                  _HandFooter(
                    controller: c,
                    cardWidth: metrics.coincheCardWidth,
                    keyOf: _key,
                    landing: landing,
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// En-tête
// ---------------------------------------------------------------------------

class _Header extends StatelessWidget {
  const _Header({required this.controller, required this.difficulty});

  final CoincheController controller;
  final Difficulty difficulty;

  @override
  Widget build(BuildContext context) {
    return GameHeader(
      onMenu: () => Navigator.of(context).maybePop(),
      center: Expanded(
        child: Column(
          children: [
            Wrap(
              alignment: WrapAlignment.center,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 6,
              children: [
                Text(
                  'Manche ${controller.match.round}',
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
                DifficultyChip(difficulty: difficulty),
              ],
            ),
          ],
        ),
      ),
      trailing: Semantics(
        label: tf('sMatchTarget', {'n': '${controller.match.target}'}),
        child: SizedBox(
          width: 48,
          height: 48,
          child: Stack(
            alignment: Alignment.center,
            children: [
              const Icon(
                Icons.emoji_events,
                size: 48,
                color: Color(0xFFFBBF24),
              ),
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text(
                  '${controller.match.target}',
                  style: const TextStyle(
                    color: _inkColor,
                    fontWeight: FontWeight.w900,
                    fontSize: 11,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Bandeau de score
// ---------------------------------------------------------------------------

class _ScoreBar extends StatelessWidget {
  const _ScoreBar({required this.controller});

  final CoincheController controller;

  @override
  Widget build(BuildContext context) {
    final match = controller.match;
    final contract = controller.round.contract;
    return Semantics(
      label: tf('sScoreUsThem', {
        'a': '${match.scores[Team.ns]}',
        'b': '${match.scores[Team.ew]}',
      }),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFFFACC15), Color(0xFFFBBF24), Color(0xFFFB923C)],
          ),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: _frameColor, width: 3),
        ),
        child: Row(
          children: [
            _TeamScore(
              label: _teamLabel[Team.ns]!,
              score: match.scores[Team.ns]!,
              color: const Color(0xFF047857),
            ),
            Expanded(
              child: Column(
                children: [
                  const Text(
                    'CONTRAT',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF17213D),
                    ),
                  ),
                  Container(
                    margin: const EdgeInsets.only(top: 2),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: _frameColor, width: 2),
                    ),
                    child: Text(
                      contract == null
                          ? 'Enchères'
                          : '${contract.value} ${coincheSuitSymbol(contract.mode)}'
                              '${contract.multiplier > 1 ? ' ×${contract.multiplier}' : ''}'
                              ' · ${_teamLabel[teamOf(contract.seat)]}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            _TeamScore(
              label: _teamLabel[Team.ew]!,
              score: match.scores[Team.ew]!,
              color: const Color(0xFFB91C1C),
            ),
          ],
        ),
      ),
    );
  }
}

class _TeamScore extends StatelessWidget {
  const _TeamScore({
    required this.label,
    required this.score,
    required this.color,
  });

  final String label;
  final int score;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          constraints: const BoxConstraints(minWidth: 52),
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: color, width: 2),
          ),
          child: Text(
            '$score',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w900,
              fontSize: 22,
            ),
          ),
        ),
        const SizedBox(width: 4),
        Text(
          label.toUpperCase(),
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w900,
            color: _inkColor,
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Tapis : sièges, pli, statut, enchères
// ---------------------------------------------------------------------------

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

class _BidPanel extends StatelessWidget {
  const _BidPanel({required this.controller});

  final CoincheController controller;

  @override
  Widget build(BuildContext context) {
    final contract = controller.round.contract;
    final choiceValue = controller.choiceValue;
    final choiceMode = controller.choiceMode;
    final canAnnounce = choiceMode != null &&
        choiceValue != null &&
        choiceValue >= controller.minValue;

    return Container(
      constraints: const BoxConstraints(maxWidth: 420),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _creamColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _frameColor, width: 3),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  t('yourBid'),
                  style: TextStyle(
                    color: _inkColor,
                    fontWeight: FontWeight.w900,
                    fontSize: 16,
                  ),
                ),
              ),
              Text(
                contract == null
                    ? 'Aucune annonce'
                    : 'Actuel : ${contract.value} ${coincheSuitSymbol(contract.mode)}',
                style: const TextStyle(
                  color: _inkColor,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              for (final suit in _suitNames)
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 2),
                    child: _ChoiceButton(
                      label: coincheSuitSymbol(suit),
                      semanticsLabel: coincheSuitName(suit),
                      selected: choiceMode == suit,
                      textColor: coincheSuitColor(suit),
                      onTap: () => controller.setChoiceMode(suit),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 6),
          GridView.count(
            crossAxisCount: 5,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 6,
            crossAxisSpacing: 6,
            childAspectRatio: 1.6,
            children: [
              for (var value = minBid; value <= maxBid; value += 10)
                _ChoiceButton(
                  label: '$value',
                  selected: choiceValue == value,
                  enabled: value >= controller.minValue,
                  textColor: _inkColor,
                  onTap: () => controller.setChoiceValue(value),
                ),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            alignment: WrapAlignment.center,
            children: [
              _ActionButton(
                label: t('pass'),
                onTap: () => controller.callBid(const PassBid()),
              ),
              _ActionButton(
                label: t('bid'),
                primary: true,
                enabled: canAnnounce,
                onTap: controller.announce,
              ),
              if (controller.canContre)
                _ActionButton(
                  label: t('contre'),
                  danger: true,
                  onTap: () => controller.callBid(const ContreBid()),
                ),
              if (controller.canSurcoinche)
                _ActionButton(
                  label: t('surcoinche'),
                  danger: true,
                  onTap: () => controller.callBid(const SurcoincheBid()),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ChoiceButton extends StatelessWidget {
  const _ChoiceButton({
    required this.label,
    required this.selected,
    required this.textColor,
    required this.onTap,
    this.semanticsLabel,
    this.enabled = true,
  });

  final String label;
  final String? semanticsLabel;
  final bool selected;
  final bool enabled;
  final Color textColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    if (kComicCoinche) {
      // Case BD (#156) : papier, jaune quand sélectionnée, libellé en Bangers.
      return Semantics(
        button: true,
        selected: selected,
        enabled: enabled,
        label: semanticsLabel,
        child: Opacity(
          opacity: enabled ? 1 : 0.3,
          child: GestureDetector(
            onTap: enabled ? onTap : null,
            child: ComicPanel(
              color: selected ? ComicPalette.yellow : ComicPalette.paper,
              radius: 10,
              shadowOffset: const Offset(2, 2),
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
              child: Center(
                child: Text(
                  label,
                  style: TextStyle(
                    fontFamily: 'Bangers',
                    fontSize: 20,
                    letterSpacing: 1,
                    color: ComicPalette.ink,
                  ),
                ),
              ),
            ),
          ),
        ),
      );
    }
    return Semantics(
      button: true,
      selected: selected,
      label: semanticsLabel,
      child: Opacity(
        opacity: enabled ? 1 : 0.3,
        child: Material(
          color: selected ? _goldColor : Colors.white,
          borderRadius: BorderRadius.circular(10),
          child: InkWell(
            borderRadius: BorderRadius.circular(10),
            onTap: enabled ? onTap : null,
            child: Container(
              alignment: Alignment.center,
              constraints: const BoxConstraints(minHeight: 44),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: selected ? _frameColor : const Color(0x33152646),
                  width: 2,
                ),
              ),
              child: Text(
                label,
                style: TextStyle(
                  color: textColor,
                  fontWeight: FontWeight.w900,
                  fontSize: 18,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.label,
    required this.onTap,
    this.primary = false,
    this.danger = false,
    this.enabled = true,
  });

  final String label;
  final VoidCallback onTap;
  final bool primary;
  final bool danger;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    if (kComicCoinche) {
      // Bouton BD (#146) : case papier, rouge pour le danger, jaune pour l'action principale.
      final fill = danger
          ? ComicPalette.red
          : (primary ? ComicPalette.yellow : ComicPalette.paper);
      final ink = danger ? ComicPalette.paper : ComicPalette.ink;
      return Opacity(
        opacity: enabled ? 1 : 0.4,
        child: Semantics(
          button: true,
          enabled: enabled,
          label: label,
          child: GestureDetector(
            onTap: enabled ? onTap : null,
            child: ComicPanel(
              color: fill,
              radius: 12,
              shadowOffset: const Offset(3, 3),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              child: ConstrainedBox(
                constraints: const BoxConstraints(minHeight: 24, minWidth: 86),
                child: Center(
                  child: Text(
                    label,
                    style: TextStyle(
                      fontFamily: 'Bangers',
                      fontSize: 18,
                      letterSpacing: 1,
                      color: ink,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
    }
    final Color background = danger
        ? const Color(0xFFD71920)
        : primary
            ? const Color(0xFFF2B74E)
            : Colors.white;
    final Color foreground = danger ? Colors.white : _inkColor;
    return Opacity(
      opacity: enabled ? 1 : 0.4,
      child: Material(
        color: background,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: enabled ? onTap : null,
          child: Container(
            constraints: const BoxConstraints(minHeight: 44, minWidth: 110),
            alignment: Alignment.center,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Text(
              label,
              style: TextStyle(color: foreground, fontWeight: FontWeight.w900),
            ),
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Main du joueur
// ---------------------------------------------------------------------------

class _HandFooter extends StatelessWidget {
  const _HandFooter({
    required this.controller,
    required this.cardWidth,
    required this.keyOf,
    required this.landing,
  });

  final CoincheController controller;
  final double cardWidth;
  final GlobalKey Function(String name) keyOf;
  final Set<String> landing;

  /// Une carte de la main : elle reste vide tant qu'elle vole vers la main.
  Widget _handCard(CoincheCard card, Set<String> legal, bool dimmed) {
    final playable = legal.contains(card.id);
    void play() => controller.playHuman(card.id);
    return KeyedSubtree(
      key: keyOf('hand:${card.id}'),
      child: MaskedSlot(
        hidden: landing.contains(card.id),
        child: CoincheCardView(
          width: cardWidth,
          card: card,
          dimmed: dimmed && !playable,
          onTap: dimmed && playable ? play : null,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final hand = controller.hand;
    final contract = controller.round.contract;
    final legal = controller.legalIds;
    final dimmed = controller.isHumanPlayTurn;

    return Container(
      key: keyOf('seat:south'),
      padding: const EdgeInsets.fromLTRB(8, 6, 8, 8),
      decoration: BoxDecoration(
        color: _creamColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _frameColor, width: 3),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'TA MAIN · ${hand.length} cartes',
                  style: const TextStyle(
                    color: _inkColor,
                    fontWeight: FontWeight.w900,
                    fontSize: 12,
                  ),
                ),
              ),
              if (contract != null)
                Text(
                  'Atout : ${coincheSuitSymbol(contract.mode)}',
                  style: TextStyle(
                    color: coincheSuitColor(contract.mode),
                    fontWeight: FontWeight.w900,
                  ),
                ),
            ],
          ),
          LayoutBuilder(
            builder: (context, constraints) {
              final n = hand.length;
              if (n == 0) return SizedBox(height: cardWidth * 1.4 + 12);
              // Chevauchement de 65 % de la largeur, réduit si la main ne tient pas.
              final overlap =
                  n > 1 ? (constraints.maxWidth - cardWidth) / (n - 1) : 0.0;
              final step = [
                cardWidth * 0.65,
                overlap,
              ].reduce((a, b) => a < b ? a : b);
              final total = cardWidth + step * (n - 1);
              return SizedBox(
                height: cardWidth * 1.4 + 12,
                child: Center(
                  child: SizedBox(
                    width: total,
                    child: Stack(
                      children: [
                        for (var i = 0; i < n; i++)
                          Positioned(
                            left: step * i,
                            top: legal.contains(hand[i].id) && dimmed ? 0 : 8,
                            child: _handCard(hand[i], legal, dimmed),
                          ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Récapitulatif de manche ou de partie
// ---------------------------------------------------------------------------

class _SummaryDialog extends StatelessWidget {
  const _SummaryDialog({required this.controller, required this.onMenu});

  final CoincheController controller;
  final VoidCallback onMenu;

  @override
  Widget build(BuildContext context) {
    final summary = controller.summary!;
    final match = controller.match;
    final winner = match.winner;
    final title = winner != null
        ? (winner == Team.ns ? 'Victoire !' : 'Défaite')
        : summary.made
            ? (summary.capot ? 'Capot !' : 'Contrat réussi')
            : 'Chute';
    final multiplier = summary.contract.multiplier > 1
        ? ' ×${summary.contract.multiplier}'
        : '';

    return ColoredBox(
      color: Colors.black54,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFF059669),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: Colors.black, width: 4),
                boxShadow: const [
                  BoxShadow(color: Colors.black, offset: Offset(0, 7)),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: _goldColor,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.black, width: 2),
                    ),
                    child: Text(
                      winner != null
                          ? 'PARTIE TERMINÉE'
                          : 'MANCHE ${match.round - 1}',
                      style: const TextStyle(
                        color: Color(0xFF17213D),
                        fontSize: 11,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 30,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${summary.contract.value} ${coincheSuitSymbol(summary.contract.mode)}$multiplier'
                    ' · ${_teamLabel[teamOf(summary.contract.seat)]}',
                    style: const TextStyle(
                      color: Colors.white70,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      for (final team in Team.values)
                        Expanded(
                          child: Container(
                            margin: const EdgeInsets.symmetric(horizontal: 4),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.black26,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Column(
                              children: [
                                Text(
                                  _teamLabel[team]!.toUpperCase(),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                                Text(
                                  '+${summary.awarded[team]}',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 24,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                                Text(
                                  'Cartes ${summary.points[team]}',
                                  style: const TextStyle(
                                    color: Colors.white70,
                                    fontSize: 11,
                                  ),
                                ),
                                Text(
                                  'Total ${match.scores[team]}',
                                  style: const TextStyle(
                                    color: Colors.white70,
                                    fontSize: 11,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  if (winner != null) ...[
                    _DialogButton(
                      label: t('replay'),
                      onTap: controller.restart,
                    ),
                    TextButton(
                      onPressed: onMenu,
                      child: Text(
                        t('backToMenu'),
                        style: TextStyle(color: Colors.white70),
                      ),
                    ),
                  ] else
                    _DialogButton(
                      label: t('nextRound'),
                      onTap: controller.nextRound,
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _DialogButton extends StatelessWidget {
  const _DialogButton({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: FilledButton(
        style: FilledButton.styleFrom(
          backgroundColor: _goldColor,
          foregroundColor: const Color(0xFF3D351F),
          padding: const EdgeInsets.symmetric(vertical: 14),
        ),
        onPressed: onTap,
        child: Text(label, style: const TextStyle(fontWeight: FontWeight.w900)),
      ),
    );
  }
}
