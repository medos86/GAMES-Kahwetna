import 'dart:async';

import 'package:material_ui/material_ui.dart';

import 'card_flight.dart';

/// Un vol prévu : [child] part de [from] vers la position courante de [to] (#266).
/// [landingId] : identifiant de la carte qui arrive ; sa case reste vide jusqu'à l'arrivée.
class CardFlight {
  const CardFlight({
    required this.from,
    required this.to,
    required this.child,
    this.delay = Duration.zero,
    this.hold = false,
    this.landingId,
  });

  final Rect from;
  final Rect? Function() to;
  final Widget child;
  final Duration delay;
  final bool hold;
  final String? landingId;
}

/// Case d'arrivée : vide (opacité 0) tant qu'une carte est en route vers elle (#266).
/// La taille ne change pas, donc la position reste mesurable.
class MaskedSlot extends StatelessWidget {
  const MaskedSlot({super.key, required this.hidden, required this.child});

  final bool hidden;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Opacity(opacity: hidden ? 0 : 1, child: child);
  }
}

/// Mouvements de cartes communs à tous les jeux (#266) : un seul code pour
/// Rami, Chkobba, Coinche, Domino et Ludo. Le jeu fournit ses vols, le moteur
/// gère le départ après rendu, le masque d'arrivée et le retrait du masque.
mixin CardMotionMixin<T extends StatefulWidget> on State<T> {
  /// Identifiants des cartes en route : leur case reste vide jusqu'à l'arrivée.
  final Set<String> landing = {};

  /// Lance [flights] après le rendu, quand les destinations existent.
  /// Les cases [CardFlight.landingId] sont masquées dès cet appel.
  void flyAfterRender(List<CardFlight> flights) {
    final ids = flights.map((f) => f.landingId).whereType<String>().toList();
    if (ids.isNotEmpty) {
      if (mounted) setState(() => landing.addAll(ids));
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      for (final flight in flights) {
        final id = flight.landingId;
        final done = flyCard(
          context: context,
          from: flight.from,
          to: flight.to,
          child: flight.child,
          delay: flight.delay,
          hold: flight.hold,
        );
        if (id == null) continue;
        unawaited(
          done.whenComplete(() {
            if (!mounted) return;
            setState(() => landing.remove(id));
          }),
        );
      }
    });
  }
}
