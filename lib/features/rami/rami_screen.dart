import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show ValueListenable;

import '../../core/layout/device_metrics.dart';
import '../../widgets/comic/comic_pill.dart';
import '../../core/services/toast.dart';
import '../../game/rami.dart' as rules;
import '../../widgets/ad_banner.dart';
import '../menu/menu_models.dart';
import 'rami_card_view.dart';
import 'rami_controller.dart';
import '../../core/strings.dart';
import '../../core/i18n/app_language.dart';
import '../../core/theme/game_style.dart';
import '../../core/services/ad_free_service.dart';
import '../../widgets/exit_guard.dart';
import '../../core/services/saved_game_store.dart';
import '../../widgets/resume_game.dart';

/// Facteur d'agrandissement des cartes Rami (lisibilité sur téléphone).
const double _ramiCardScale = 1.35;

/// Clé partagée avec le mode sans pub (même nom que le web).
const _feltColor = Color(0xFF10B981);
const _frameColor = Color(0xFF4A2A10);
const _creamColor = Color(0xFFFFF8E7);
const _inkColor = Color(0xFF20284B);
const _goldColor = Color(0xFFFFE16B);
const _woodColor = Color(0xFF8B4513);
const _dragThreshold = 8.0;

const _seatNames = ['Toi', 'Ali', 'Karim', 'Sami'];
const _groupColors = [
  Color(0xFFE43F5F),
  Color(0xFF1676D2),
  Color(0xFFF49B32),
  Color(0xFF9B8CFF),
  Color(0xFF14705B),
];

final _ramiRules = <({String title, String text})>[
  (
    title: 'Le jeu',
    text:
        '4 joueurs chacun pour soi : toi contre 3 IA. 2 jeux de 52 cartes + 2 jokers, 13 cartes chacun.',
  ),
  (
    title: 'Combinaisons',
    text: 'Suite : 3 cartes ou plus de même couleur qui se suivent (As bas ou haut, sans boucler). '
        'Brelan ou carré : 3 ou 4 cartes de même valeur et de couleurs différentes.',
  ),
  (
    title: Strings.jokerLabel,
    text:
        "Remplace n'importe quelle carte dans une combinaison, avec au moins 2 vraies cartes.",
  ),
  (
    title: 'Ouverture',
    text:
        'Ta première pose doit totaliser ${rules.ramiOpenMin} points minimum, en une seule fois. '
            'As = 1, figures = 10, joker = 20.',
  ),
  (
    title: 'Ton tour',
    text: 'Pioche dans la pioche ou prends la défausse. Pose tes combinaisons, ajoute des cartes sur '
        'celles de la table (une fois ouvert), puis défausse. La carte prise à la défausse ne peut pas '
        'être défaussée tout de suite.',
  ),
  (
    title: 'Glisser-déposer',
    text: 'Fais glisser tes cartes pour les ranger : une barre colorée sous des cartes voisines indique '
        'un paquet valide. Glisse un paquet sur la table pour le poser, une carte sur une combinaison '
        'pour l\'ajouter, ou sur la défausse pour finir ton tour. Un simple appui sélectionne une carte.',
  ),
  (
    title: 'Fin de manche',
    text:
        'Le premier qui vide sa main gagne la manche. Les autres comptent les points des cartes qui '
            'leur restent.',
  ),
  (
    title: 'Partie',
    text:
        "Les points de pénalité s'additionnent jusqu'à 100 ou 200. Le plus petit total gagne.",
  ),
];

String _statusText(rules.RamiState g, int stagedPoints) {
  if (g.phase == rules.RamiPhase.end) return '';
  if (g.turn != 0) return '${_seatNames[g.turn]} réfléchit…';
  if (g.phase == rules.RamiPhase.draw) return Strings.ramiYourDraw;
  if (g.staged.isNotEmpty) {
    return 'Ouverture : $stagedPoints / ${rules.ramiOpenMin} pts. Valide quand c\'est bon';
  }
  if (g.opened[0]) return Strings.ramiSlideThenDiscard;
  return 'Ouvre avec ${rules.ramiOpenMin} pts : glisse tes paquets sur la table';
}

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

/// Appui en cours sur une carte de la main ; devient un glisser après [_dragThreshold] px.
class _Press {
  _Press(this.id, this.start);

