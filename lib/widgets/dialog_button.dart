import 'package:material_ui/material_ui.dart';

import '../core/theme/comic_palette.dart';

/// Bouton plein pleine largeur des boîtes de dialogue de fin de manche (issue #303).
/// Remplace les copies identiques de Rami et de Coinche.
class DialogButton extends StatelessWidget {
  const DialogButton({super.key, required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: FilledButton(
        style: FilledButton.styleFrom(
          backgroundColor: ComicPalette.gold,
          foregroundColor: ComicPalette.goldInk,
          padding: const EdgeInsets.symmetric(vertical: 14),
        ),
        onPressed: onTap,
        child: Text(label, style: const TextStyle(fontWeight: FontWeight.w900)),
      ),
    );
  }
}
