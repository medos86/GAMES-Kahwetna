import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:material_ui/material_ui.dart';

import '../../core/avatars/avatar_catalog.dart';
import '../../core/avatars/game_avatars.dart';
import '../../core/reactions/reaction_mood.dart';
import '../../core/services/ad_free_service.dart';
import '../../core/services/interstitial_service.dart';
import '../../widgets/reaction_sticker.dart';
import '../../widgets/turn_avatar.dart';
import '../../widgets/game_rays_background.dart';
import '../../core/i18n/app_language.dart';
import '../../core/strings.dart';
import '../../core/theme/game_style.dart';
import '../../core/theme/scoba_palette.dart';
import '../../core/theme/comic_palette.dart';
import '../../game/chkobba.dart';
import '../../game/common.dart';
import '../menu/menu_models.dart';
import 'chkobba_card_face.dart';
import 'chkobba_controller.dart';
import 'chkobba_opponent_name.dart';
import 'chkobba_table.dart';
import 'chkobba_table_layout.dart';
import '../../widgets/exit_guard.dart';
import '../../widgets/round_result_panel.dart';
import '../../widgets/game_scaffold.dart';
import '../../core/services/saved_game_store.dart';
import '../../core/services/profile_store.dart';
import '../../widgets/resume_game.dart';
import '../../widgets/difficulty_chip.dart';
import '../../widgets/trophy_badge.dart';
import '../../widgets/game_header.dart';
import '../../widgets/card_flight.dart';
import '../../widgets/card_motion.dart';

part 'chkobba_parts/chkobba_scoreboard.dart';
part 'chkobba_parts/chkobba_table_parts.dart';
part 'chkobba_parts/chkobba_round_cards.dart';
part 'chkobba_parts/chkobba_seat_row.dart';

/// Nom du joueur tant que le profil n'est pas lu, ou s'il est vide (#766).
const _fallbackPlayerName = 'Joueur';

/// Écran de jeu de la Chkobba, fidèle à GameScreen.tsx : scores, pioche, tapis, mains,
/// bannière de tour, Haya, choix de prise et récapitulatif de manche.
class ChkobbaScreen extends StatefulWidget {
  const ChkobbaScreen({
    super.key,
    required this.difficulty,
    required this.targetScore,
    this.demoChoice = false,
    this.initialState,
  });

  /// État de départ imposé (tests) : remplace la donne aléatoire.
  final ChkobbaState? initialState;

  final Difficulty difficulty;
  final int targetScore;

  /// Donne fixe du dialogue de choix de prise (`?demo=choice`). Sans effet hors debug.
  final bool demoChoice;

  @override
  State<ChkobbaScreen> createState() => _ChkobbaScreenState();
}

