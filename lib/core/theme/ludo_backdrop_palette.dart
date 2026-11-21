import 'package:material_ui/material_ui.dart';

/// Palette du fond bleu du Ludo (#690). Hors des écrans, pour rester sous le
/// ratchet des couleurs en dur (test/style).
abstract final class LudoBackdropPalette {
  static const Color top = Color(0xFF0B4F9C);
  static const Color middle = Color(0xFF1676D2);
  static const Color bottom = Color(0xFF2A8CE6);

  /// Contour des dés : gris-bleu translucide, jamais noir plein.
  static const Color diceStroke = Color(0x402A3A55);

  /// Points des dés : un peu plus discrets que le contour.
  static const Color pip = Color(0x332A3A55);
}
