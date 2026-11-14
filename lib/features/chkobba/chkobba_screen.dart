import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:material_ui/material_ui.dart';

import '../../core/services/ad_free_service.dart';
import '../../core/i18n/app_language.dart';
import '../../core/strings.dart';
import '../../core/theme/game_style.dart';
import '../../game/chkobba.dart';
import '../../game/common.dart';
import '../menu/menu_models.dart';
import 'chkobba_card_face.dart';
import 'chkobba_controller.dart';
import 'chkobba_rules_screen.dart';
import 'chkobba_table.dart';
import '../../widgets/exit_guard.dart';
import '../../widgets/game_scaffold.dart';
import '../../core/services/saved_game_store.dart';
import '../../widgets/resume_game.dart';
import '../../widgets/difficulty_chip.dart';
import '../../widgets/game_header.dart';
import '../../widgets/card_flight.dart';

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

class _ChkobbaScreenState extends State<ChkobbaScreen> {
  late final ChkobbaController _controller;

  @override
  void initState() {
    super.initState();
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

  /// Cases du tapis masquées tant qu'une carte posée n'y est pas arrivée (#238).
  final Set<String> _landing = {};

  /// Tout mouvement de carte : cartes jouées, captures, donne (#238).
  /// Une capture se lit en deux temps : la carte se pose sur le tapis,
  /// puis la carte et les cartes prises rejoignent le tas du gagnant.
  void _onChanged() {
    final game = _controller.game;
    if (identical(game, _lastGame)) return;
    if (!_ready) {
      _restored = true;
      return;
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
    final tableKey = _key('table');
    bool wonNow(String id) =>
        taker != null && (game.won[taker]?.any((c) => c.id == id) ?? false);

    // Cartes prises : elles quittent le tapis vers le tas du gagnant, après la pose.
    final gone = [
      for (final card in beforeTable)
        if (game.table.every((t) => t.id != card.id)) card,
    ];
    if (winnerKey != null) {
      for (final card in gone) {
        final from = rectOfKey(_key('tbl:${card.id}'));
        if (from == null) continue;
        unawaited(
          flyCard(
            context: context,
            from: from,
            to: () => rectOfKey(winnerKey),
            child: ChkobbaCardFace(card: card),
            delay: _capturePause,
            hold: true,
          ),
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
    final tableNow = tableKey;
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
      final from = rectOfKey(key)!;
      // Temps 1 : la carte se pose au centre du tapis.
      unawaited(
        flyCard(
          context: context,
          from: from,
          to: () => _centerOn(tableNow, from.size),
          child: ChkobbaCardFace(card: card),
        ),
      );
      // Temps 2 : elle rejoint le tas avec les cartes prises.
      final mid = _centerOn(tableNow, from.size);
      if (mid != null && winnerKey != null) {
        unawaited(
          flyCard(
            context: context,
            from: mid,
            to: () => rectOfKey(winnerKey),
            child: ChkobbaCardFace(card: card),
            delay: _capturePause,
            hold: true,
          ),
        );
      }
    }

    // Cartes posées sans capture : vers leur case du tapis (après le rendu).
    if (plain.isNotEmpty) {
      for (final (card, _) in plain) {
        _landing.add(card.id);
      }
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        var i = 0;
        for (final (card, from) in plain) {
          final id = card.id;
          if (_targetFor(id) == null) {
            setState(() => _landing.remove(id));
            continue;
          }
          unawaited(
            flyCard(
              context: context,
              from: from,
              to: () => _targetFor(id),
              child: ChkobbaCardFace(card: card),
              delay: _stagger * i,
            ).whenComplete(() {
              if (!mounted) return;
              setState(() => _landing.remove(id));
            }),
          );
          i++;
        }
      });
    }

    if (_dealPending) _distribute();
  }

  /// Rectangle de taille [size] centré sur le widget [key].
  Rect? _centerOn(GlobalKey key, Size size) {
    final r = rectOfKey(key);
    if (r == null) return null;
    return Rect.fromCenter(
      center: r.center,
      width: size.width,
      height: size.height,
    );
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

  static ChkobbaAiLevel _levelFor(Difficulty d) => switch (d) {
        Difficulty.facile => ChkobbaAiLevel.facile,
        Difficulty.moyen => ChkobbaAiLevel.moyen,
        Difficulty.difficile => ChkobbaAiLevel.difficile,
      };

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
    final style = GameStyle.current;
    final Widget background;
    if (style.villageBackground) {
      background = const _CalmBackground();
    } else {
      background = const _WoodBackground();
    }

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
    final thinking = _controller.isOpponentThinking;
    final canPlay = !over && game.winner == null && game.turn == Player.player;
    final cardWidth = cardHeight * 0.7;
    final style = GameStyle.current;

    // Emplacements du tapis : au moins 12, multiple du nombre de colonnes (comme TABLE_MIN_SLOTS).
    // Chaque carte garde son emplacement : les autres ne glissent pas après un jeu.
    final assigned = _controller.tableSlots();
    final used = assigned.values.fold<int>(
      0,
      (max, index) => math.max(max, index + 1),
    );
    final slotCount = _roundUp(math.max(12, used), columns);
    final slots = List<Widget?>.filled(slotCount, null);
    for (final card in game.table) {
      final index = assigned[card.id]!;
      if (_landing.contains(card.id)) {
        slots[index] = Opacity(
          key: _key('tbl:${card.id}'),
          opacity: 0,
          child: ChkobbaCardFace(card: card),
        );
      } else {
        slots[index] = ChkobbaCardFace(
          key: _key('tbl:${card.id}'),
          card: card,
        );
      }
    }

    return Stack(
      children: [
        Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 6, 10, 0),
              child: GameHeader(
                unit: 14,
                onMenu: () => Navigator.of(context).pop(),
                center: Expanded(
                  child: Center(
                    child: DifficultyChip(difficulty: widget.difficulty),
                  ),
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      tooltip: t('chkobbaRules'),
                      onPressed: () => Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => const ChkobbaRulesScreen(),
                        ),
                      ),
                      icon: const Icon(Icons.menu_book, color: Colors.white),
                    ),
                    if (game.winner != null)
                      IconButton(
                        tooltip: t('newGame'),
                        onPressed: () => _deal(_controller.startNewGame),
                        icon: const Icon(Icons.refresh, color: Colors.white),
                      ),
                    _TargetBadge(target: game.targetScore),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 8, 10, 0),
              child: _Scoreboard(
                game: game,
                playerWonKey: _key('won:player'),
                opponentWonKey: _key('won:opponent'),
                deckKey: _key('deck'),
              ),
            ),
            const SizedBox(height: 8),
            // Main de l'adversaire : dos des cartes, sauf celle qu'il montre.
            // Taille réduite (≈ 0,8 × la main du joueur), comme le source React (0,9 vs 1,06).
            KeyedSubtree(
              key: _key('opp-hand'),
              child: _Hand(
                cards: game.hands[Player.opponent]!,
                width: cardWidth * 0.8,
                height: cardHeight * 0.8,
                builder: (card) => KeyedSubtree(
                  key: _key('opp:${card.id}'),
                  child: card.id == revealed
                      ? ChkobbaCardFace(card: card, highlight: true)
                      : const ChkobbaCardBack(),
                ),
              ),
            ),
            Expanded(
              child: Stack(
                alignment: Alignment.center,
                children: [
                  if (game.winner != null && !over)
                    _FinalCard(state: game)
                  else
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 400),
                        child: ChkobbaTable(
                          key: _key('table'),
                          cards: slots,
                          columns: columns,
                          emptyLabel: 'Chkobba !',
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
                      ),
                    ),
                  // Bannière de tour : toujours réservée, visible seulement quand l'adversaire réfléchit.
                  Positioned(
                    bottom: 6,
                    left: 0,
                    right: 0,
                    child: IgnorePointer(
                      child: Opacity(
                        opacity: thinking ? 1 : 0,
                        child: const Center(child: _ThinkingBadge()),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Main du joueur, plus grande que celle de l'adversaire.
            _Hand(
              cards: game.hands[Player.player]!,
              width: cardWidth,
              height: cardHeight,
              builder: (card) => ChkobbaCardFace(
                key: _key('hand:${card.id}'),
                card: card,
                onTap: canPlay ? () => _onPlayerCard(card.id) : null,
              ),
            ),
            const SizedBox(height: 8),
          ],
        ),
        if (summary != null)
          Positioned.fill(
            child: ColoredBox(
              color: Colors.black.withValues(alpha: 0.7),
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: _RoundCard(
                    summary: summary,
                    onContinue: () => _deal(_controller.continueAfterRound),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  static int _roundUp(int value, int multiple) =>
      ((value + multiple - 1) ~/ multiple) * multiple;
}

/// Fond bois du jeu React (style d'origine) : bandes brunes verticales.
/// Fond village calmé : image désaturée et voilée, pour que le tapis et les cartes ressortent.
class _CalmBackground extends StatelessWidget {
  const _CalmBackground();

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        ColorFiltered(
          colorFilter: const ColorFilter.matrix(_saturation40),
          child: Image.asset(
            'assets/images/background.webp',
            fit: BoxFit.cover,
          ),
        ),
        const DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0x99000000), Color(0xCC000000)],
            ),
          ),
        ),
      ],
    );
  }
}

