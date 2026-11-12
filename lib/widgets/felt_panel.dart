import 'package:material_ui/material_ui.dart';

/// Tapis vert émeraude à cadre brun (guide §8 : FeltPanel).
class FeltPanel extends StatelessWidget {
  const FeltPanel({
    super.key,
    required this.child,
    this.padding = EdgeInsets.zero,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;

  static const Color _felt = Color(0xFF10B981); // emerald-500
  static const Color _frame = Color(0xFF4A2A10);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: _felt,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: _frame, width: 6),
        // comicShadow(ring: 3, drop: 8, blur: 20)
        boxShadow: const [
          BoxShadow(color: _frame, spreadRadius: 3),
          BoxShadow(color: _frame, spreadRadius: 3, offset: Offset(0, 8)),
          BoxShadow(
            color: Color(0x4D281405),
            spreadRadius: 3,
            blurRadius: 20,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: child,
    );
  }
}
