import 'dart:math' as math;

/// Respiration du joueur actif, t de 0 à 1 sur un cycle : de 1 à 1,05 et retour (#665).
/// Pur Dart, partagé par le Ludo (#665) et le Chkobba (#728).
double turnAvatarBreathScale(double t) =>
    1 + 0.05 * (1 - math.cos(2 * math.pi * t)) / 2;