// Matrice de saturation à 40 % (luminance Rec. 709).
const _saturation40 = <double>[
  0.52756,
  0.42912,
  0.04332,
  0,
  0,
  0.12756,
  0.82912,
  0.04332,
  0,
  0,
  0.12756,
  0.42912,
  0.44332,
  0,
  0,
  0,
  0,
  0,
  1,
  0,
];

class _WoodBackground extends StatelessWidget {
  const _WoodBackground();

  @override
  Widget build(BuildContext context) {
    return CustomPaint(painter: _WoodPainter());
  }
}

class _WoodPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(
      Offset.zero & size,
      Paint()..color = const Color(0xFF8B4513),
    );
    final light = Paint()..color = const Color(0xFFA0522D);
    final dark = Paint()..color = const Color(0xFF654321);
    for (double x = 0; x < size.width; x += 8) {
      canvas.drawRect(Rect.fromLTWH(x + 2, 0, 2, size.height), light);
      canvas.drawRect(Rect.fromLTWH(x + 6, 0, 2, size.height), dark);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Pastille du score cible (trophée jaune avec le nombre dessus).
class _TargetBadge extends StatelessWidget {
  const _TargetBadge({required this.target});

  final int target;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 44,
      height: 44,
      child: Stack(
        alignment: Alignment.center,
        children: [
          const Icon(Icons.emoji_events, size: 44, color: Color(0xFFFBBF24)),
          Align(
            alignment: const Alignment(0, -0.25),
            child: Text(
              '$target',
              style: const TextStyle(
                fontWeight: FontWeight.w900,
                fontSize: 15,
                color: Color(0xFF20284B),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Tableau de bord : score de chaque joueur, Chkobba, cartes ramassées et pioche.
class _Scoreboard extends StatelessWidget {
  const _Scoreboard({
    required this.game,
    this.playerWonKey,
    this.opponentWonKey,
    this.deckKey,
  });

  /// Clé de la pioche (cible de la donne animée, #238).
  final Key? deckKey;

  final ChkobbaState game;

  /// Clés des tas de cartes gagnées (cibles des captures animées, #238).
  final Key? playerWonKey;
  final Key? opponentWonKey;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      container: true,
      label: tf('sChkScore', {
        'a': '${game.scores[Player.player]}',
        'b': '${game.scores[Player.opponent]}',
      }),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFFFACC15), Color(0xFFFBBF24), Color(0xFFFB923C)],
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.black, width: 3),
          boxShadow: const [
            BoxShadow(color: Colors.black, offset: Offset(0, 5)),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _ScoreSide(
              key: playerWonKey,
              name: t('you'),
              score: game.scores[Player.player]!,
              chkobbas: game.chkobbas[Player.player]!,
              cards: game.won[Player.player]!.length,
              color: const Color(0xFF047857),
            ),
            Semantics(
              label: tf('sDeckLeft', {'n': '${game.deck.length}'}),
              child: KeyedSubtree(
                key: deckKey,
                child: _DeckPile(count: game.deck.length),
              ),
            ),
            _ScoreSide(
              key: opponentWonKey,
              name: t('opponent'),
              score: game.scores[Player.opponent]!,
              chkobbas: game.chkobbas[Player.opponent]!,
              cards: game.won[Player.opponent]!.length,
              color: const Color(0xFFB91C1C),
            ),
          ],
        ),
      ),
    );
  }
}

