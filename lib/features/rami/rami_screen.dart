import 'dart:async';
import 'dart:math' as math;

import 'package:material_ui/material_ui.dart';
import 'package:flutter/foundation.dart' show ValueListenable;

import '../../core/avatars/avatar_catalog.dart';
import '../../core/avatars/game_avatars.dart';
import '../../core/layout/device_metrics.dart';
import '../../core/services/toast.dart';
import '../../game/rami.dart' as rules;
import '../menu/menu_models.dart';
import 'rami_card_view.dart';
import 'rami_discard_shown.dart';
import 'rami_meld_owner_tag.dart';
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
import '../../core/services/game_end_sequence.dart';
import '../../widgets/avatar_view.dart';
import '../../widgets/exit_guard.dart';
import '../../widgets/game_rays_background.dart';
import '../../widgets/game_scaffold.dart';
import '../../widgets/pulse_glow.dart';
import '../../core/services/saved_game_store.dart';
import '../../core/services/profile_store.dart';
import '../../widgets/resume_game.dart';
import '../../core/theme/comic_palette.dart';
import '../../widgets/dialog_button.dart';
import '../../widgets/result_dialog.dart';
import '../../widgets/round_result_panel.dart';
import '../../widgets/trophy_badge.dart';
import '../../widgets/card_motion.dart';
import '../../widgets/difficulty_chip.dart';
import '../../widgets/game_header.dart';
import '../../widgets/pressable.dart';
import 'rami_action_button.dart';
import 'rami_scores_overlay.dart';
import 'rami_seat_badge.dart';
import 'rami_seat_info.dart';

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
  // Pseudo du joueur (siège 0) : tiré du profil local, « Toi » par défaut (#838).
  String _myName = 'Toi';

  // Avatars des 4 sièges, siège 0 = joueur (issue #552).
  List<String> _avatarIds = [defaultAvatar.id, 'lion', 'tiger', 'panda'];
  final ValueListenable<bool> _adFree = AdFreeService.instance.active;
  final GameEndSequence _endSeq = GameEndSequence();
  late final GameEndWatcher _endWatcher = GameEndWatcher(
    isEnded: () => _c.game.matchWinner != null,
    onEnded: () => _endSeq.start(InterstitialService.instance.onGameFinished),
  );

  @override
  void initState() {
    super.initState();
    InterstitialService.instance.preload();
    // Faces et dos en cache avant le premier coup adverse (#1056).
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) precacheRamiCards(context);
    });
    loadGameAvatars(seats: 4).then((ids) {
      if (mounted) setState(() => _avatarIds = ids);
    });
    loadProfile().then((profile) {
      if (mounted && profile.name.trim().isNotEmpty) {
        setState(() => _myName = profile.name.trim());
      }
    });
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
    _endSeq.dispose();
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

  /// Nom affiché d'un siège : mon pseudo pour moi (siège 0), sinon le prénom de l'adversaire (#838).
  String _nameOf(int seat) => seat == 0 ? _myName : _seatNames[seat];

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
      // Cases des cartes du tapis : servent seulement aux vols, pas à la pose (#1056).
      if (entry.key.startsWith('slot:')) continue;
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

  void _onPointerDown(
    PointerDownEvent event,
    String id, {
    String? fromMeld,
    rules.RamiCard? card,
  }) {
    _closeScores();
    if (_press != null) return;
    _press = _Press(id, event.position, fromMeld: fromMeld, card: card);
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
        card: press.card,
      ),
    );
  }

  void _onPointerUp(PointerUpEvent event) {
    final press = _press;
    _press = null;
    setState(() => _drag = null);
    if (press == null) return;
    final from = press.fromMeld;
    if (press.active) {
      // Glisser-déposer : pas d'animation de vol (#944).
      _silentDrop = true;
      try {
        if (from != null) {
          _c.moveFromMeld(press.id, from, _targetAt(event.position));
        } else {
          _c.dropCard(press.id, _targetAt(event.position));
        }
      } finally {
        _silentDrop = false;
      }
    } else if (from == null) {
      _c.tap(press.id);
    }
  }

  /// Vrai pendant un glisser-déposer : le départ de la carte n'est pas animé (#944).
  bool _silentDrop = false;

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
            // Fond rayons propre au Rami (#809).
            background: const GameRaysBackground(gameName: 'Rami'),
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
          // La coupe ouvre le panneau des scores, comme dans les autres jeux (#1084).
          Pressable(
            key: _key('scoretab'),
            semanticLabel: Strings.showScores,
            pressedScale: 0.92,
            onTap: () => setState(() => _scoresOpen = !_scoresOpen),
            child: SizedBox(
              width: 48,
              height: 48,
              child: Center(
                child: TrophyBadge(
                  target: g.targetScore,
                  tint: difficultyTint(widget.difficulty),
                ),
              ),
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
        // Badges des adversaires sur le bord du tapis, sens horaire (#589).
        for (final seat in const [1, 2, 3])
          Align(
            alignment: ramiSeatAlignment(seat),
            child: Padding(
              padding: EdgeInsets.only(
                left: seat == 1 ? 4 : 0,
                top: seat == 2 ? 4 : 0,
                right: seat == 3 ? 4 : 0,
              ),
              child: RamiSeatBadge(
                key: _key('dest:$seat'),
                name: _nameOf(seat),
                cards: g.hands[seat].length,
                avatarId: _avatarIds[seat],
                avatarState: _avatarStateOf(seat, g),
                quarterTurns: ramiSeatQuarterTurns(seat),
                active: g.turn == seat && g.phase != rules.RamiPhase.end,
                onTap: () => _showSeatInfo(seat),
              ),
            ),
          ),
        // Voile qui s'estompe avec le panneau (#591) ; toucher le tapis hors du
        // panneau le referme (sans jouer le coup).
        Positioned.fill(
          child: RamiScoresScrim(
            key: _key('scrim'),
            open: _scoresOpen,
            onTap: _closeScores,
          ),
        ),
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: RamiScoresPanel(
            open: _scoresOpen,
            onClose: _closeScores,
            // Le panneau sort du tapis : même vert et même cadre (#838).
            feltColor: _feltColor,
            frameColor: _frameColor,
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

  /// Case d'un siège pour les vols : son badge sur le bord du tapis, sinon l'onglet des scores (#532).
  Rect? _seatRect(int seat) {
    return _rectOf(_key('dest:$seat')) ?? _rectOf(_key('scoretab'));
  }

  /// État de l'avatar d'un siège (issue #552) : neutre pendant la manche,
  /// heureux pour le gagnant et fâché pour les autres en fin de manche.
  AvatarState _avatarStateOf(int seat, rules.RamiState g) {
    final winner = g.roundResult?.winner;
    final winners = winner == null ? <int>[] : <int>[winner];
    return gameAvatarState(
      seat: seat,
      finished: g.phase == rules.RamiPhase.end,
      winners: winners,
    );
  }

  /// Score d'un siège, avec son avatar (issue #552).
  Widget _chipOf(int seat, rules.RamiState g) {
    return _PlayerChip(
      seat: seat,
      game: g,
      avatarId: _avatarIds[seat],
      avatarState: _avatarStateOf(seat, g),
      onAvatarTap: () => _showSeatInfo(seat),
    );
  }

  /// Popup d'un siège : pseudo, score et cartes en main (#887).
  void _showSeatInfo(int seat) {
    final g = _c.game;
    unawaited(
      RamiSeatInfo.show(
        context,
        name: _nameOf(seat),
        score: g.scores[seat],
        cards: g.hands[seat].length,
        avatarId: _avatarIds[seat],
        avatarState: _avatarStateOf(seat, g),
      ),
    );
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
                child: _chipOf(seat, g),
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
        // Pas de contour doré sur le tapis quand c'est mon tour (#952) :
        // l'indication du tour reste sur l'avatar de mon siège.
        border: Border.all(
          color: _frameColor,
          width: 6,
        ),
        boxShadow: const [
          BoxShadow(color: _frameColor, spreadRadius: 3, offset: Offset(0, 8)),
        ],
      ),
      child: Column(
        children: [
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
          // Pioche et défausse à gauche, mon avatar à droite de la défausse (#861),
          // puis les boutons d'action sur la même ligne.
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
                Padding(
                  padding: const EdgeInsets.only(left: 8, bottom: 2),
                  child: RamiSeatBadge(
                    key: _key('dest:0'),
                    name: _nameOf(0),
                    cards: g.hands[0].length,
                    avatarId: _avatarIds[0],
                    avatarState: _avatarStateOf(0, g),
                    active: _c.myTurn,
                    onTap: () => _showSeatInfo(0),
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
          // Ma main est posée dans le même tapis : un seul grand tapis (#838).
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: _handRow(handWidth),
          ),
        ],
      ),
    );
  }

  /// Boutons d'action de la table pendant la phase de pose : le bouton rouge de défausse
  /// reste visible (#885), désactivé tant qu'une seule carte n'est pas sélectionnée.
  Widget _contextActions(rules.RamiState g) {
    final c = _c;
    if (!c.canPlay) return const SizedBox.shrink();
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
    if (ramiShouldFlyLeaving(
      silentDrop: _silentDrop,
      hasLeaving: leaving.isNotEmpty,
    )) {
      _flyLeaving(leaving);
    }
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
    final moves = ramiAiMoves(prev, next);
    // Recyclage (#646) : la pioche part seulement quand la défausse est revenue en pioche.
    final recycleCount = moves.contains(RamiAiMove.recycle)
        ? ramiRecycleFlightCount(prev.discard.length)
        : 0;
    final drawDelay = ramiRecycleTotal(recycleCount);
    for (final move in moves) {
      switch (move) {
        case RamiAiMove.recycle:
          for (var i = 0; i < recycleCount; i++) {
            flights.add(_recycleFlight(pile, next.stock, i));
          }
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
            delay: drawDelay,
            duration: ramiAiFlightDuration,
            curve: Curves.easeOutCubic,
          ));
        case RamiAiMove.takeDiscard:
          if (prev.discard.isEmpty) break;
          final top = prev.discard.last;
          flights.add(CardFlight(
            from: pile,
            to: () => _seatTarget(seat, pile),
            child: RamiCardView(card: top, width: pile.width),
            duration: ramiAiFlightDuration,
            curve: Curves.easeOutCubic,
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
            curve: Curves.easeOutCubic,
          ));
      }
    }
    // Paquets posés par l'adversaire (#878) : un paquet après l'autre (#943), carte par carte.
    final packs = ramiNewTablePacks(prev, next);
    final delays = ramiPackDelays(
      [for (final pack in packs) pack.length],
      flight: ramiAiFlightDuration,
    );
    var posed = 0;
    for (final pack in packs) {
      for (final card in pack) {
        final from = Rect.fromCenter(
          center: chip.center,
          width: pile.width,
          height: pile.height,
        );
        flights.add(CardFlight(
          from: from,
          to: () => _targetFor(card.id, from),
          child: RamiCardView(card: card, width: pile.width),
          delay: delays[posed++],
          duration: ramiAiFlightDuration,
          landingId: card.id,
          curve: Curves.easeOutCubic,
        ));
      }
    }
    if (flights.isNotEmpty) flyAfterRender(flights);
  }

  /// Vol des cartes qui quittent la main vers leur destination (défausse, combinaison, tapis).
  /// Un paquet posé part après le précédent, carte par carte (#592, #943).
  void _flyLeaving(List<rules.RamiCard> leaving) {
    final flights = <CardFlight>[];
    final packs = ramiPacksAmong(
      _c.game,
      {for (final card in leaving) card.id},
    );
    final delays = ramiPackDelays([for (final pack in packs) pack.length]);
    final delayOf = <String, Duration>{};
    var posed = 0;
    for (final pack in packs) {
      for (final card in pack) {
        delayOf[card.id] = delays[posed++];
      }
    }
    for (final card in leaving) {
      final from = _rectOf(_key('hand:${card.id}'));
      if (from == null) continue;
      final posedDelay = delayOf[card.id];
      flights.add(
        CardFlight(
          from: from,
          to: () => _targetFor(card.id, from),
          child: RamiCardView(card: card, width: from.width),
          delay: posedDelay ?? _flightStagger * flights.length,
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
      final index = meld.cards.indexWhere((card) => card.id == id);
      if (index >= 0) {
        // Case réelle de la carte : sa taille est celle du tapis, pas celle de la pioche (#1056).
        final slot = _rectOf(_key('slot:$id'));
        if (slot != null) return slot;
        final r = _rectOf(_key('meld:${meld.id}'));
        if (r == null) return null;
        // Chaque carte vise sa place dans le paquet, pas le paquet entier (#592).
        return Rect.fromLTWH(
          ramiMeldSlotLeft(r.left, from.width, index),
          r.top,
          from.width,
          from.height,
        );
      }
    }
    return null;
  }

  /// Place d'un adversaire pour un dos de carte (centre de son bloc, taille de la carte).
  Rect? _seatTarget(int seat, Rect from) {
    final chip = _seatRect(seat);
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
    // Tour de table : chaque carte part vers sa place, dans l'ordre droite, haut, gauche, moi (#532).
    final mine = _c.hand;
    var rounds = mine.length;
    for (var seat = 1; seat < 4; seat++) {
      rounds = math.max(rounds, g.hands[seat].length);
    }
    final flights = <CardFlight>[];
    for (var k = 0; k < rounds; k++) {
      for (var i = 0; i < ramiDealSeatOrder.length; i++) {
        final seat = ramiDealSeatOrder[i];
        // Un tour par carte, et dans le tour un décalage court : droite, haut, gauche, moi.
        final delay = ramiDealStep * k + ramiDealSeatStagger * i;
        if (seat == 0) {
          if (k >= mine.length) continue;
          final card = mine[k];
          flights.add(
            CardFlight(
              from: from,
              to: () => _rectOf(_key('hand:${card.id}')),
              child: RamiCardView(card: card, width: from.width),
              delay: delay,
              duration: ramiDealFlight,
              landingId: card.id,
            ),
          );
        } else {
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
              duration: ramiDealFlight,
            ),
          );
        }
      }
    }
    flyAfterRender(flights);
  }

  void _drawFromStock(double width) {
    _closeScores();
    final from = _rectOf(_key('stock'));
    final pile = _rectOf(_key('discard'));
    final before = {for (final card in _c.hand) card.id};
    final prevRecycles = _c.game.recycles;
    final discardSize = _c.game.discard.length;
    _c.drawFromStock();
    if (from == null) return;
    // Recyclage (#646) : la défausse vole vers la pioche, puis la carte part vers la main.
    final recycled = _c.game.recycles > prevRecycles;
    final recycleCount = recycled ? ramiRecycleFlightCount(discardSize) : 0;
    final flights = <CardFlight>[];
    if (pile != null) {
      for (var i = 0; i < recycleCount; i++) {
        flights.add(_recycleFlight(pile, _c.game.stock, i));
      }
    }
    final drawn = _c.hand.where((card) => !before.contains(card.id));
    if (drawn.isNotEmpty) {
      final id = drawn.first.id;
      flights.add(CardFlight(
        from: from,
        to: () => _rectOf(_key('hand:$id')),
        child: RamiBackView(
          width: width,
          asset: ramiBackAssetOf(drawn.first),
        ),
        delay: ramiRecycleTotal(recycleCount),
        landingId: id,
      ));
    }
    flyAfterRender(flights);
  }

  /// Une carte de la défausse qui revient dans la pioche (#646), décalée de [index] pas.
  CardFlight _recycleFlight(Rect pile, List<rules.RamiCard> stock, int index) {
    return CardFlight(
      from: pile,
      to: () => _rectOf(_key('stock')),
      child: RamiBackView(
        width: pile.width,
        asset: ramiStockBackAsset(stock),
      ),
      delay: ramiRecycleStagger * index,
      duration: ramiRecycleFlight,
    );
  }

  Widget _piles(double width, rules.RamiState g) {
    final c = _c;
    final top = c.top;
    // Le tas garde la carte précédente pendant le vol de la nouvelle (#346).
    final shown = ramiDiscardShown(g.discard, landing);
    final covered = top != null && landing.contains(top.id);
    final discardHover = c.canPlay && _drag?.target is RamiDropDiscard;
    final discardLit = discardHover || _discardFlash;
    final VoidCallback? onDiscardTap;
    if (c.canDraw && !covered) {
      onDiscardTap = () {
        _closeScores();
        c.drawFromDiscard();
      };
    } else {
      onDiscardTap = c.canPlay ? _onDiscardTap : null;
    }
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              clipBehavior: Clip.none,
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
                border:
                    discardLit ? Border.all(color: _goldColor, width: 3) : null,
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
                      key: const ValueKey('discard_tap'),
                      onTap: onDiscardTap,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          AnimatedScale(
                            scale: _discardFlash ? 0.94 : 1,
                            duration: const Duration(milliseconds: 120),
                            child: RamiCardView(card: shown, width: width),
                          ),
                          // Icône : la défausse est la cible de la carte sélectionnée (#906).
                          if (c.canPlay && c.selected.length == 1)
                            IgnorePointer(
                              child: Container(
                                key: _key('discard_hint'),
                                width: width * 0.42,
                                height: width * 0.42,
                                decoration: BoxDecoration(
                                  color: _goldColor,
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: _frameColor,
                                    width: 2,
                                  ),
                                ),
                                child: Icon(
                                  Icons.south,
                                  color: _frameColor,
                                  size: width * 0.3,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
            ),
          ],
        ),
        // Bouclier du seuil d'ouverture : à droite de la défausse, au même niveau
        // (le bas), lisible en permanence, y compris après l'ouverture (#880, #886).
        const SizedBox(width: 12),
        RamiMinOpeningShield(
          key: _key('shield'),
          minimum: rules.minOpening(g),
          label: tf(
            'ramiMinOpen',
            {'n': '${rules.minOpening(g)}'},
          ),
        ),
      ],
    );
  }

  /// Retour visuel bref quand la défausse est touchée (#885).
  bool _discardFlash = false;

  void _onDiscardTap() {
    _closeScores();
    setState(() => _discardFlash = true);
    Timer(const Duration(milliseconds: 180), () {
      if (mounted) setState(() => _discardFlash = false);
    });
    _c.discardSelected();
  }

  /// Avatar du propriétaire d'un paquet, ou null hors siège (#942).
  String? _ownerAvatar(int owner) =>
      owner >= 0 && owner < _avatarIds.length ? _avatarIds[owner] : null;

  AvatarState _ownerAvatarState(int owner, rules.RamiState g) =>
      owner >= 0 && owner < 4 ? _avatarStateOf(owner, g) : AvatarState.neutral;

  /// Combinaison survolée par une carte glissée (surbrillance).
  bool _isHotMeld(Object? target, String id) =>
      _c.canPlay && target is RamiDropMeld && target.id == id;

  Widget _tableCards(double meldWidth, double areaWidth, rules.RamiState g) {
    final c = _c;
    final target = _drag?.target;
    final hover = c.canPlay && target is RamiDropTable;
    // Tapis armé dès la sélection (tap), pas seulement pendant un glisser.
    final dropping = ramiTableArmed(
      canPlay: c.canPlay,
      dragging: _drag != null,
      selectedCount: c.selected.length,
    );
    // Paquets posés puis en cours de pose ; rangés pour remplir les trous du haut.
    final melds = [
      for (final meld in g.table)
        _MeldView(
          key: _key('meld:${meld.id}'),
          cards: meld.cards,
          cardWidth: meldWidth,
          slotKey: (id) => _key('slot:$id'),
          owner: meld.owner,
          avatarId: _ownerAvatar(meld.owner),
          avatarState: _ownerAvatarState(meld.owner, g),
          hot: _isHotMeld(target, meld.id),
          eligible: c.layEligible,
          arriving: landing,
          onTap: c.layEligible ? () => c.layOffSelected(meld.id) : null,
          onLongPress: c.takeBackAction(meld.id),
          // Glisser une carte d'un paquet du tour vers la main ou un autre paquet (#898).
          onCardPointerDown: (i, event) {
            final card = meld.cards[i];
            if (card.isJoker) return;
            _onPointerDown(event, card.id, fromMeld: meld.id, card: card);
          },
        ),
    ];
    final sizes = [
      for (final meld in g.table) meld.cards.length,
    ];
    final rowOf = ramiPackMelds(sizes, meldWidth, areaWidth) ??
        List<int>.generate(sizes.length, (i) => i);
    final ordered = [for (final i in ramiPackedOrder(rowOf)) melds[i]];
    final table = Container(
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
            // Paquet en cours : cartes glissées sur le tapis, pas encore valides (#874).
            if (c.draftCards.isNotEmpty)
              _MeldView(
                cards: c.draftCards,
                cardWidth: meldWidth,
                owner: 0,
                avatarId: _ownerAvatar(0),
                onTap: () => c.removeFromDraft(c.draftIds.last),
              ),
          ],
        ),
      ),
    );
    // Sélection valide : un tap sur le tapis la pose, sans aperçu avant la pose (#972).
    return GestureDetector(
      onTap: c.canPoseSelection ? c.pose : null,
      child: table,
    );
  }

  /// Pied : seulement la main (#121 : plus de tri, de compteur ni de libellé de paquets).
  /// Main posée sur le tapis (#831) : fond vert, pas crème.
  List<Widget> _actions() {
    final c = _c;
    // Pas de bouton « Poser » : un paquet se forme en glissant les cartes sur le tapis (#874).
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
      iconOnly: true,
    );
    if (c.canCancel) return [cancel];
    if (c.canReturnTaken) return [returnTaken];
    return const [];
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
        // Taille de carte fixe (#896) : seul le chevauchement se resserre.
        final width = cardWidth;
        _handCardWidth = width;
        final step = ramiHandStep(n, width, maxW);
        final total = n == 0 ? 0.0 : width + step * (n - 1);
        // Place réservée au-dessus de la main pour la carte sélectionnée qui monte (#906).
        final lift = width * ramiSelectLift;
        final height = width * 1.4 + 8 + lift;
        // Main toujours centrée dans la largeur disponible (#922).
        final pad = (maxW - total) / 2;

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

        // Pendant un dépôt, la main se remet en place pour ouvrir un vrai emplacement :
        // l'ouverture est retirée de la largeur, puis le pas se resserre pour la tenir.
        final gap = gapAt >= 0 ? width * ramiGapRatio : 0.0;
        final spreadStep = ramiHandStep(m, width, maxW - gap);
        final spreadTotal = m == 0 ? 0.0 : width + spreadStep * (m - 1) + gap;
        final spreadPad = (maxW - spreadTotal) / 2;

        // Ordre de dessin : de gauche à droite, la carte déplacée en dernier.
        final dragAt = shown.indexWhere((card) => card.id == dragId);
        final order = ramiDrawOrder(m, dragAt >= 0 ? dragAt : null);

        // Jamais de défilement : la main tient toujours sur la largeur (#922).
        return SizedBox(
          key: _key('handrow'),
          width: maxW,
          height: height,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              for (final j in order)
                AnimatedPositioned(
                  key: ValueKey('pos:${shown[j].id}'),
                  duration: const Duration(milliseconds: 180),
                  curve: Curves.easeOut,
                  left: (gapAt >= 0 ? spreadPad : pad) +
                      j * (gapAt >= 0 ? spreadStep : step) +
                      ramiGapOffset(j, gapAt, width),
                  top: lift,
                  child: _handCard(
                    shown[j],
                    width,
                    selected: selected.contains(shown[j].id),
                  ),
                ),
            ],
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
    rules.RamiCard? card = drag.card;
    for (final item in c.hand) {
      if (item.id == drag.id) card = item;
    }
    // Pas de compteur du paquet pendant le glisser depuis la main (#889).
    return Positioned(
      left: drag.local.dx - width / 2,
      top: drag.local.dy - width * 1.4 * 0.75,
      child: IgnorePointer(
        child: Transform.rotate(
          angle: -0.09,
          child: card == null
              ? const SizedBox.shrink()
              : RamiCardView(card: card, width: width),
        ),
      ),
    );
  }

  /// Récapitulatif de manche, ou de partie quand un joueur atteint l'objectif.
  /// Texte de l'éclat d'annonce : qui a gagné la manche (#417).
  String _revealBurst(rules.RamiState g) {
    final winner = g.roundResult?.winner;
    if (winner == null) return 'FIN !';
    return winner == 0 ? 'GAGNÉ !' : '${_nameOf(winner)} GAGNE !';
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
                : '${_nameOf(winner)} gagne la manche';
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
            won: isOver ? matchWinner == 0 : null,
            revealed: isOver ? _endSeq.revealed : null,
            rows: [
              for (var seat = 0; seat < 4; seat++)
                RoundResultRow(
                  name: _nameOf(seat),
                  color: RoundResultColors.seat(seat),
                  avatarId: _avatarIds[seat],
                  avatarState: _avatarStateOf(seat, g),
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
