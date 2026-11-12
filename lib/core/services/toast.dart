import 'package:flutter/material.dart';

/// Gravité d'un toast : info (neutre), success (réussite) ou error (action refusée).
enum ToastType { info, success, error }

/// Marge sous le toast : il reste au-dessus de la bannière publicitaire (guide §12.3).
const double kToastBottomMargin = 96;

/// Durée d'affichage.
const Duration kToastDuration = Duration(seconds: 3);

/// Affiche un toast flottant, centré en bas, au-dessus de la bannière.
///
/// Un toast déjà affiché est remplacé tout de suite (pas de file d'attente qui s'allonge
/// quand le joueur enchaîne des actions refusées).
ScaffoldFeatureController<SnackBar, SnackBarClosedReason> showToast(
  BuildContext context,
  String message, {
  String? description,
  ToastType type = ToastType.info,
}) => showToastOn(
  ScaffoldMessenger.of(context),
  message,
  description: description,
  type: type,
);

/// Variante pour du code sans [BuildContext] (par exemple une `GlobalKey<ScaffoldMessengerState>`).
ScaffoldFeatureController<SnackBar, SnackBarClosedReason> showToastOn(
  ScaffoldMessengerState messenger,
  String message, {
  String? description,
  ToastType type = ToastType.info,
}) {
  final accent = _accentOf(type);
  messenger.hideCurrentSnackBar();
  return messenger.showSnackBar(
    SnackBar(
      behavior: SnackBarBehavior.floating,
      margin: const EdgeInsets.fromLTRB(16, 0, 16, kToastBottomMargin),
      duration: kToastDuration,
      backgroundColor: const Color(0xF2101A33),
      elevation: 6,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: accent, width: 1.5),
      ),
      content: Row(
        children: [
          Icon(_iconOf(type), color: accent, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  message,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
                if (description != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(
                      description,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Color(0xB3FFFFFF),
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

Color _accentOf(ToastType type) => switch (type) {
  ToastType.info => const Color(0xFF60A5FA),
  ToastType.success => const Color(0xFF4ADE80),
  ToastType.error => const Color(0xFFF87171),
};

IconData _iconOf(ToastType type) => switch (type) {
  ToastType.info => Icons.info_outline,
  ToastType.success => Icons.check_circle_outline,
  ToastType.error => Icons.error_outline,
};