class _ScoreSide extends StatelessWidget {
  const _ScoreSide({
    super.key,
    required this.name,
    required this.score,
    required this.chkobbas,
    required this.cards,
    required this.color,
  });

  final String name;
  final int score;
  final int chkobbas;
  final int cards;
  final Color color;

  @override
  Widget build(BuildContext context) {
    const info = TextStyle(
      fontSize: 11,
      fontWeight: FontWeight.w700,
      color: Color(0xB3451A03),
    );
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 34,
          height: 34,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: color, width: 2),
          ),
          child: Text(
            '$score',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w900,
              color: color,
            ),
          ),
        ),
        const SizedBox(height: 2),
        Text(
          name.toUpperCase(),
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w900,
            color: color,
            letterSpacing: 0.5,
          ),
        ),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.star, size: 12, color: Color(0xFF92400E)),
            Text(' $chkobbas', style: info),
            const SizedBox(width: 8),
            Text(tf('cardCount', {'n': '$cards'}), style: info),
          ],
        ),
      ],
    );
  }
}

/// Pioche : trois cartes empilées avec le nombre de cartes restantes.
class _DeckPile extends StatelessWidget {
  const _DeckPile({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    Widget pile(Color color) => Container(
          width: 18,
          height: 26,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(3),
            border: Border.all(color: Colors.black, width: 2),
          ),
        );

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: 46,
          height: 46,
          child: Stack(
            alignment: Alignment.center,
            clipBehavior: Clip.none,
            children: [
              Transform.translate(
                offset: const Offset(-4, 0),
                child: Transform.rotate(
                  angle: -0.2,
                  child: pile(const Color(0xFFA82D49)),
                ),
              ),
              Transform.translate(
                offset: const Offset(4, 0),
                child: Transform.rotate(
                  angle: 0.2,
                  child: pile(const Color(0xFF8F203D)),
                ),
              ),
              pile(const Color(0xFFC63D55)),
              const Icon(Icons.layers, size: 14, color: Color(0xFFFFE16B)),
              Positioned(
                top: -2,
                right: -2,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 4,
                    vertical: 1,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFFDF5),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.black),
                  ),
                  child: Text(
                    '$count',
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF20284B),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        Text(
          t('draw'),
          style: TextStyle(
            fontSize: 9,
            fontWeight: FontWeight.w900,
            color: Color(0xFF17213D),
          ),
        ),
      ],
    );
  }
}

