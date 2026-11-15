part of '../rami_screen.dart';

/// Appui en cours sur une carte de la main ; devient un glisser après [_dragThreshold] px.
class _Press {
  _Press(this.id, this.start);

  final String id;
  final Offset start;
  bool active = false;
}

/// Carte en cours de glisser : position dans le corps de l'écran et cible survolée.
class _Drag {
  const _Drag(this.id, this.local, this.target);

  final String id;
  final Offset local;
  final RamiDropTarget? target;
}