  final String id;
  final Offset start;
  bool active = false;
}

/// Carte en cours de glisser : position dans le corps de l'écran et cible survolée.
class _Drag {
  const _Drag(this.id, this.local, this.target);

  final String id;
  final Offset local;
  final RamiDropTarget? target;
}

class _RamiScreenState extends State<RamiScreen> {
  late final RamiController _c = RamiController(
    store: const SharedPreferencesSavedGameStore(),
    targetScore: widget.targetScore,
    difficulty: rules.RamiAiLevel.values.byName(widget.difficulty.name),
    onMessage: _showMessage,
  );

  /// Clés des zones cibles (« discard », « table », « meld:id », « hand:id »), pour le test de position.
  final Map<String, GlobalKey> _keys = {};
  final GlobalKey _bodyKey = GlobalKey();
  _Press? _press;
  _Drag? _drag;
  final ValueListenable<bool> _adFree = AdFreeService.instance.active;

  @override
  void initState() {
    super.initState();
    _c.restore().then((_) {
      if (mounted) offerResume(context, _c);
    });
    _adFree.addListener(_onAdFreeChanged);
  }

  @override
  void dispose() {
    _adFree.removeListener(_onAdFreeChanged);
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
    for (final entry in _keys.entries) {
      final rect = _rectOf(entry.value);
      if (rect == null || !rect.contains(point)) continue;
      final name = entry.key;
      if (name == 'table') {
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
    return table;
  }

  Offset _toLocal(Offset global) {
    final box = _bodyKey.currentContext?.findRenderObject();
    return box is RenderBox ? box.globalToLocal(global) : global;
  }

  void _onPointerDown(PointerDownEvent event, String id) {
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

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final metrics = DeviceMetrics(width: size.width, height: size.height);
    // Cartes agrandies sur l'écran Rami (la formule de DeviceMetrics reste celle du source).
    final handWidth = metrics.ramiHandCardWidth * _ramiCardScale;

    return ExitGuard(
      active: _c.game.matchWinner == null,
      child: Scaffold(
        backgroundColor: _woodColor,
        body: ListenableBuilder(
          listenable: _c,
          builder: (context, _) {
            final g = _c.game;
            return Stack(
              key: _bodyKey,
              children: [
                const Positioned.fill(
                  child: DecoratedBox(
                    decoration: BoxDecoration(color: _woodColor),
                  ),
                ),
                SafeArea(
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(
                      8,
                      8,
                      8,
                      _adFree.value ? 8 : 80,
                    ),
                    child: Column(
                      children: [
                        _header(g),
                        const SizedBox(height: 6),
                        _scores(g),
                        const SizedBox(height: 6),
                        Expanded(child: _tableSection(handWidth, g)),
                        const SizedBox(height: 6),
                        _footer(handWidth),
                      ],
                    ),
                  ),
                ),
                if (!_adFree.value)
                  const Positioned(
                    left: 8,
                    right: 8,
                    bottom: 8,
                    child: AdBanner(),
                  ),
                if (_drag != null) _dragOverlay(handWidth),
                if (g.phase == rules.RamiPhase.end && g.roundResult != null)
                  Positioned.fill(child: _summary(g)),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _header(rules.RamiState g) {
    return Row(
      children: [
        kComicRami
            ? ComicPill(
                label: Strings.menuLabel,
                icon: Icons.arrow_back,
                onTap: () => Navigator.of(context).maybePop(),
              )
            : Material(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                child: InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: () => Navigator.of(context).maybePop(),
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.arrow_back,
                          size: 18,
                          color: Color(0xFF7E22CE),
                        ),
                        SizedBox(width: 4),
                        Text(
                          Strings.menuLabel,
                          style: TextStyle(
                            color: Color(0xFF7E22CE),
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
        Expanded(
          child: Column(
            children: [
              Text(
                Strings.headerRami,
                style: TextStyle(
                  color: Color(0xFFFFF1BD),
                  fontWeight: FontWeight.w900,
                  letterSpacing: 2,
                  fontSize: 13,
                ),
              ),
              Text(
                tf('round', {'n': '${g.round}'}),
                style: const TextStyle(fontWeight: FontWeight.w800),
              ),
            ],
          ),
        ),
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
            child: Stack(
              alignment: Alignment.center,
              children: [
                const Icon(
                  Icons.emoji_events,
                  size: 44,
                  color: Color(0xFFFBBF24),
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(
                    '${g.targetScore}',
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
      ],
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

  Widget _scores(rules.RamiState g) {
    return Row(
      children: [
        for (var seat = 0; seat < 4; seat++)
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2),
              child: _PlayerChip(seat: seat, game: g),
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
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _piles(handWidth * 1.1, g),
              const SizedBox(width: 8),
              Expanded(child: _statusBubble(g)),
            ],
          ),
          const SizedBox(height: 8),
          Expanded(child: _tableCards(handWidth * 0.8, g)),
          _contextActions(g),
        ],
      ),
    );
  }

  /// Boutons d'action affichés sur la table seulement quand ils servent :
  /// valider/annuler pendant une pose en cours, poser/défausser quand des cartes sont sélectionnées.
  Widget _contextActions(rules.RamiState g) {
    final c = _c;
    if (!c.canPlay) return const SizedBox.shrink();
    final staged = g.staged.isNotEmpty;
    if (!staged && c.selected.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Wrap(
        alignment: WrapAlignment.center,
        spacing: 6,
        runSpacing: 6,
        children: _actions(staged),
      ),
    );
  }

  Widget _piles(double width, rules.RamiState g) {
    final c = _c;
    final top = c.top;
    final discardHover = c.canPlay && _drag?.target is RamiDropDiscard;
    return Row(
      children: [
        Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            GestureDetector(
              onTap: c.canDraw ? c.drawFromStock : null,
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(width * 0.14),
                  border: c.canDraw
                      ? Border.all(color: _goldColor, width: 3)
                      : null,
                ),
                child: RamiBackView(width: width),
              ),
            ),
            Text(
              'Pioche · ${g.stock.length}',
              style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w900),
            ),
          ],
        ),
        const SizedBox(width: 8),
        Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              key: _key('discard'),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(width * 0.14),
                border: discardHover || c.canDraw
                    ? Border.all(color: _goldColor, width: 3)
                    : null,
              ),
              child: top == null
                  ? Container(
                      width: width,
                      height: width * 1.4,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(width * 0.14),
                        border: Border.all(color: Colors.white54, width: 2),
                      ),
                    )
                  : GestureDetector(
                      onTap: c.canDraw ? c.drawFromDiscard : null,
                      child: RamiCardView(card: top, width: width),
                    ),
            ),
            Text(
              'Défausse · ${g.discard.length}',
              style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w900),
            ),
          ],
        ),
      ],
    );
  }

  Widget _statusBubble(rules.RamiState g) {
    final text = _statusText(g, _c.stagedPoints);
    if (text.isEmpty) return const SizedBox.shrink();
    final myTurn = _c.myTurn;
    return Semantics(
      liveRegion: true,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: myTurn ? _goldColor : const Color(0xFFF97316),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.black, width: 2),
        ),
        child: Text(
          text,
          style: TextStyle(
            color: myTurn ? const Color(0xFF3D351F) : Colors.white,
            fontWeight: FontWeight.w900,
            fontSize: 13,
          ),
        ),
      ),
    );
  }

  Widget _tableCards(double meldWidth, rules.RamiState g) {
    final c = _c;
    final target = _drag?.target;
    final hover = c.canPlay && target is RamiDropTable;
    final dropping = c.canPlay && _drag != null;
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
          spacing: 6,
          runSpacing: 6,
          children: [
            if (g.table.isEmpty && g.staged.isEmpty)
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
            for (final meld in g.table)
              _MeldView(
                key: _key('meld:${meld.id}'),
                cards: meld.cards,
                cardWidth: meldWidth,
                hot:
                    c.canPlay && target is RamiDropMeld && target.id == meld.id,
                eligible: c.layEligible,
                onTap: c.layEligible ? () => c.layOffSelected(meld.id) : null,
              ),
            for (final cards in g.staged)
              _MeldView(cards: cards, cardWidth: meldWidth, staged: true),
          ],
        ),
      ),
    );
  }

  /// Pied : seulement la main (#121 : plus de tri, de compteur ni de libellé de paquets).
  Widget _footer(double handWidth) {
    return Container(
      padding: const EdgeInsets.fromLTRB(8, 6, 8, 8),
      decoration: BoxDecoration(
        color: _creamColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _frameColor, width: 3),
      ),
      child: _handRow(handWidth),
    );
  }

  List<Widget> _actions(bool staged) {
    final c = _c;
    return [
      if (!staged)
        _ActionButton(
          label: Strings.actPose,
          onTap: c.pose,
          enabled: c.selectionIsMeld,
          primary: true,
        )
      else ...[
        _ActionButton(
          label: tf('validate', {
            'cur': '${c.stagedPoints}',
            'min': '${rules.ramiOpenMin}',
          }),
          onTap: c.commit,
          enabled: c.stagedPoints >= rules.ramiOpenMin,
          primary: true,
        ),
        _ActionButton(label: Strings.actCancel, onTap: c.cancel),
      ],
      _ActionButton(
        label: Strings.actDiscard,
        onTap: c.discardSelected,
        enabled: c.selected.length == 1 && !staged,
        danger: true,
      ),
    ];
  }

  /// Main du joueur (#141) : les cartes se chevauchent. La carte sélectionnée ou déplacée
  /// passe au-dessus des autres (z-order). Si la main est trop longue, le pas se resserre.
  Widget _handRow(double cardWidth) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final c = _c;
        final hand = c.displayed;
        final groupOf = c.groupOf;
        final selected = c.selected;
        final n = hand.length;
        final maxW = constraints.maxWidth;
        // Largeur de carte : réduite seulement si même le chevauchement minimal ne tient pas.
        final minStep = 0.3;
        final fitWidth = n <= 1 ? cardWidth : maxW / (1 + minStep * (n - 1));
        final width = fitWidth < cardWidth ? fitWidth : cardWidth;
        // Pas entre deux cartes : 60 % de la largeur, resserré pour tenir sur la largeur.
        final room = n <= 1 ? 0.0 : (maxW - width) / (n - 1);
        final natural = 0.6 * width;
        final step = n <= 1 ? 0.0 : (room < natural ? room : natural);
        final total = n == 0 ? 0.0 : width + step * (n - 1);
        final height = width * 1.4 + 8;

        // Ordre de dessin : cartes non sélectionnées d'abord, sélectionnées ou déplacées en dernier.
        final order = [
          for (var i = 0; i < n; i++)
            if (!selected.contains(hand[i].id) && _drag?.id != hand[i].id) i,
          for (var i = 0; i < n; i++)
            if (selected.contains(hand[i].id) || _drag?.id == hand[i].id) i,
        ];

        return Center(
          child: SizedBox(
            width: total,
            height: height,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                for (final i in order)
                  Positioned(
                    key: ValueKey('pos:${hand[i].id}'),
                    left: i * step,
                    top: 0,
                    child: _handCard(
                      hand[i],
                      width,
                      selected: selected.contains(hand[i].id),
                      group: groupOf[hand[i].id],
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
    required int? group,
  }) {
    final drag = _drag;
    final target = drag?.target;
    final dragged = drag?.id == card.id;
    final insert = target is RamiDropHand && target.id == card.id && !dragged
        ? target
        : null;

    return Listener(
      key: _key('hand:${card.id}'),
      behavior: HitTestBehavior.opaque,
      onPointerDown: (event) => _onPointerDown(event, card.id),
      onPointerMove: _onPointerMove,
      onPointerUp: _onPointerUp,
      onPointerCancel: (_) => _onPointerCancel(),
      child: SizedBox(
        width: width,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Opacity(
                  opacity: dragged ? 0.3 : 1,
                  child: RamiCardView(
                    card: card,
                    width: width,
                    selected: selected,
                  ),
                ),
                if (insert != null)
                  Positioned(
                    top: 0,
                    bottom: 0,
                    left: insert.after ? null : -3,
                    right: insert.after ? -3 : null,
                    child: Container(width: 3, color: const Color(0xFFE43F5F)),
                  ),
              ],
            ),
            Container(
              margin: const EdgeInsets.only(top: 3),
              height: 5,
              color: group == null
                  ? Colors.transparent
                  : _groupColors[group % _groupColors.length],
            ),
          ],
        ),
      ),
    );
  }

  /// Carte suivant le doigt pendant le glisser.
  Widget _dragOverlay(double handWidth) {
    final drag = _drag!;
    final c = _c;
    final width = handWidth * 1.15;
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
                      matchWinner != null
                          ? Strings.matchOver
                          : 'MANCHE ${g.round}',
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
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 30,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      for (var seat = 0; seat < 4; seat++)
                        Expanded(
                          child: Container(
                            margin: const EdgeInsets.symmetric(horizontal: 3),
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.black26,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Column(
                              children: [
                                Text(
                                  _seatNames[seat].toUpperCase(),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w900,
                                    fontSize: 11,
                                  ),
                                ),
                                Text(
                                  '+${result.penalties[seat]}',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 20,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                                Text(
                                  'Total ${g.scores[seat]}',
                                  style: const TextStyle(
                                    color: Colors.white70,
                                    fontSize: 10,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  if (matchWinner != null) ...[
                    _DialogButton(label: Strings.replay, onTap: _c.restart),
                    TextButton(
                      onPressed: () => Navigator.of(context).maybePop(),
                      child: Text(
                        Strings.backToMenu,
                        style: TextStyle(color: Colors.white70),
                      ),
                    ),
                  ] else
                    _DialogButton(
                      label: Strings.nextRoundButton,
                      onTap: _c.nextRound,
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

// ---------------------------------------------------------------------------
// Widgets auxiliaires
// ---------------------------------------------------------------------------

class _PlayerChip extends StatelessWidget {
  const _PlayerChip({required this.seat, required this.game});

  final int seat;
  final rules.RamiState game;

  @override
  Widget build(BuildContext context) {
    final active = game.turn == seat && game.phase != rules.RamiPhase.end;
    final opened = game.opened[seat] ? 'Ouvert' : 'Fermé';
    final ink = active ? const Color(0xFF513B00) : _inkColor;
    return Semantics(
      label: '${_seatNames[seat]} : ${game.scores[seat]} points, $opened',
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
        decoration: BoxDecoration(
          color: active ? _goldColor : _creamColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: _frameColor.withValues(alpha: active ? 1 : 0.6),
            width: 2,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Flexible(
                  child: Text(
                    _seatNames[seat].toUpperCase(),
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: ink,
                      fontSize: 11,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                if (game.dealer == seat) ...[
                  const SizedBox(width: 3),
                  const CircleAvatar(
                    radius: 7,
                    backgroundColor: _inkColor,
                    child: Text(
                      'D',
                      style: TextStyle(
                        fontSize: 9,
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ],
              ],
            ),
            Text(
              '${game.scores[seat]}',
              style: TextStyle(
                color: ink,
                fontSize: 18,
                fontWeight: FontWeight.w900,
              ),
            ),
            Text(
              seat == 0 ? opened : '×${game.hands[seat].length} · $opened',
              style: TextStyle(
                color: ink.withValues(alpha: 0.75),
                fontSize: 10,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Combinaison de la table : cartes qui se chevauchent, comme les piles du source.
class _MeldView extends StatelessWidget {
  const _MeldView({
    super.key,
    required this.cards,
    required this.cardWidth,
    this.hot = false,
    this.eligible = false,
    this.staged = false,
    this.onTap,
  });

  final List<rules.RamiCard> cards;
  final double cardWidth;
  final bool hot;
  final bool eligible;
  final bool staged;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final step = cardWidth * 0.58;
    final width = cardWidth + step * (cards.length - 1);
    final height = cardWidth * 1.4;
    final Color border = hot || eligible
        ? _goldColor
        : staged
            ? _goldColor.withValues(alpha: 0.8)
            : Colors.white24;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: hot
              ? _goldColor.withValues(alpha: 0.3)
              : Colors.black.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: border, width: 2),
        ),
        child: SizedBox(
          width: width,
          height: height,
          child: Stack(
            children: [
              for (var i = 0; i < cards.length; i++)
                Positioned(
                  left: step * i,
                  top: 0,
                  child: RamiCardView(card: cards[i], width: cardWidth),
                ),
            ],
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
            constraints: const BoxConstraints(minHeight: 40, minWidth: 64),
            alignment: Alignment.center,
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: Text(
              label,
              style: TextStyle(
                color: foreground,
                fontWeight: FontWeight.w900,
                fontSize: 13,
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
