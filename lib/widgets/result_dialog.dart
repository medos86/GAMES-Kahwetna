import 'dart:ui';

import 'package:material_ui/material_ui.dart';

import '../core/theme/comic_palette.dart';

/// Boîte de dialogue de fin de manche / de partie, en style BD (issue #295).
/// Affichée par [ResultDialog.show] sur fond flouté (4 px) et assombri.
class ResultDialog extends StatelessWidget {
  const ResultDialog({
    super.key,
    required this.title,
    this.icon,
    this.children = const [],
    this.actions = const [],
  });

  final String title;
  final IconData? icon;
  final List<Widget> children;
  final List<Widget> actions;

  /// Ouvre le dialogue. Non fermable en touchant l'extérieur (sauf [dismissible]).
  static Future<T?> show<T>(
    BuildContext context, {
    required WidgetBuilder builder,
    bool dismissible = false,
  }) {
    return showGeneralDialog<T>(
      context: context,
      barrierDismissible: dismissible,
      barrierLabel: 'Fermer',
      barrierColor: Colors.transparent,
      transitionDuration: const Duration(milliseconds: 200),
      pageBuilder: (ctx, _, __) => Stack(
        children: [
          Positioned.fill(
            child: GestureDetector(
              onTap: dismissible ? () => Navigator.of(ctx).maybePop() : null,
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 4, sigmaY: 4),
                child: const ColoredBox(color: Color(0x99000000)),
              ),
            ),
          ),
          Center(child: builder(ctx)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Container(
        margin: const EdgeInsets.all(24),
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
        constraints: const BoxConstraints(maxWidth: 420),
        decoration: BoxDecoration(
          color: ComicPalette.paper,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: ComicPalette.ink, width: 4),
          boxShadow: const [
            BoxShadow(color: ComicPalette.ink, offset: Offset(0, 7)),
          ],
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (icon != null) Icon(icon, size: 40, color: ComicPalette.ink),
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontFamily: 'Bangers',
                  fontSize: 32,
                  letterSpacing: 1,
                  color: ComicPalette.ink,
                ),
              ),
              const SizedBox(height: 12),
              ...children,
              if (actions.isNotEmpty) ...[
                const SizedBox(height: 16),
                ...actions
                    .expand((w) => [w, const SizedBox(height: 10)])
                    .toList()
                  ..removeLast(),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Formate une variation de score avec son signe : +100, -10, 0.
String signedScore(int value) => value > 0 ? '+$value' : '$value';

/// Carte de score d'un joueur ou d'une équipe dans un [ResultDialog] (issue #295).
/// Affiche le nom, la variation signée, le motif éventuel et le total.
class ResultScoreBox extends StatelessWidget {
  const ResultScoreBox({
    super.key,
    required this.name,
    required this.value,
    required this.total,
    this.reason,
    this.highlight = false,
  });

  final String name;
  final String value;
  final String total;
  final String? reason;
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 3),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: highlight ? ComicPalette.gold : ComicPalette.paper,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: ComicPalette.ink, width: 3),
      ),
      child: Column(
        children: [
          Text(
            name.toUpperCase(),
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: ComicPalette.ink,
              fontWeight: FontWeight.w900,
              fontSize: 11,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              color: ComicPalette.ink,
              fontFamily: 'Bangers',
              fontSize: 26,
            ),
          ),
          if (reason != null)
            Text(
              reason!,
              textAlign: TextAlign.center,
              style: const TextStyle(color: ComicPalette.ink, fontSize: 10),
            ),
          Text(
            'Total $total',
            style: const TextStyle(color: ComicPalette.ink, fontSize: 10),
          ),
        ],
      ),
    );
  }
}