/// Rangée de trois emplacements fixes : les cartes ne se décalent pas quand la main diminue.
class _Hand extends StatelessWidget {
  const _Hand({
    required this.cards,
    required this.width,
    required this.height,
    required this.builder,
  });

  final List<ChkobbaCard> cards;
  final double width;
  final double height;
  final Widget Function(ChkobbaCard card) builder;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        for (var i = 0; i < 3; i++) ...[
          if (i > 0) const SizedBox(width: 8),
          SizedBox(
            width: width,
            height: height,
            child: i < cards.length ? builder(cards[i]) : const _EmptySlot(),
          ),
        ],
      ],
    );
  }
}

class _EmptySlot extends StatelessWidget {
  const _EmptySlot();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: const Color(0x26FFFFFF), width: 2),
        borderRadius: BorderRadius.circular(8),
      ),
    );
  }
}

/// « Tour de l'adversaire... », affiché pendant que l'IA réfléchit.
class _ThinkingBadge extends StatelessWidget {
  const _ThinkingBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFF97316), Color(0xFFDC2626)],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.black, width: 3),
        boxShadow: const [BoxShadow(color: Colors.black, offset: Offset(0, 5))],
      ),
      child: Semantics(
        liveRegion: true,
        child: const Text(
          "⏳ Tour de l'adversaire...",
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w900,
            fontSize: 15,
          ),
        ),
      ),
    );
  }
}

/// Résultat final de la partie (affiché sur le tapis après le récapitulatif).
class _FinalCard extends StatelessWidget {
  const _FinalCard({required this.state});

  final ChkobbaState state;

