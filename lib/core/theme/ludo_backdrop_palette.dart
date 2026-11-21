import 'package:material_ui/material_ui.dart';

/// Palette du fond bleu du Ludo. Hors des écrans, pour rester sous le
/// ratchet des couleurs en dur (test/style).
abstract final class LudoBackdropPalette {
  static const Color top = Color(0xFF0B4F9C);
  static const Color middle = Color(0xFF1676D2);
  static const Color bottom = Color(0xFF2A8CE6);

  /// Teinte du masque : blanc translucide, le trait de l'image ressort sur le bleu.
  static const Color maskTint = Color(0x33FFFFFF);
}
