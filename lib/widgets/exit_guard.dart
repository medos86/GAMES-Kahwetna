import 'package:flutter/material.dart';

import '../core/strings.dart';
import '../core/theme/comic_palette.dart';
import 'comic/comic_panel.dart';
import 'comic_button.dart';

/// Retour système sur un écran de jeu (#117) : si une partie est en cours, demande
/// confirmation avant de quitter. Le bouton Menu passe aussi par ici.
class ExitGuard extends StatelessWidget {
  const ExitGuard({super.key, required this.active, required this.child});

  /// Vrai tant que la partie n'est pas terminée.
  final bool active;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !active,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        final leave = await showLeaveGameDialog(context);
        if (leave == true && context.mounted) Navigator.of(context).pop();
      },
      child: child,
    );
  }
}

/// Dialogue « Quitter la partie ? ». Renvoie true si le joueur confirme.
Future<bool?> showLeaveGameDialog(BuildContext context) => showLeaveDialog(
  context,
  title: Strings.exitGameTitle,
  body: Strings.exitGameBody,
);

/// Dialogue de confirmation de sortie, générique (partie ou application).
Future<bool?> showLeaveDialog(
  BuildContext context, {
  required String title,
  required String body,
}) => showConfirmDialog(
  context,
  title: title,
  body: body,
  cancelLabel: Strings.exitStay,
  confirmLabel: Strings.exitLeave,
);

/// Dialogue à deux choix. Renvoie true si le bouton de confirmation est pressé.
Future<bool?> showConfirmDialog(
  BuildContext context, {
  required String title,
  required String body,
  required String cancelLabel,
  required String confirmLabel,
  ComicButtonVariant confirmVariant = ComicButtonVariant.danger,
  bool dismissible = true,
}) {
  return showDialog<bool>(
    context: context,
    barrierDismissible: dismissible,
    builder: (ctx) => Dialog(
      backgroundColor: ComicPalette.paper.withAlpha(0),
      insetPadding: const EdgeInsets.all(24),
      child: ComicPanel(
        color: ComicPalette.paper,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontFamily: 'Bangers',
                fontSize: 28,
                color: ComicPalette.ink,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              body,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16, color: ComicPalette.ink),
            ),
            const SizedBox(height: 16),
            ComicButton(
              label: cancelLabel,
              variant: ComicButtonVariant.neutral,
              onPressed: () => Navigator.of(ctx).pop(false),
            ),
            const SizedBox(height: 8),
            ComicButton(
              label: confirmLabel,
              variant: confirmVariant,
              onPressed: () => Navigator.of(ctx).pop(true),
            ),
          ],
        ),
      ),
    ),
  );
}
