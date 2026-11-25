part of '../rami_screen.dart';

/// Appui en cours sur une carte de la main ; devient un glisser après [_dragThreshold] px.
class _Press {
  _Press(this.id, this.start, {this.fromMeld, this.card});

  final String id;
  final Offset start;
  // Paquet posé pendant le tour d'où vient la carte (#898) ; null pour la main.
  final String? fromMeld;
  final rules.RamiCard? card;
  bool active = false;
}

/// Carte en cours de glisser : position dans le corps de l'écran et cible survolée.
class _Drag {
  const _Drag(this.id, this.local, this.target, {this.card});

  final String id;
  final Offset local;
  final RamiDropTarget? target;
  // Carte glissée hors de la main (paquet du tapis, #898).
  final rules.RamiCard? card;
}
