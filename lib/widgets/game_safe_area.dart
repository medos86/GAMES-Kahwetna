import 'dart:math' as math;

import 'package:material_ui/material_ui.dart';

/// Zone sûre des écrans de jeu (#204).
///
/// En mode immersif la barre d'état est masquée, mais `SafeArea` réserve tout de même
/// sa hauteur : les boutons du haut descendent d'autant. Ici la marge haute est plafonnée
/// à [maxTopInset] : une caméra ou une encoche standard reste sous la marge, sans réserver
/// une bande vide. Valeur à valider sur appareil (voir la PR).
class GameSafeArea extends StatelessWidget {
  const GameSafeArea({super.key, required this.child, this.bottom = true});

  /// Plafond de la marge haute, en dp. À 0 : la caméra centrée du S23 Ultra ne couvre pas les boutons latéraux.
  static const double maxTopInset = 0;

  final Widget child;
  final bool bottom;

  @override
  Widget build(BuildContext context) {
    final top = math.min(MediaQuery.paddingOf(context).top, maxTopInset);
    return SafeArea(
      top: false,
      bottom: bottom,
      child: Padding(
        padding: EdgeInsets.only(top: top),
        child: child,
      ),
    );
  }
}