  @override
  Widget build(BuildContext context) {
    final won = state.winner == Player.player;
    final rounds = state.round;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.black, width: 3),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            won ? '🏆 Victoire !' : 'Défaite',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w900,
              fontSize: 26,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '${state.scores[Player.player]} – ${state.scores[Player.opponent]} · $rounds manche${rounds > 1 ? 's' : ''}',
            style: const TextStyle(
              color: Colors.white70,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

/// Récapitulatif de manche, comme la carte « Manche N » du source.
class _RoundCard extends StatelessWidget {
  const _RoundCard({required this.summary, required this.onContinue});

  final ChkobbaRoundScore summary;
  final VoidCallback onContinue;

  // La correspondance porte sur le libellé français produit par la logique du jeu (inchangé).
  // Seul l'affichage est traduit, avec une clé lue à chaque build (pas de cache de langue).
  static final _categories = <({String key, bool Function(String) matches})>[
    (key: 'catChkobba', matches: (l) => l.startsWith('Chkobba')),
    (key: 'catHaya', matches: (l) => l.startsWith('Haya')),
    (key: 'catCards', matches: (l) => l == 'Cartes'),
    (key: 'catDeniers', matches: (l) => l == 'Deniers'),
    (key: 'catBermila', matches: (l) => l == 'Bermila'),
  ];

  int _pointsFor(Player p, bool Function(String) matches) => summary.points[p]!
      .where((x) => matches(x.label))
      .fold(0, (sum, x) => sum + x.value);

  int _total(Player p) => summary.points[p]!.fold(0, (sum, x) => sum + x.value);

  static String _show(int v) => v == 0 ? '—' : '$v';

  Widget _row(
    String label,
    String player,
    String opponent, {
    TextStyle? style,
    double pad = 8,
  }) {
    final base = style ??
        const TextStyle(
          fontWeight: FontWeight.w900,
          fontSize: 14,
          color: Color(0xFF17213D),
        );
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: pad),
      child: Row(
        children: [
          Expanded(child: Text(label, style: base)),
          SizedBox(
            width: 64,
            child: Text(
              player,
              textAlign: TextAlign.center,
              style: base.copyWith(color: const Color(0xFF065F46)),
            ),
          ),
          SizedBox(
            width: 76,
            child: Text(
              opponent,
              textAlign: TextAlign.center,
              style: base.copyWith(color: const Color(0xFF9F1239)),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = summary.state;
    final winner = state.winner;
    return Container(
      constraints: const BoxConstraints(maxWidth: 420),
      decoration: BoxDecoration(
        color: const Color(0xFF059669),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.black, width: 4),
        boxShadow: const [BoxShadow(color: Colors.black, offset: Offset(0, 7))],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF10B981), Color(0xFF047857)],
                ),
                border: Border(
                  bottom: BorderSide(color: Colors.black, width: 4),
                ),
              ),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFE16B),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.black, width: 2),
                    ),
                    child: const Text(
                      'RÉCAPITULATIF',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 2,
                        color: Color(0xFF17213D),
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Manche ${state.round}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                      fontSize: 24,
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _row(
                    t('roundPoints'),
                    t('you'),
                    t('opponent'),
                    style: const TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 11,
                      color: Colors.white,
                    ),
                    pad: 0,
                  ),
                  const SizedBox(height: 6),
                  Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFFDF5),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.black, width: 3),
                    ),
                    child: Column(
                      children: [
                        for (var i = 0; i < _categories.length; i++)
                          Container(
                            decoration: BoxDecoration(
                              border: i == 0
                                  ? null
                                  : const Border(
                                      top: BorderSide(
                                        color: Color(0xFFB8C5AD),
                                        width: 2,
                                      ),
                                    ),
                            ),
                            child: _row(
                              t(_categories[i].key),
                              _show(
                                _pointsFor(
                                  Player.player,
                                  _categories[i].matches,
                                ),
                              ),
                              _show(
                                _pointsFor(
                                  Player.opponent,
                                  _categories[i].matches,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
                  Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFF15264D),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.black, width: 3),
                    ),
                    child: _row(
                      'Score de la manche',
                      '+${_total(Player.player)}',
                      '+${_total(Player.opponent)}',
                      style: const TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 14,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFFFFE16B), Color(0xFFFFC24B)],
                      ),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.black, width: 3),
                    ),
                    child: _row(
                      'Score total',
                      '${state.scores[Player.player]}',
                      '${state.scores[Player.opponent]}',
                      style: const TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 18,
                        color: Color(0xFF17213D),
                      ),
                      pad: 10,
                    ),
                  ),
                  const SizedBox(height: 16),
                  GestureDetector(
                    onTap: onContinue,
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFFFFE16B), Color(0xFFFFB43C)],
                        ),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.black, width: 3),
                        boxShadow: const [
                          BoxShadow(color: Colors.black, offset: Offset(0, 5)),
                        ],
                      ),
                      child: Text(
                        winner == null
                            ? 'Manche suivante →'
                            : 'Voir le résultat final',
                        style: const TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 16,
                          color: Color(0xFF30264F),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Feuille de choix quand une carte peut prendre plusieurs combinaisons (« Que veux-tu prendre ? »).
class _CapturePicker extends StatelessWidget {
  const _CapturePicker({required this.options});

  final List<List<ChkobbaCard>> options;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF059669),
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        border: Border(top: BorderSide(color: Colors.black, width: 4)),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Que veux-tu prendre ?',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                  fontSize: 20,
                ),
              ),
              const SizedBox(height: 12),
              for (final option in options)
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: GestureDetector(
                    onTap: () => Navigator.of(context).pop(option),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        vertical: 12,
                        horizontal: 8,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.black, width: 3),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          for (final card in option)
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 4,
                              ),
                              child: SizedBox(
                                width: 52,
                                height: 74,
                                child: ChkobbaCardFace(card: card),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              const SizedBox(height: 4),
              OutlinedButton(
                style: OutlinedButton.styleFrom(foregroundColor: Colors.white),
                onPressed: () => Navigator.of(context).pop(),
                child: Text(Strings.actCancel),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
