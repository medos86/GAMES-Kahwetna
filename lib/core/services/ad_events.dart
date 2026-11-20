/// Mesure publicitaire sans donnée personnelle (issue #474).
///
/// Chaque événement est émis une seule fois par couple (événement, identifiant de pub).
/// L'identifiant est un compteur local, jamais un identifiant d'utilisateur.
/// Le payload ne contient que le nom de l'événement, l'identifiant de pub et, si besoin, une valeur.
enum AdEvent { impression, click, videoOffer, videoAccepted, videoCompleted, revenue }

/// Clés autorisées dans un payload de mesure. Toute autre clé est interdite (#474).
const Set<String> kAdEventPayloadKeys = {'event', 'adId', 'value'};

class AdEventRecord {
  const AdEventRecord({required this.event, required this.adId, this.value});

  final AdEvent event;
  final String adId;
  final double? value;

  Map<String, Object> toPayload() => {
        'event': event.name,
        'adId': adId,
        if (value != null) 'value': value!,
      };
}

class AdEventTracker {
  AdEventTracker({void Function(AdEventRecord record)? sink})
      : _sink = sink ?? _ignore;

  final void Function(AdEventRecord record) _sink;
  final Set<String> _emitted = <String>{};

  static void _ignore(AdEventRecord _) {}

  /// Émet [event] pour [adId] une seule fois. Retourne `false` si déjà émis ou si [adId] est vide.
  bool track(AdEvent event, String adId, {double? value}) {
    if (adId.isEmpty) return false;
    final key = '${event.name}|$adId';
    if (!_emitted.add(key)) return false;
    _sink(AdEventRecord(event: event, adId: adId, value: value));
    return true;
  }
}
