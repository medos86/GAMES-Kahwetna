import 'dart:ui';

import 'package:material_ui/material_ui.dart';

import '../core/theme/comic_palette.dart';

/// Style du récapitulatif (issue #295).
/// Un seul rendu BD désormais : papier, encre noire, titre en Bangers.
/// Les valeurs [comicGreen] et [dark] sont conservées pour compatibilité et rendent le même style BD.
enum ResultDialogStyle {
  /// Style BD (à utiliser pour tout nouvel écran).
  bd,

  /// Ancien style vert comic (obsolète) : rendu identique à [bd].
  comicGreen,

  /// Ancien style sombre (obsolète) : rendu identique à [bd].
  dark,
}

/// Boîte de dialogue de fin de manche / de partie, en style BD (issue #295).
/// Affichée par [ResultDialog.show] sur fond flouté (4 px) et assombri.
class ResultDialog extends StatelessWidget {
  const ResultDialog({
    super.key,
    this.style = ResultDialogStyle.bd,
    required this.title,
    this.icon,
    this.children = const [],
    this.actions = const [],
  });

  final ResultDialogStyle style;
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
