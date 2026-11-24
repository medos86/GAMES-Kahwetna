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
    this.iconOnly = false,
  });

  final String label;
  final IconData icon;
  final VoidCallback onTap;
  final bool primary;
  final bool danger;
  final bool enabled;

  /// Icône seule (sans libellé visible) : le libellé reste dans l'infobulle et l'accessibilité (#862).
  final bool iconOnly;

  @override
  Widget build(BuildContext context) {
    final Color background = danger
        ? const Color(0xFFD71920)
        : primary
            ? const Color(0xFFF2B74E)
            : Colors.white;
    final Color foreground = danger ? Colors.white : _ink;
    if (iconOnly) {
      return Semantics(
        button: true,
        enabled: enabled,
        label: label,
        child: Tooltip(
          message: label,
          child: Opacity(
            opacity: enabled ? 1 : 0.4,
            child: Material(
              color: background,
              borderRadius: BorderRadius.circular(10),
              child: InkWell(
                borderRadius: BorderRadius.circular(10),
                onTap: enabled ? onTap : null,
                child: Container(
                  alignment: Alignment.center,
                  constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
                  child: Icon(icon, size: 20, color: foreground),
                ),
              ),
            ),
          ),
        ),
      );
    }
    return Opacity(
      opacity: enabled ? 1 : 0.4,
      child: Material(
        color: background,
        borderRadius: BorderRadius.circular(10),
        child: InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: enabled ? onTap : null,
          child: Container(
            alignment: Alignment.center,
            constraints: const BoxConstraints(minHeight: 30),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 14, color: foreground),
                const SizedBox(width: 4),
                Text(
                  label,
                  style: TextStyle(
                    color: foreground,
                    fontFamily: 'Bangers',
                    letterSpacing: 0.4,
                    fontSize: 12,
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