class _ChkobbaScreenState extends State<ChkobbaScreen>
    with CardMotionMixin<ChkobbaScreen> {
  late final ChkobbaController _controller;

  /// Avatars [joueur, adversaire] (issue #551) ; remplacés une fois le profil lu.
  List<String> _avatarIds = [defaultAvatar.id, 'lion'];

  /// Pseudo du joueur (profil) et nom tiré au hasard pour l'adversaire (#766).
  String _playerName = _fallbackPlayerName;
  final String _opponentName = pickOpponentName(math.Random());

  @override
  void initState() {
    super.initState();
    loadGameAvatars(seats: 2).then((ids) {
      if (mounted) setState(() => _avatarIds = ids);
    });
    loadProfile().then((profile) {
      final name = profile.name.trim();
      if (mounted && name.isNotEmpty) setState(() => _playerName = name);
    });
    _controller = ChkobbaController(
      store: const SharedPreferencesSavedGameStore(),
      targetScore: widget.targetScore,
      level: _levelFor(widget.difficulty),
      initialState: widget.initialState ??
          (kDebugMode && widget.demoChoice
              ? chkobbaDemoChoiceState(targetScore: widget.targetScore)
              : null),
    );
    _snapshotCaptures();
    // Issue #471 : l'interstitiel entre deux parties est préchargé.
    InterstitialService.instance.preload();
    _controller.addListener(_onChanged);
    _controller.restore().then((_) {
      _snapshotCaptures();
      _ready = true;
      // Partie neuve : la donne initiale est animée.
      if (!_restored) _distribute();
      if (mounted) offerResume(context, _controller);
    });
  }

  @override
  void dispose() {
    _controller.removeListener(_onChanged);
    _controller.dispose();
    super.dispose();
  }

  // -------------------------------------------------------------------------
  // Captures animées (#238) : les cartes prises volent du tapis vers le tas.
  // -------------------------------------------------------------------------

  final Map<String, GlobalKey> _keys = {};

  /// Carte de la main tenue par le doigt : ses prises s'allument sur le tapis (#923).
  String? _previewId;

  void _setPreview(String? cardId) {
    if (_previewId == cardId) return;
    setState(() => _previewId = cardId);
  }

  GlobalKey _key(String name) => _keys.putIfAbsent(name, () => GlobalKey());

  static const _stagger = Duration(milliseconds: 60);
  bool _ready = false;
  bool _restored = false;
  bool _dealPending = false;
  ChkobbaState? _lastGame;
  List<ChkobbaCard> _lastTable = const [];
  List<ChkobbaCard> _lastPlayer = const [];
  List<ChkobbaCard> _lastOpp = const [];
  Map<Player, int> _lastWon = const {};

  void _snapshotCaptures() {
    final game = _controller.game;
    _lastGame = game;
    _lastTable = game.table;
    _lastPlayer = game.hands[Player.player] ?? const [];
    _lastOpp = game.hands[Player.opponent] ?? const [];
    _lastWon = {for (final p in Player.values) p: game.won[p]?.length ?? 0};
  }

  /// Lance une action qui donne une nouvelle donne : la distribution est animée.
  void _deal(VoidCallback action) {
    _dealPending = true;
    action();
    _dealPending = false;
  }

  static const _capturePause = Duration(milliseconds: 320);

  /// Durée de la pose de la carte jouée sur la carte prise (#394).
  static const _landDuration = Duration(milliseconds: 300);

  /// Cartes prises encore en vol vers le tas : le compteur ne les compte pas (#354).
  final Set<String> _capturing = {};

  /// Zone du tableau de score : les cartes qui vont au tas s'y enfoncent (#357).
  Rect? _scoreboardRect() => rectOfKey(_key('scoreboard'));

  void _release(String id) {
    if (!mounted) return;
    setState(() => _capturing.remove(id));
  }

  /// Carte jouée : pose sur la carte prise, puis vers le tas (#394).
  Future<void> _landThenPile(
    ChkobbaCard card,
    Rect from,
    Rect landing,
    GlobalKey winnerKey,
  ) async {
    try {
      await flyCard(
        context: context,
        from: from,
        to: () => landing,
        child: ChkobbaCardFace(card: card),
        duration: _landDuration,
      );
      await flyCard(
        context: context,
        from: landing,
        to: () => rectOfKey(winnerKey),
        child: ChkobbaCardFace(card: card),
        occluder: _scoreboardRect,
      );
    } finally {
      _release(card.id);
    }
  }

  /// Tout mouvement de carte : cartes jouées, captures, donne (#238).
  /// Une capture se lit en deux temps : la carte se pose sur le tapis,
  /// puis la carte et les cartes prises rejoignent le tas du gagnant.
  bool _endNotified = false;

  void _onChanged() {
    final game = _controller.game;
    if (identical(game, _lastGame)) return;
    if (!_ready) {
      _restored = true;
      return;
    }
    // Issue #471 : une partie terminée déclenche la politique d'interstitiel, une fois.
    if (game.winner == null) {
      _endNotified = false;
    } else if (!_endNotified) {
      _endNotified = true;
      unawaited(InterstitialService.instance.onGameFinished());
    }
    final beforeTable = _lastTable;
    final beforeWon = _lastWon;
    final beforePlayer = _lastPlayer;
    final beforeOpp = _lastOpp;
    _snapshotCaptures();

    Player? taker;
    for (final p in Player.values) {
      if ((game.won[p]?.length ?? 0) > (beforeWon[p] ?? 0)) taker = p;
    }
    final winnerKey = taker == null ? null : _key('won:${taker.name}');
    bool wonNow(String id) =>
        taker != null && (game.won[taker]?.any((c) => c.id == id) ?? false);

    // Cartes prises : la carte jouée se pose sur la carte du tapis (#394),
    // puis cartes jouées et cartes prises rejoignent le tas du gagnant.
    final gone = [
      for (final card in beforeTable)
        if (game.table.every((t) => t.id != card.id)) card,
    ];
    // Case de la première carte prise : là où la carte jouée se pose.
    final landing =
        gone.isEmpty ? null : rectOfKey(_key('tbl:${gone.first.id}'));
    if (winnerKey != null) {
      for (final card in gone) {
        final from = rectOfKey(_key('tbl:${card.id}'));
        if (from == null) continue;
        _capturing.add(card.id);
        unawaited(
          flyCard(
            context: context,
            from: from,
            to: () => rectOfKey(winnerKey),
            child: ChkobbaCardFace(card: card),
            delay: landing == null ? _capturePause : _landDuration,
            hold: true,
            occluder: _scoreboardRect,
          ).whenComplete(() => _release(card.id)),
        );
      }
    }

    // Cartes jouées (joueur, puis adversaire) : depuis la main ou la zone adverse.
    final stillPlayer = {for (final c in game.hands[Player.player]!) c.id};
    final stillOpp = {for (final c in game.hands[Player.opponent]!) c.id};
    final leaving = [
      for (final c in beforePlayer)
        if (!stillPlayer.contains(c.id)) (c, _key('hand:${c.id}')),
      for (final c in beforeOpp)
        if (!stillOpp.contains(c.id)) (c, _key('opp:${c.id}')),
    ];
    final captures = [
      for (final (card, key) in leaving)
        if (wonNow(card.id) && rectOfKey(key) != null) (card, key),
    ];
    // Position de départ lue maintenant : après le rendu la carte a quitté sa place.
    final plain = <(ChkobbaCard, Rect)>[];
    for (final (card, key) in leaving) {
      final from = rectOfKey(key);
      if (!wonNow(card.id) && from != null) plain.add((card, from));
    }

    for (final (card, key) in captures) {
      final from = rectOfKey(key);
      if (from == null || winnerKey == null) continue;
      _capturing.add(card.id);
      if (landing == null) {
        // Rien à poser : la carte jouée rejoint directement le tas.
        unawaited(
          flyCard(
            context: context,
            from: from,
            to: () => rectOfKey(winnerKey),
            child: ChkobbaCardFace(card: card),
            occluder: _scoreboardRect,
          ).whenComplete(() => _release(card.id)),
        );
        continue;
      }
      unawaited(_landThenPile(card, from, landing, winnerKey));
    }

    // Cartes posées sans capture : vers leur case du tapis (après le rendu).
    if (plain.isNotEmpty) {
      final flights = <CardFlight>[];
      for (final (card, from) in plain) {
        final id = card.id;
        flights.add(
          CardFlight(
            from: from,
            to: () => _targetFor(id),
            child: ChkobbaCardFace(card: card),
            delay: _stagger * flights.length,
            landingId: id,
          ),
        );
      }
      flyAfterRender(flights);
    }

    // Nouvelle donne (bouton ou redonne automatique en cours de manche) : la distribution est animée.
    final dealt = _controller.takeDeal();
    if (_dealPending || dealt) _distribute();
  }

  /// Destination exacte d'une carte : sa case du tapis, ou le tas de celui qui l'a prise.
  Rect? _targetFor(String id) {
    final game = _controller.game;
    if (game.table.any((c) => c.id == id)) {
      return rectOfKey(_key('tbl:$id'));
    }
    for (final p in Player.values) {
      if (game.won[p]?.any((c) => c.id == id) ?? false) {
        return rectOfKey(_key('won:${p.name}'));
      }
    }
    return null;
  }

  /// Donne : la pioche envoie les cartes du joueur, puis un dos vers l'adversaire.
  void _distribute() {
    final from = rectOfKey(_key('deck'));
    if (from == null) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final game = _controller.game;
      var i = 0;
      for (final card in game.hands[Player.player]!) {
        if (rectOfKey(_key('hand:${card.id}')) == null) continue;
        unawaited(
          flyCard(
            context: context,
            from: from,
            to: () => rectOfKey(_key('hand:${card.id}')),
            child: ChkobbaCardFace(card: card),
            delay: _stagger * i,
          ),
        );
        i++;
      }
      for (final card in game.hands[Player.opponent]!) {
        if (rectOfKey(_key('opp:${card.id}')) == null) continue;
        unawaited(
          flyCard(
            context: context,
            from: from,
            to: () => rectOfKey(_key('opp:${card.id}')),
            child: const ChkobbaCardBack(),
            delay: _stagger * i,
          ),
        );
        i++;
      }
    });
  }

  static ChkobbaAiLevel _levelFor(Difficulty d) =>
      aiLevelFor(ChkobbaAiLevel.values, d);

  Future<void> _onPlayerCard(String cardId) async {
    _controller.tapPlayerCard(cardId);
    final pending = _controller.pendingCapture;
    if (pending == null) return;
    final option = await showModalBottomSheet<List<ChkobbaCard>>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => _CapturePicker(options: pending.options),
    );
    if (!mounted) return;
    if (option == null) {
      _controller.cancelPendingCapture();
    } else {
      _controller.choosePendingCapture(option);
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final columns = size.width < 600 ? 4 : 6;
    // Hauteur de carte : 11 % de l'écran, bornée pour laisser la place au tapis.
    final cardHeight = math.min(math.max(size.height * 0.11, 56.0), 92.0);
    // Fond rayons propre à la Chkobba (#805).
    const background = GameRaysBackground(gameName: 'Chkobba');

    return ListenableBuilder(
      listenable: Listenable.merge([
        _controller,
        AdFreeService.instance.active,
      ]),
      builder: (context, _) => ExitGuard(
        active: _controller.game.winner == null,
        child: GameScaffold(
          showAd: !AdFreeService.instance.active.value,
          background: background,
          child: _buildBoard(context, columns, cardHeight),
        ),
      ),
    );
  }

  Widget _buildBoard(BuildContext context, int columns, double cardHeight) {
    final game = _controller.game;
    final summary = _controller.roundSummary;
    final over = summary != null;
    final revealed = _controller.revealedCardId;
    final hayaBy = _controller.hayaBy;
    final canPlay = !over && game.winner == null && game.turn == Player.player;
    final cardWidth = cardHeight * 0.7;
    // Main du joueur agrandie (#chkobba-hand) : lisible sans toucher au tapis.
    final playerHandHeight = chkobbaHandCardHeight(
      MediaQuery.sizeOf(context).height,
    );
    final style = GameStyle.current;

    // Emplacements du tapis : au moins 12, multiple du nombre de colonnes (comme TABLE_MIN_SLOTS).
    // Cartes posées au centre du tapis : chaque carte garde sa place tant qu'elle est sur la table.
    final assigned = _controller.tableSlots();
    final used = assigned.values.fold<int>(
      0,
      (max, index) => math.max(max, index + 1),
    );
    final slotCount = _roundUp(math.max(12, used), columns);
    final slots = List<Widget?>.filled(slotCount, null);
    // Cartes du tapis que la carte tenue peut prendre : elles s'allument (#923).
    final targets = chkobbaCaptureTargetIds(game, Player.player, _previewId);
    for (final card in game.table) {
      final index = assigned[card.id]!;
      final lit = targets.contains(card.id);
      slots[index] = MaskedSlot(
        key: _key('tbl:${card.id}'),
        hidden: landing.contains(card.id),
        child: ChkobbaCardFace(card: card, highlight: lit),
      );
    }

    // Largeur des coins latéraux (#766) : avatar, score et pile tiennent dans cette bande.
    final corner = _cornerWidth(MediaQuery.sizeOf(context).width);
    final Widget centre = game.winner != null && !over
        ? _FinalCard(state: game)
        : ChkobbaTable(key: _key('table'), cards: slots, columns: columns);

    return Stack(
      children: [
        Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 6, 10, 0),
              child: GameHeader(
                unit: 14,
                onMenu: () => Navigator.of(context).maybePop(),
                center: const Expanded(child: SizedBox()),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (game.winner != null)
                      IconButton(
                        tooltip: t('newGame'),
                        onPressed: () => _deal(_controller.startNewGame),
                        icon: const Icon(Icons.refresh, color: Colors.white),
                      ),
                    TrophyBadge(
                      target: game.targetScore,
                      size: 44,
                      tint: difficultyTint(widget.difficulty),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: Container(
                key: const ValueKey('chkobba-felt'),
                // Contour extérieur marron BD (#766) : seul le tapis reste vert.
                margin: const EdgeInsets.fromLTRB(4, 6, 4, 6),
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: ComicPalette.tableWood,
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(color: Colors.black, width: 3),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: ColoredBox(
                    color: ScobaPalette.tapisVert,
                    child: Column(
                      children: [
                        const SizedBox(height: 6),
                        // Rangée de l'adversaire : pile et pioche à gauche, main, avatar à droite (#800).
                        _SeatRow(
                          corner: corner,
                          left: _pileLane(
                            game: game,
                            owner: Player.opponent,
                            color: ScobaPalette.redText,
                            showDeck: game.starter == Player.opponent,
                            deckAbove: true,
                          ),
                          hand: KeyedSubtree(
                            key: _key('opp-hand'),
                            child: _Hand(
                              cards: game.hands[Player.opponent]!,
                              width: cardWidth * 0.8,
                              height: cardHeight * 0.8,
                              builder: (card) => _opponentCard(card, revealed),
                            ),
                          ),
                          right: _avatarLane(
                            game: game,
                            player: Player.opponent,
                            name: _opponentName,
                            color: ScobaPalette.redText,
                          ),
                        ),
                        // Tapis : toute la hauteur libre entre les deux rangées (#800).
                        Expanded(
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 4,
                                  vertical: 4,
                                ),
                                child: Center(child: centre),
                              ),
                              if (_controller.chkobbaBy != null)
                                Positioned.fill(
                                  child: Center(
                                    child: ChkobbaBanner(
                                      text: 'Chkobba !',
                                      colors: style.chkobbaGradient,
                                      angle: -0.1,
                                    ),
                                  ),
                                ),
                              if (hayaBy != null)
                                Positioned(
                                  top: 6,
                                  child: ChkobbaBanner(
                                    text: '♦ 7AYA !',
                                    colors: style.ayaGradient,
                                    angle: 0.09,
                                    burstSize: 110,
                                  ),
                                ),
                            ],
                          ),
                        ),
                        // Rangée du joueur : avatar à gauche, main, pile et pioche à droite (#800).
                        _SeatRow(
                          corner: corner,
                          left: _avatarLane(
                            game: game,
                            player: Player.player,
                            name: _playerName,
                            color: ScobaPalette.blueText,
                          ),
                          hand: _Hand(
                            cards: game.hands[Player.player]!,
                            width: playerHandHeight * 0.7,
                            height: playerHandHeight,
                            builder: (card) => _playerHandCard(card, canPlay),
                          ),
                          right: _pileLane(
                            game: game,
                            owner: Player.player,
                            color: ScobaPalette.blueText,
                            showDeck: game.starter == Player.player,
                            deckAbove: false,
                          ),
                        ),
                        const SizedBox(height: 6),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
        if (summary != null)
          Positioned.fill(
            child: ColoredBox(
              color: Colors.black.withValues(alpha: 0.7),
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: ChkobbaRoundCard(
                    summary: summary,
                    avatarIds: _avatarIds,
                    onContinue: () => _deal(_controller.continueAfterRound),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  /// Largeur d'un coin latéral (#766) : entre 88 et 100 dp selon l'écran.
  static double _cornerWidth(double screenWidth) =>
      math.min(math.max(screenWidth * 0.24, 88.0), 100.0);

  /// Carte de la main du joueur. Appui maintenu : le tapis s'allume sur ses prises (#923).
  /// Tap : la carte est jouée (ou choisie parmi les prises).
  Widget _playerHandCard(ChkobbaCard card, bool canPlay) {
    return Listener(
      onPointerDown: (_) => _setPreview(canPlay ? card.id : null),
      onPointerUp: (_) => _setPreview(null),
      onPointerCancel: (_) => _setPreview(null),
      child: ChkobbaCardFace(
        key: _key('hand:${card.id}'),
        card: card,
        onTap: canPlay ? () => _onPlayerCard(card.id) : null,
      ),
    );
  }

  /// Carte de l'adversaire : dos, sauf celle qu'il montre (#766).
  Widget _opponentCard(ChkobbaCard card, String? revealedId) {
    return KeyedSubtree(
      key: _key('opp:${card.id}'),
      child: card.id == revealedId
          ? ChkobbaCardFace(card: card, highlight: true)
          : const ChkobbaCardBack(),
    );
  }

  /// Coin d'avatar (#800) : identité seule, à l'extérieur de la rangée.
  Widget _avatarLane({
    required ChkobbaState game,
    required Player player,
    required String name,
    required Color color,
  }) {
    return FittedBox(
      fit: BoxFit.scaleDown,
      child: _SidePanel(
        key: _key('panel:${player.name}'),
        game: game,
        player: player,
        name: name,
        color: color,
        avatarId: _avatarIds[player.index],
        opponentSide: player == Player.opponent,
        reaction: _controller.reactionOf(player),
      ),
    );
  }

  /// Coin de pile et de pioche (#800), côté opposé aux avatars. La pioche n'est
  /// là que chez celui qui commence : au-dessus de la pile en haut, dessous en bas.
  Widget _pileLane({
    required ChkobbaState game,
    required Player owner,
    required Color color,
    required bool showDeck,
    required bool deckAbove,
  }) {
    final pile = _WonPile(
      key: _key('won:${owner.name}'),
      color: color,
      chkobbaCards: _shownChkobbaCards(owner),
    );
    final deck = Semantics(
      label: tf('sDeckLeft', {'n': '${game.deck.length}'}),
      child: KeyedSubtree(
        key: _key('deck'),
        child: ChkobbaDeckPile(count: game.deck.length),
      ),
    );
    return FittedBox(
      fit: BoxFit.scaleDown,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (showDeck && deckAbove) ...[deck, const SizedBox(height: 6)],
          pile,
          if (showDeck && !deckAbove) ...[const SizedBox(height: 6), deck],
        ],
      ),
    );
  }

  /// Cartes de Chkobba sous le tas, une fois arrivées (pas pendant leur vol, #594, #626).
  List<ChkobbaCard> _shownChkobbaCards(Player p) => [
        for (final card in _controller.chkobbaCardsOf(p))
          if (!_capturing.contains(card.id)) card,
      ];

  static int _roundUp(int value, int multiple) =>
      ((value + multiple - 1) ~/ multiple) * multiple;
}
