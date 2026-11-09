import 'package:flutter/material.dart';

/// Palette issue de src/styles/theme.css (:root).
abstract final class AppColors {
  static const Color background = Color(0xFF10234B);
  static const Color foreground = Color(0xFFFFF8E7);
  static const Color primary = Color(0xFFFFD858);
  static const Color primaryForeground = Color(0xFF2A2451);
  static const Color secondary = Color(0xFF2CC4BE);
  static const Color secondaryForeground = Color(0xFF092F42);
  static const Color muted = Color(0xFF263D70);
  static const Color mutedForeground = Color(0xFFBFCAE5);
  static const Color accent = Color(0xFFF2547D);
  static const Color destructive = Color(0xFFD4183D);
  static const Color ring = Color(0xFFFFE681);

  /// `--card: rgba(10, 35, 73, 0.82)`
  static const Color card = Color(0xD10A2349);

  /// `--border: rgba(255, 255, 255, 0.26)`
  static const Color border = Color(0x42FFFFFF);
}
