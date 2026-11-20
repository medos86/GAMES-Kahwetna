import 'package:material_ui/material_ui.dart';

import '../core/avatars/avatar_catalog.dart';
import '../core/theme/comic_palette.dart';
import 'avatar_view.dart';
import 'result_dialog.dart';

/// Couleurs d'identité des joueurs et équipes dans les écrans de fin (issue #526).
/// Même ordre pour tous les jeux : 0 bleu, 1 rouge, 2 vert, 3 jaune.
abstract final class RoundResultColors {
  static const List<Color> seats = [
    ComicPalette.tunisBlue,
    ComicPalette.red,
    ComicPalette.seatGreen,
    ComicPalette.yellow,
  ];

  static Color seat(int index) => seats[index % seats.length];

  /// Encre ou blanc, selon celui qui contraste le plus avec [fill].
  static Color textOn(Color fill) {
    final inkContrast = contrastRatio(ComicPalette.ink, fill);
    final whiteContrast = contrastRatio(ComicPalette.white, fill);
    return inkContrast >= whiteContrast ? ComicPalette.ink : ComicPalette.white;
  }
}

/// Écran de fin de manche ou de partie, identique pour tous les jeux (issue #526).
/// Structure : bande colorée (titre), badge, sous-titre, une ligne par joueur
/// ou équipe, puis les boutons. Le gagnant a sa ligne en or.
class RoundResultPanel extends StatelessWidget {
  const RoundResultPanel({
    super.key,
    required this.title,
    required this.badge,
    required this.rows,
    required this.actions,
    this.subtitle,
    this.accent = ComicPalette.yellow,
  });

  final String title;
  final String badge;
  final String? subtitle;
  final List<RoundResultRow> rows;
  final List<Widget> actions;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return ResultDialog(
      title: title,
      accent: accent,
      actions: actions,
      children: [
        Center(child: _Badge(badge)),
        if (subtitle != null) ...[
          const SizedBox(height: 8),
          Text(
            subtitle!,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: ComicPalette.ink,
              fontWeight: FontWeight.w700,
              fontSize: 13,
            ),
          ),
        ],
        const SizedBox(height: 14),
        for (final row in rows)
          Padding(padding: const EdgeInsets.only(bottom: 8), child: row),
      ],
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: ComicPalette.ink,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        textAlign: TextAlign.center,
        style: const TextStyle(
          color: ComicPalette.paper,
          fontSize: 12,
          fontWeight: FontWeight.w900,
          letterSpacing: 1.5,
        ),
      ),
    );
  }
}

/// Une ligne de score : pastille, nom, motif, variation et total (issue #526).
/// La variation reste sur une seule ligne (mise à l'échelle au lieu du retour à la ligne).
class RoundResultRow extends StatelessWidget {
  const RoundResultRow({
    super.key,
    required this.name,
    required this.color,
    required this.value,
    this.leading,
    this.reason,
    this.total,
    this.highlight = false,
    this.avatarId,
    this.avatarState = AvatarState.neutral,
  });

  /// Nom du joueur ou de l'équipe.
  final String name;

  /// Couleur de la pastille (couleur du joueur sur le plateau).
  final Color color;

  /// Valeur principale, déjà formatée (« +10 », « 1er »…).
  final String value;

  /// Texte dans la pastille. Par défaut, l'initiale du nom.
  final String? leading;

  /// Motif court sous le nom.
  final String? reason;

  /// Total de la partie, affiché en grand. `null` : pas de total.
  final String? total;

  /// Gagnant : ligne en or.
  final bool highlight;

  /// Avatar du joueur ou de l'équipe (#628) : remplace l'initiale dans la pastille.
  final String? avatarId;

  /// État de l'avatar (neutre, heureux, fâché).
  final AvatarState avatarState;

  @override
  Widget build(BuildContext context) {
    final initial = name.isEmpty ? '' : name.substring(0, 1).toUpperCase();
    final avatar = avatarId;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: highlight ? ComicPalette.gold : ComicPalette.paper,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: ComicPalette.ink, width: 3),
        boxShadow: const [
          BoxShadow(color: ComicPalette.ink, offset: Offset(0, 3)),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              border: Border.all(color: ComicPalette.ink, width: 2.5),
            ),
            // Avatar du joueur (#628) à la place de l'initiale, quand il est connu.
            child: avatar != null
                ? ClipOval(
                    child: AvatarView(
                      avatarId: avatar,
                      state: avatarState,
                      size: 28,
                      isActive: false,
                      semanticLabel: name,
                    ),
                  )
                : Text(
                    leading ?? initial,
                    style: TextStyle(
                      color: RoundResultColors.textOn(color),
                      fontFamily: 'Bangers',
                      fontSize: 18,
                    ),
                  ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: ComicPalette.ink,
                    fontWeight: FontWeight.w900,
                    fontSize: 15,
                  ),
                ),
                if (reason != null)
                  Text(
                    reason!,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: ComicPalette.ink,
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  value,
                  maxLines: 1,
                  style: const TextStyle(
                    color: ComicPalette.ink,
                    fontFamily: 'Bangers',
                    fontSize: 28,
                  ),
                ),
              ),
              if (total != null)
                Text(
                  'Total $total',
                  maxLines: 1,
                  style: const TextStyle(
                    color: ComicPalette.ink,
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
