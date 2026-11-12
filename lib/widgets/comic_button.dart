import 'package:material_ui/material_ui.dart';

/// Variantes des boutons « comic » (guide §8).
enum ComicButtonVariant { white, primary, danger, neutral }

/// Bouton cartoon : bordure épaisse, ombre dure décalée vers le bas.
/// Pressé : décalage vertical de 2 px et ombre supprimée. Désactivé : opacité 0.4.
class ComicButton extends StatefulWidget {
  const ComicButton({
    super.key,
    required this.label,
    this.onPressed,
    this.icon,
    this.variant = ComicButtonVariant.primary,
    this.semanticLabel,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final ComicButtonVariant variant;
  final String? semanticLabel;

  @override
  State<ComicButton> createState() => _ComicButtonState();
}

class _ComicButtonState extends State<ComicButton> {
  bool _pressed = false;

  _Look get _look => switch (widget.variant) {
        ComicButtonVariant.white => const _Look(
            gradient: [Color(0xFFFFFFFF), Color(0xFFFFFFFF)],
            text: Color(0xFF7E22CE),
            shadow: Color(0xFF4A2A10),
          ),
        ComicButtonVariant.primary => const _Look(
            gradient: [Color(0xFFFFE16B), Color(0xFFFFB43C)],
            text: Color(0xFF3D351F),
            shadow: Color(0xFFAE7131),
          ),
        ComicButtonVariant.danger => const _Look(
            gradient: [Color(0xFFFF5A3C), Color(0xFFD71920)],
            text: Color(0xFFFFFFFF),
            shadow: Color(0xFF4A0A0A),
          ),
        ComicButtonVariant.neutral => const _Look(
            gradient: [Color(0xFFFFFFFF), Color(0xFFF1F5F9)],
            text: Color(0xFF15264D),
            shadow: Color(0xFF15264D),
          ),
      };

  void _setPressed(bool value) {
    if (widget.onPressed == null || _pressed == value) return;
    setState(() => _pressed = value);
  }

  @override
  Widget build(BuildContext context) {
    final look = _look;
    final enabled = widget.onPressed != null;
    final pressed = _pressed && enabled;

    final body = AnimatedContainer(
      duration: const Duration(milliseconds: 90),
      transform: Matrix4.translationValues(0, pressed ? 2 : 0, 0),
      constraints: const BoxConstraints(minHeight: 44, minWidth: 44),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: look.gradient),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: look.shadow, width: 3),
        boxShadow: pressed
            ? null
            : [BoxShadow(color: look.shadow, offset: const Offset(0, 4))],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (widget.icon != null) ...[
            Icon(widget.icon, size: 18, color: look.text),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Text(
              widget.label,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'RobotoSlab',
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: look.text,
              ),
            ),
          ),
        ],
      ),
    );

    return Semantics(
      button: true,
      enabled: enabled,
      label: widget.semanticLabel ?? widget.label,
      child: Opacity(
        opacity: enabled ? 1 : 0.4,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTapDown: (_) => _setPressed(true),
          onTapUp: enabled
              ? (_) {
                  _setPressed(false);
                  widget.onPressed!();
                }
              : null,
          onTapCancel: () => _setPressed(false),
          child: body,
        ),
      ),
    );
  }
}

class _Look {
  const _Look({
    required this.gradient,
    required this.text,
    required this.shadow,
  });
  final List<Color> gradient;
  final Color text;
  final Color shadow;
}
