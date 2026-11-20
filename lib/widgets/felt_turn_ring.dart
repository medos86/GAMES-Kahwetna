import 'package:material_ui/material_ui.dart';

/// Anneau du joueur courant (#643, décision 4) : accent BD fixe, pour tous
/// les jeux. Un indice de forme s'ajoute à la couleur (daltonisme).
///
/// L'anneau ne déplace jamais l'avatar : la taille reste identique qu'il soit
/// actif ou non, pour ne pas recouvrir les cartes du tapis.
class FeltTurnRing extends StatelessWidget {
  const FeltTurnRing({
    super.key,
    required this.active,
    required this.child,
  });

  final bool active;
  final Widget child;

  static const Color accent = Color(0xFFFFD60A);
  static const double ringWidth = 4;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      selected: active,
      child: Container(
        padding: const EdgeInsets.all(ringWidth),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: active ? accent : const Color(0x00000000),
        ),
        child: child,
      ),
    );
  }
}
