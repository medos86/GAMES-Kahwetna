import 'dart:ui';

import 'package:flutter/material.dart';

/// Deux styles de récapitulatif (guide §8).
enum ResultDialogStyle {
  /// Vert comic : Chkobba, Coinche, Rami.
  comicGreen,

  /// Sombre : Domino, Ludo.
  dark,
}

/// Boîte de dialogue de fin de manche / de partie.
/// Affichée par [ResultDialog.show] sur fond flouté (4 px) et assombri.
class ResultDialog extends StatelessWidget {
  const ResultDialog({
    super.key,
    required this.style,
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
    final isGreen = style == ResultDialogStyle.comicGreen;
    final background =
        isGreen ? const Color(0xFF059669) : const Color(0xFF0B3F7A);
    final border = isGreen ? const Color(0xFF000000) : const Color(0xFFFFD653);
    final titleColor = isGreen ? Colors.white : const Color(0xFFFFE681);

    return Material(
      color: Colors.transparent,
      child: Container(
        margin: const EdgeInsets.all(24),
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
        constraints: const BoxConstraints(maxWidth: 420),
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: border, width: 4),
          boxShadow: isGreen
              ? const [BoxShadow(color: Colors.black, offset: Offset(0, 7))]
              : null,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (icon != null) Icon(icon, size: 40, color: titleColor),
              Text(
                title,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'RobotoSlab',
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                  color: titleColor,
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
