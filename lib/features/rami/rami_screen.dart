import 'dart:async';
import 'dart:math' as math;

import 'package:material_ui/material_ui.dart';
import 'package:flutter/foundation.dart' show ValueListenable;

import '../../core/layout/device_metrics.dart';
import '../../core/services/toast.dart';
import '../../game/rami.dart' as rules;
import '../menu/menu_models.dart';
import 'rami_card_view.dart';
import 'rami_discard_shown.dart';
import 'rami_min_opening_shield.dart';
import 'rami_hand_layout.dart';
import 'rami_round_summary.dart';
import 'rami_round_reveal.dart';
import 'rami_controller.dart';
import '../../core/strings.dart';
import '../../core/i18n/app_language.dart';
import '../../core/services/ad_free_service.dart';
import '../../core/services/game_end_watcher.dart';
import '../../core/services/interstitial_service.dart';
import '../../widgets/exit_guard.dart';
import '../../widgets/game_scaffold.dart';
import '../../widgets/pulse_glow.dart';
import '../../core/services/saved_game_store.dart';
import '../../widgets/resume_game.dart';
import '../../core/theme/comic_palette.dart';
import '../../widgets/dialog_button.dart';
import '../../widgets/result_dialog.dart';
import '../../widgets/round_result_panel.dart';
import '../../widgets/trophy_badge.dart';
import '../../widgets/card_motion.dart';
import '../../widgets/difficulty_chip.dart';
import '../../widgets/game_header.dart';
import 'rami_action_button.dart';
import 'rami_turn_banner.dart';
import 'rami_scores_overlay.dart';

part 'rami_parts/rami_constants.dart';
part 'rami_parts/rami_gestures.dart';
part 'rami_parts/rami_widgets.dart';

/// Écran du Rami. Logique dans RamiController et lib/game/rami.dart.
class RamiScreen extends StatefulWidget {
  const RamiScreen({
    super.key,
    required this.difficulty,
    required this.targetScore,
  });

  final Difficulty difficulty;
  final int targetScore;

  @override
  State<RamiScreen> createState() => _RamiScreenState();
}

