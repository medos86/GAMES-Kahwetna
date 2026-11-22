import 'dart:async';
import 'dart:math' as math;

import 'package:material_ui/material_ui.dart';

import 'package:flutter/foundation.dart' show ValueListenable;

import '../../core/avatars/avatar_catalog.dart';
import '../../core/avatars/game_avatars.dart';
import '../../core/layout/device_metrics.dart';
import '../../game/coinche.dart';
import '../../core/i18n/app_language.dart';
import '../../core/theme/game_style.dart';
import '../menu/menu_models.dart';
import 'coinche_card_view.dart';
import 'coinche_controller.dart';
import 'coinche_opponent_names.dart';
import '../../core/services/ad_free_service.dart';
import '../../core/services/game_end_watcher.dart';
import '../../core/services/interstitial_service.dart';
import '../../core/theme/comic_palette.dart';
import '../../widgets/turn_avatar.dart';
import 'coinche_avatars.dart';
import '../../widgets/comic/comic_panel.dart';
import '../../widgets/exit_guard.dart';
import '../../widgets/game_scaffold.dart';
import '../../core/services/saved_game_store.dart';
import '../../widgets/resume_game.dart';
import '../../widgets/difficulty_chip.dart';
import '../../widgets/trophy_badge.dart';
import '../../widgets/dialog_button.dart';
import '../../widgets/round_result_panel.dart';
import '../../widgets/game_header.dart';
import '../../widgets/card_flight.dart';
import '../../widgets/card_motion.dart';

part 'coinche_parts/coinche_score.dart';
part 'coinche_parts/coinche_table.dart';
part 'coinche_parts/coinche_bid_panel.dart';
part 'coinche_parts/coinche_footer_summary.dart';

/// Clé partagée avec le mode sans pub (même nom que le web).
const _feltColor = ComicPalette.felt;
const _frameColor = ComicPalette.ink;
const _creamColor = Color(0xFFFFF8E7);
const _inkColor = Color(0xFF20284B);
const _goldColor = Color(0xFFFFE16B);

const _teamLabel = {Team.ns: 'Nous', Team.ew: 'Eux'};
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
  // Avatars des 4 sièges, indexés par Seat (issue #554) ; 0 = joueur.
  List<String> _avatarIds = [defaultAvatar.id, 'lion', 'tiger', 'panda'];

  // Prénoms des adversaires, tirés au hasard à chaque partie (issue #770).
  final Map<Seat, String> _seatNames = pickCoincheOpponentNames(math.Random());

  late final CoincheController _controller = CoincheController(
    store: const SharedPreferencesSavedGameStore(),
    target: widget.targetScore,
    difficulty: widget.difficulty,
  );
  final ValueListenable<bool> _adFree = AdFreeService.instance.active;
  late final GameEndWatcher _endWatcher = GameEndWatcher(
    isEnded: () => _controller.match.winner != null,
    onEnded: () => unawaited(InterstitialService.instance.onGameFinished()),
  );

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
    InterstitialService.instance.preload();
    loadGameAvatars(seats: 4).then((ids) {
      if (mounted) setState(() => _avatarIds = ids);
    });
    _controller.addListener(_endWatcher.check);
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
    _controller.removeListener(_endWatcher.check);
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
            background: const ColoredBox(color: ComicPalette.tableWood),
            overlays: [
              if (c.summary != null)
                Positioned.fill(
                  child: _SummaryDialog(
                    controller: c,
                    avatarIds: _avatarIds,
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
                      avatarIds: _avatarIds,
                      seatNames: _seatNames,
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
