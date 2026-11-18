// Bouton d'action compact de la table du Rami : petit, avec une icône devant le libellé.
import 'package:material_ui/material_ui.dart';

const _ink = Color(0xFF20284B);

class RamiActionButton extends StatelessWidget {
  const RamiActionButton({
    super.key,
    required this.label,
    required this.icon,
    required this.onTap,
    this.primary = false,
    this.danger = false,
    this.enabled = true,
    this.large = false,
  });

  final String label;
  final IconData icon;
  final VoidCallback onTap;
  final bool primary;
  final bool danger;
  final bool enabled;
  /// Grande cible tactile (>= 48 dp) pour la barre d'actions du tapis (#522).
  final bool large;

  @override
  Widget build(BuildContext context) {
    final Color background = danger
        ? const Color(0xFFD71920)
        : primary
            ? const Color(0xFFF2B74E)
            : Colors.white;
    final Color foreground = danger ? Colors.white : _ink;
    return Opacity(
      opacity: enabled ? 1 : 0.4,
      child: Material(
        color: background,
        borderRadius: BorderRadius.circular(10),
        child: InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: enabled ? onTap : null,
          child: Container(
            constraints: BoxConstraints(minHeight: large ? 48 : 30),
            padding: EdgeInsets.symmetric(
              horizontal: large ? 10 : 8,
              vertical: large ? 10 : 4,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, size: large ? 20 : 14, color: foreground),
                const SizedBox(width: 4),
                Text(
                  label,
                  style: TextStyle(
                    color: foreground,
                    fontFamily: 'Bangers',
                    letterSpacing: 0.4,
                    fontSize: large ? 16 : 12,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