class _RamiScreenState extends State<RamiScreen>
    with CardMotionMixin<RamiScreen> {
  late final RamiController _c = RamiController(
    store: const SharedPreferencesSavedGameStore(),
    targetScore: widget.targetScore,
    difficulty: aiLevelFor(rules.RamiAiLevel.values, widget.difficulty),
    onMessage: _showMessage,
  );

  /// Clés des zones cibles (« discard », « table », « meld:id », « hand:id »), pour le test de position.
  final Map<String, GlobalKey> _keys = {};
  final GlobalKey _bodyKey = GlobalKey();
  _Press? _press;
  _Drag? _drag;
  // Largeur réelle des cartes de la main (la carte glissée garde cette taille).
  double _handCardWidth = 0;
  final ValueListenable<bool> _adFree = AdFreeService.instance.active;
  late final GameEndWatcher _endWatcher = GameEndWatcher(
    isEnded: () => _c.game.matchWinner != null,
    onEnded: () => unawaited(InterstitialService.instance.onGameFinished()),
  );

  @override
  void initState() {
    super.initState();
    InterstitialService.instance.preload();
    _c.addListener(_endWatcher.check);
    _c.addListener(_onRamiChanged);
    _c.restore().then((_) {
      _ready = true;
      _snapshot();
      // Partie neuve : la première donne est animée.
      if (!_restored) _distribute();
      if (mounted) offerResume(context, _c);
    });
    _adFree.addListener(_onAdFreeChanged);
  }

  @override
  void dispose() {
    _adFree.removeListener(_onAdFreeChanged);
    _c.removeListener(_endWatcher.check);
    _c.removeListener(_onRamiChanged);
    _c.dispose();
    super.dispose();
  }

  void _onAdFreeChanged() {
    if (mounted) setState(() {});
  }

  void _showMessage(String message) {
    if (!mounted) return;
    // Tous les messages du contrôleur sont des actions refusées.
    showToast(context, message, type: ToastType.error);
  }

  GlobalKey _key(String name) => _keys.putIfAbsent(name, () => GlobalKey());

  // -------------------------------------------------------------------------
  // Glisser-déposer : positions calculées à partir des clés
  // -------------------------------------------------------------------------

  Rect? _rectOf(GlobalKey key) {
    final box = key.currentContext?.findRenderObject();
    if (box is! RenderBox || !box.hasSize) return null;
    return box.localToGlobal(Offset.zero) & box.size;
  }

  RamiDropTarget? _targetAt(Offset point) {
    RamiDropTarget? table;
    var inHandRow = false;
    for (final entry in _keys.entries) {
      final rect = _rectOf(entry.value);
      if (rect == null || !rect.contains(point)) continue;
      final name = entry.key;
      if (name == 'handrow') {
        inHandRow = true;
      } else if (name == 'table') {
        table = const RamiDropTable();
      } else if (name == 'discard') {
        return const RamiDropDiscard();
      } else if (name.startsWith('meld:')) {
        return RamiDropMeld(name.substring(5));
      } else if (name.startsWith('hand:')) {
        return RamiDropHand(
          name.substring(5),
          after: point.dx > rect.center.dx,
        );
      }
    }
    // Entre deux cartes, les cartes s'écartent : la cible de la main reste celle d'avant.
    final previous = _drag?.target;
    if (inHandRow && previous is RamiDropHand) return previous;
    return table;
  }

  Offset _toLocal(Offset global) {
    final box = _bodyKey.currentContext?.findRenderObject();
    return box is RenderBox ? box.globalToLocal(global) : global;
  }

  void _onPointerDown(PointerDownEvent event, String id) {
    _closeScores();
    if (_press != null) return;
    _press = _Press(id, event.position);
  }

  void _onPointerMove(PointerMoveEvent event) {
    final press = _press;
    if (press == null) return;
    if (!press.active) {
      if ((event.position - press.start).distance < _dragThreshold) return;
      press.active = true;
    }
    setState(
      () => _drag = _Drag(
        press.id,
        _toLocal(event.position),
        _targetAt(event.position),
      ),
    );
  }

  void _onPointerUp(PointerUpEvent event) {
    final press = _press;
    _press = null;
    setState(() => _drag = null);
    if (press == null) return;
    if (press.active) {
      _c.dropCard(press.id, _targetAt(event.position));
    } else {
      _c.tap(press.id);
    }
  }

  void _onPointerCancel() {
    _press = null;
    setState(() => _drag = null);
  }

  // -------------------------------------------------------------------------
  // Construction
  // -------------------------------------------------------------------------

  /// Mise en page en LTR, même en arabe : les boutons gardent leur place (#241).
  @override
  Widget build(BuildContext context) => Directionality(
        textDirection: TextDirection.ltr,
        child: _buildScreen(context),
      );

  Widget _buildScreen(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final metrics = DeviceMetrics(width: size.width, height: size.height);
    // Cartes agrandies sur l'écran Rami (la formule de DeviceMetrics reste celle du source).
    final handWidth = metrics.ramiHandCardWidth * _ramiCardScale;

    return ExitGuard(
      active: _c.game.matchWinner == null,
      child: ListenableBuilder(
        listenable: _c,
        builder: (context, _) {
          final g = _c.game;
          return GameScaffold(
            showAd: !_adFree.value,
            background: const ColoredBox(color: _woodColor),
            overlays: [
              if (g.phase == rules.RamiPhase.end && g.roundResult != null)
                Positioned.fill(
                  child: RamiRoundReveal(
                    key: ValueKey('end-${g.round}'),
                    burst: _revealBurst(g),
                    child: _summary(g),
                  ),
                ),
            ],
            child: Stack(
              key: _bodyKey,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(8, 8, 8, 0),
                  child: Column(
                    children: [
                      _header(g),
                      const SizedBox(height: 6),
                      Expanded(child: _tableWithScores(handWidth, g)),
                      const SizedBox(height: 6),
                      _footer(handWidth, g),
                    ],
                  ),
                ),
                if (_drag != null) _dragOverlay(handWidth),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _header(rules.RamiState g) {
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
                  tf('round', {'n': '${g.round}'}),
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
                DifficultyChip(difficulty: widget.difficulty),
              ],
            ),
          ],
        ),
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            tooltip: Strings.seeRules,
            onPressed: _showRules,
            icon: const Icon(Icons.menu_book, color: Colors.white),
          ),
          Semantics(
            label: tf('target', {'n': '${g.targetScore}'}),
            child: SizedBox(
              width: 48,
              height: 48,
              child: Center(child: TrophyBadge(target: g.targetScore)),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showRules() {
    return showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: _creamColor,
        title: Text(
          Strings.rulesTitleRami,
          style: TextStyle(color: _inkColor, fontWeight: FontWeight.w900),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (final rule in _ramiRules)
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        rule.title,
                        style: const TextStyle(
                          color: _inkColor,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      Text(
                        rule.text,
                        style: TextStyle(
                          color: _inkColor.withValues(alpha: 0.8),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: Text(Strings.close),
          ),
        ],
      ),
    );
  }

  /// Scores cachés par défaut : un onglet en haut du tapis ouvre le panneau superposé (#528).
  /// Le tapis garde toute sa taille quand le panneau est ouvert.
  bool _scoresOpen = false;

  Widget _tableWithScores(double handWidth, rules.RamiState g) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Positioned.fill(child: _tableSection(handWidth, g)),
        // Toucher le tapis hors du panneau le referme (sans jouer le coup).
        if (_scoresOpen)
          Positioned.fill(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: _closeScores,
              child: const ColoredBox(color: Colors.black26),
            ),
          ),
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: Center(
            child: RamiScoresTab(
              key: _key('scoretab'),
              open: _scoresOpen,
              myScore: g.scores[0],
              onTap: () => setState(() => _scoresOpen = true),
            ),
          ),
        ),
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: RamiScoresPanel(
            open: _scoresOpen,
            onClose: _closeScores,
            child: _scores(g),
          ),
        ),
      ],
    );
  }

  /// Ferme le panneau dès que le joueur agit (carte, pioche, nouvelle manche) (#528).
  void _closeScores() {
    if (_scoresOpen) setState(() => _scoresOpen = false);
  }

  /// Case d'un siège pour les vols : sa place dans le panneau s'il est ouvert, sinon l'onglet.
  Rect? _seatRect(int seat) {
    if (_scoresOpen) {
      final chip = _seatRect(seat);
      if (chip != null) return chip;
    }
    return _rectOf(_key('scoretab'));
  }

  Widget _scores(rules.RamiState g) {
    return Row(
      children: [
        for (var seat = 0; seat < 4; seat++)
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2),
              child: KeyedSubtree(
                key: _key('seat:$seat'),
                child: _PlayerChip(seat: seat, game: g),
              ),
            ),
          ),
      ],
    );
  }

  Widget _tableSection(double handWidth, rules.RamiState g) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: _feltColor,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: _frameColor, width: 6),
        boxShadow: const [
          BoxShadow(color: _frameColor, spreadRadius: 3, offset: Offset(0, 8)),
        ],
      ),
      child: Column(
        children: [
          // Bouclier du seuil d'ouverture : en haut à droite du tapis, passif (#522).
          Align(
            alignment: Alignment.topRight,
            child: RamiMinOpeningShield(
              minimum: rules.minOpening(g),
              label: tf(
                'ramiMinOpen',
                {'n': '${rules.minOpening(g)}'},
              ),
            ),
          ),
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final sizes = [
                  for (final meld in g.table) meld.cards.length,
                ];
                // Zoom adaptatif : les cartes du tapis rétrécissent pour que tous les paquets tiennent.
                final meldWidth = ramiTableCardWidth(
                  sizes,
                  constraints.maxWidth - 16,
                  constraints.maxHeight - 12,
                  handWidth * 0.8,
                );
                return _tableCards(meldWidth, constraints.maxWidth - 16, g);
              },
            ),
          ),
          // Pioche et défausse à gauche, boutons d'action à leur côté sur la même ligne.
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Flexible(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.bottomLeft,
                    child: _piles(ramiPileWidth(handWidth), g),
                  ),
                ),
                Expanded(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.bottomRight,
                    child: _contextActions(g),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Boutons d'action affichés sur la table seulement quand ils servent :
  /// poser/défausser/reprendre quand des cartes sont sélectionnées.
  Widget _contextActions(rules.RamiState g) {
    final c = _c;
    if (!c.canPlay) return const SizedBox.shrink();
    if (c.selected.isEmpty && !c.canCancel) return const SizedBox.shrink();
    // Zone tactile haute de 48 dp pour chaque bouton, largeur naturelle (#522).
    return Padding(
      padding: const EdgeInsets.only(left: 10, bottom: 4),
      child: Wrap(
        alignment: WrapAlignment.start,
        spacing: 4,
        runSpacing: 4,
        children: [
          for (final button in _actions()) SizedBox(height: 48, child: button),
        ],
      ),
    );
  }

  /// Pioche : la carte-dos vole vers le bas de l'écran si les animations sont activées (#224).
  // -------------------------------------------------------------------------
  // Mouvements animés (#238) : distribution et cartes qui quittent la main.
  // Une seule règle pour tous les passages : la carte vole vers sa destination.
  // -------------------------------------------------------------------------

  static const _flightStagger = Duration(milliseconds: 40);
  static const _dealStep = Duration(milliseconds: 90);
  bool _ready = false;
  bool _restored = false;
  bool _dealPending = false;
  List<rules.RamiCard> _lastHand = const [];
  rules.RamiState? _lastGame;

  void _snapshot() {
    _lastHand = List.of(_c.hand);
    _lastGame = _c.game;
  }

  /// Lance une action qui donne une nouvelle manche : la distribution est animée.
  void _deal(VoidCallback action) {
    _closeScores();
    _dealPending = true;
    action();
    _dealPending = false;
  }

  void _onRamiChanged() {
    final prevHand = _lastHand;
    final prevGame = _lastGame;
    final g = _c.game;
    if (identical(g, prevGame)) return;
    if (!_ready) {
      _restored = true;
      return;
    }
    _snapshot();
    final still = {for (final card in _c.hand) card.id};
    final leaving = [
      for (final card in prevHand)
        if (!still.contains(card.id)) card,
    ];
    if (leaving.isNotEmpty) _flyLeaving(leaving);
    if (_dealPending) {
      _distribute();
    } else if (prevGame != null) {
      _flyAiMoves(prevGame, g);
    }
  }

  /// Coups des adversaires (#316) : pioche et défausse volent depuis / vers leur place.
  void _flyAiMoves(rules.RamiState prev, rules.RamiState next) {
    final seat = prev.turn;
    final chip = _seatRect(seat);
    final pile = _rectOf(_key('discard'));
    if (chip == null || pile == null) return;
    final flights = <CardFlight>[];
    for (final move in ramiAiMoves(prev, next)) {
      switch (move) {
        case RamiAiMove.drawStock:
          final stock = _rectOf(_key('stock'));
          if (stock == null) break;
          flights.add(CardFlight(
            from: stock,
            to: () => _seatTarget(seat, stock),
            child: RamiBackView(
              width: stock.width,
              asset: ramiStockBackAsset(prev.stock),
            ),
            duration: ramiAiFlightDuration,
          ));
        case RamiAiMove.takeDiscard:
          if (prev.discard.isEmpty) break;
          final top = prev.discard.last;
          flights.add(CardFlight(
            from: pile,
            to: () => _seatTarget(seat, pile),
            child: RamiCardView(card: top, width: pile.width),
            duration: ramiAiFlightDuration,
          ));
        case RamiAiMove.discard:
          final card = next.discard.last;
          final from = Rect.fromCenter(
            center: chip.center,
            width: pile.width,
            height: pile.height,
          );
          flights.add(CardFlight(
            from: from,
            to: () => _rectOf(_key('discard')),
            child: RamiCardView(card: card, width: pile.width),
            duration: ramiAiFlightDuration,
            landingId: card.id,
          ));
      }
    }
    if (flights.isNotEmpty) flyAfterRender(flights);
  }

  /// Vol des cartes qui quittent la main vers leur destination (défausse, combinaison, tapis).
  void _flyLeaving(List<rules.RamiCard> leaving) {
    final flights = <CardFlight>[];
    for (final card in leaving) {
      final from = _rectOf(_key('hand:${card.id}'));
      if (from == null) continue;
      flights.add(
        CardFlight(
          from: from,
          to: () => _targetFor(card.id, from),
          child: RamiCardView(card: card, width: from.width),
          delay: _flightStagger * flights.length,
          landingId: card.id,
        ),
      );
    }
    // Destinations lues après le rendu : la nouvelle position existe alors.
    flyAfterRender(flights);
  }

  Rect? _targetFor(String id, Rect from) {
    final g = _c.game;
    if (_c.top?.id == id) return _rectOf(_key('discard'));
    for (final meld in g.table) {
      if (meld.cards.any((card) => card.id == id)) {
        final r = _rectOf(_key('meld:${meld.id}'));
        return r == null
            ? null
            : Rect.fromLTWH(r.left, r.top, from.width, from.height);
      }
    }
    return null;
  }

  /// Place d'un adversaire pour un dos de carte (centre de son bloc, taille de la carte).
  Rect? _seatTarget(int seat, Rect from) {
    final chip = _rectOf(_key('seat:$seat'));
    if (chip == null) return null;
    return Rect.fromCenter(
      center: chip.center,
      width: from.width,
      height: from.height,
    );
  }

  /// Distribution : pioche → chaque carte de ta main, puis un dos vers chaque adversaire.
  void _distribute() {
    final from = _rectOf(_key('stock'));
    if (from == null) return;
    final g = _c.game;
    // Tour de table : à chaque tour, une carte pour chaque siège, comme une vraie donne.
    final mine = _c.hand;
    var rounds = mine.length;
    for (var seat = 1; seat < 4; seat++) {
      rounds = math.max(rounds, g.hands[seat].length);
    }
    final flights = <CardFlight>[];
    for (var k = 0; k < rounds; k++) {
      final delay = _dealStep * k;
      if (k < mine.length) {
        final card = mine[k];
        flights.add(
          CardFlight(
            from: from,
            to: () => _rectOf(_key('hand:${card.id}')),
            child: RamiCardView(card: card, width: from.width),
            delay: delay,
            landingId: card.id,
          ),
        );
      }
      for (var seat = 1; seat < 4; seat++) {
        if (k >= g.hands[seat].length) continue;
        flights.add(
          CardFlight(
            from: from,
            to: () => _seatTarget(seat, from),
            child: RamiBackView(
              width: from.width,
              asset: ramiStockBackAsset(g.stock),
            ),
            delay: delay,
          ),
        );
      }
    }
    flyAfterRender(flights);
  }

  void _drawFromStock(double width) {
    _closeScores();
    final from = _rectOf(_key('stock'));
    final before = {for (final card in _c.hand) card.id};
    _c.drawFromStock();
    if (from == null) return;
    final drawn = _c.hand.where((card) => !before.contains(card.id));
    if (drawn.isEmpty) return;
    final id = drawn.first.id;
    flyAfterRender([
      CardFlight(
        from: from,
        to: () => _rectOf(_key('hand:$id')),
        child: RamiBackView(
          width: width,
          asset: ramiBackAssetOf(drawn.first),
        ),
        landingId: id,
      ),
    ]);
  }

  Widget _piles(double width, rules.RamiState g) {
    final c = _c;
    final top = c.top;
    // Le tas garde la carte précédente pendant le vol de la nouvelle (#346).
    final shown = ramiDiscardShown(g.discard, landing);
    final covered = top != null && landing.contains(top.id);
    final discardHover = c.canPlay && _drag?.target is RamiDropDiscard;
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            PulseGlow(
              active: c.canDraw,
              child: GestureDetector(
                onTap: c.canDraw ? () => _drawFromStock(width) : null,
                child: Container(
                  key: _key('stock'),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(width * 0.14),
                    border: c.canDraw
                        ? Border.all(color: _goldColor, width: 3)
                        : null,
                  ),
                  child: RamiBackView(
                    width: width,
                    asset: ramiStockBackAsset(g.stock),
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(width: 12),
        Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              key: _key('discard'),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(width * 0.14),
                border: discardHover
                    ? Border.all(color: _goldColor, width: 3)
                    : null,
              ),
              child: shown == null
                  ? Container(
                      width: width,
                      height: width * 1.4,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(width * 0.14),
                        border: Border.all(color: Colors.white54, width: 2),
                      ),
                    )
                  : GestureDetector(
                      onTap: c.canDraw && !covered
                          ? () {
                              _closeScores();
                              c.drawFromDiscard();
                            }
                          : null,
                      child: RamiCardView(card: shown, width: width),
                    ),
            ),
          ],
        ),
      ],
    );
  }

  /// Combinaison survolée par une carte glissée (surbrillance).
  bool _isHotMeld(Object? target, String id) =>
      _c.canPlay && target is RamiDropMeld && target.id == id;

  Widget _tableCards(double meldWidth, double areaWidth, rules.RamiState g) {
    final c = _c;
    final target = _drag?.target;
    final hover = c.canPlay && target is RamiDropTable;
    final dropping = c.canPlay && _drag != null;
    // Paquets posés puis en cours de pose ; rangés pour remplir les trous du haut.
    final melds = [
      for (final meld in g.table)
        MaskedSlot(
          key: _key('meld:${meld.id}'),
          hidden: meld.cards.any((card) => landing.contains(card.id)),
          child: _MeldView(
            cards: meld.cards,
            cardWidth: meldWidth,
            hot: _isHotMeld(target, meld.id),
            eligible: c.layEligible,
            onTap: c.layEligible ? () => c.layOffSelected(meld.id) : null,
          ),
        ),
    ];
    final sizes = [
      for (final meld in g.table) meld.cards.length,
    ];
    final rowOf = ramiPackMelds(sizes, meldWidth, areaWidth) ??
        List<int>.generate(sizes.length, (i) => i);
    final ordered = [for (final i in ramiPackedOrder(rowOf)) melds[i]];
    return Container(
      key: _key('table'),
      width: double.infinity,
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: hover
            ? _goldColor.withValues(alpha: 0.2)
            : Colors.black.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color:
              hover ? _goldColor : (dropping ? Colors.white70 : Colors.white24),
          width: 2,
        ),
      ),
      child: SingleChildScrollView(
        child: Wrap(
          spacing: 3,
          runSpacing: 3,
          children: [
            if (g.table.isEmpty)
              SizedBox(
                width: double.infinity,
                child: Text(
                  c.canPlay ? Strings.ramiDropHint : Strings.ramiNoMeld,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ...ordered,
          ],
        ),
      ),
    );
  }

  /// Pied : seulement la main (#121 : plus de tri, de compteur ni de libellé de paquets).
  Widget _footer(double handWidth, rules.RamiState g) {
    final ended = g.phase == rules.RamiPhase.end;
    return Container(
      padding: const EdgeInsets.fromLTRB(8, 6, 8, 8),
      decoration: BoxDecoration(
        color: _creamColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _frameColor, width: 3),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (!ended)
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: RamiTurnBanner(
                myTurn: _c.myTurn,
                otherName: _seatNames[g.turn],
              ),
            ),
          _handRow(handWidth),
        ],
      ),
    );
  }

  List<Widget> _actions() {
    final c = _c;
    final pose = RamiActionButton(
      label: Strings.actPose,
      icon: Icons.check,
      onTap: c.pose,
      enabled: c.selectionIsMeld,
      primary: true,
    );
    final discard = RamiActionButton(
      label: Strings.actDiscard,
      icon: Icons.south,
      onTap: c.discardSelected,
      enabled: c.selected.length == 1,
      danger: true,
    );
    final returnTaken = RamiActionButton(
      label: Strings.actReturnTaken,
      icon: Icons.undo,
      onTap: c.returnTaken,
      enabled: c.canReturnTaken,
    );
    final cancel = RamiActionButton(
      label: Strings.actCancel,
      icon: Icons.close,
      onTap: c.cancel,
      enabled: c.canCancel,
    );
    if (c.canCancel) return [pose, cancel, discard];
    if (c.canReturnTaken) return [pose, returnTaken, discard];
    return [pose, discard];
  }

  /// Main du joueur (#141) : les cartes se chevauchent. La carte sélectionnée ou déplacée
  /// passe au-dessus des autres (z-order). Si la main est trop longue, le pas se resserre.
  Widget _handRow(double cardWidth) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final c = _c;
        final hand = c.displayed;
        final selected = c.selected;
        final n = hand.length;
        final maxW = constraints.maxWidth;
        // Largeur de carte : réduite seulement si même le chevauchement minimal ne tient pas.
        final minStep = 0.3;
        final fitWidth = n <= 1 ? cardWidth : maxW / (1 + minStep * (n - 1));
        final width = fitWidth < cardWidth ? fitWidth : cardWidth;
        _handCardWidth = width;
        // Pas entre deux cartes : 60 % de la largeur, resserré pour tenir sur la largeur.
        final room = n <= 1 ? 0.0 : (maxW - width) / (n - 1);
        final natural = 0.6 * width;
        final step = n <= 1 ? 0.0 : (room < natural ? room : natural);
        final total = n == 0 ? 0.0 : width + step * (n - 1);
        final height = width * 1.4 + 8;

        // Glisser au-dessus de la main : la carte quitte sa place, les autres s'écartent
        // à l'endroit où elle va atterrir.
        final dragId = _drag?.id;
        final target = _drag?.target;
        final RamiDropHand? hover =
            target is RamiDropHand && target.id != dragId ? target : null;
        final shown = hover == null
            ? hand
            : hand.where((card) => card.id != dragId).toList();
        final m = shown.length;
        var gapAt = -1;
        if (hover != null) {
          final at = shown.indexWhere((card) => card.id == hover.id);
          if (at >= 0) {
            gapAt = hover.after ? at + 1 : at;
          }
        }

        // Ordre de dessin : de gauche à droite, la carte déplacée en dernier.
        final dragAt = shown.indexWhere((card) => card.id == dragId);
        final order = ramiDrawOrder(m, dragAt >= 0 ? dragAt : null);

        return Center(
          child: SizedBox(
            key: _key('handrow'),
            width: total,
            height: height,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                for (final j in order)
                  AnimatedPositioned(
                    key: ValueKey('pos:${shown[j].id}'),
                    duration: const Duration(milliseconds: 180),
                    curve: Curves.easeOut,
                    left: j * step + ramiGapOffset(j, gapAt, step),
                    top: 0,
                    child: _handCard(
                      shown[j],
                      width,
                      selected: selected.contains(shown[j].id),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _handCard(
    rules.RamiCard card,
    double width, {
    required bool selected,
  }) {
    final dragged = _drag?.id == card.id;
    final arriving = landing.contains(card.id);
    return Listener(
      key: _key('hand:${card.id}'),
      behavior: HitTestBehavior.opaque,
      onPointerDown: (event) => _onPointerDown(event, card.id),
      onPointerMove: _onPointerMove,
      onPointerUp: _onPointerUp,
      onPointerCancel: (_) => _onPointerCancel(),
      child: Opacity(
        opacity: dragged ? 0.3 : (arriving ? 0 : 1),
        child: RamiCardView(card: card, width: width, selected: selected),
      ),
    );
  }

  /// Carte suivant le doigt pendant le glisser.
  Widget _dragOverlay(double handWidth) {
    final drag = _drag!;
    final c = _c;
    // Même taille que la carte dans la main (pas d'agrandissement pendant le glissement).
    final width = _handCardWidth > 0 ? _handCardWidth : handWidth;
    rules.RamiCard? card;
    for (final item in c.hand) {
      if (item.id == drag.id) card = item;
    }
    final groupSize = c.canPlay ? c.groupFor(drag.id).length : 0;
    return Positioned(
      left: drag.local.dx - width / 2,
      top: drag.local.dy - width * 1.4 * 0.75,
      child: IgnorePointer(
        child: Transform.rotate(
          angle: -0.09,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              if (card != null) RamiCardView(card: card, width: width),
              if (groupSize > 1)
                Positioned(
                  right: -8,
                  top: -8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: _goldColor,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.black, width: 2),
                    ),
                    child: Text(
                      '×$groupSize',
                      style: const TextStyle(
                        color: _inkColor,
                        fontSize: 11,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  /// Récapitulatif de manche, ou de partie quand un joueur atteint l'objectif.
  /// Texte de l'éclat d'annonce : qui a gagné la manche (#417).
  String _revealBurst(rules.RamiState g) {
    final winner = g.roundResult?.winner;
    if (winner == null) return 'FIN !';
    return winner == 0 ? 'GAGNÉ !' : '${_seatNames[winner]} GAGNE !';
  }

  Widget _summary(rules.RamiState g) {
    final result = g.roundResult!;
    final winner = result.winner;
    final matchWinner = g.matchWinner;
    final title = matchWinner != null
        ? (matchWinner == 0 ? Strings.victory : Strings.defeat)
        : winner == 0
            ? Strings.roundWon
            : winner == null
                ? Strings.drawExhausted
                : '${_seatNames[winner]} gagne la manche';
    final isOver = matchWinner != null;
    final badge = isOver ? Strings.matchOver : 'MANCHE ${g.round}';
    return ColoredBox(
      color: Colors.black54,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: RoundResultPanel(
            title: title,
            badge: badge,
            rows: [
              for (var seat = 0; seat < 4; seat++)
                RoundResultRow(
                  name: _seatNames[seat],
                  color: RoundResultColors.seat(seat),
                  value: signedScore(result.penalties[seat]),
                  total: '${g.scores[seat]}',
                  reason: ramiSeatReason(
                    isWinner: winner == seat,
                    opened: g.opened[seat],
                  ),
                  highlight: winner == seat,
                ),
            ],
            actions: [
              DialogButton(
                label: isOver ? Strings.replay : Strings.nextRoundButton,
                onTap: () => _deal(isOver ? _c.restart : _c.nextRound),
              ),
              if (isOver)
                TextButton(
                  onPressed: () => Navigator.of(context).maybePop(),
                  child: Text(
                    Strings.backToMenu,
                    style: const TextStyle(color: ComicPalette.ink),
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
// Widgets auxiliaires
