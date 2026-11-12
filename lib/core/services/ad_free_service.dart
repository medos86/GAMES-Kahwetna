import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Où l'échéance du mode sans pub est conservée (en millisecondes depuis l'epoch).
abstract interface class AdFreeStore {
  Future<int?> readExpiry();

  Future<void> writeExpiry(int epochMillis);
}

/// Stockage réel : `SharedPreferences` (équivalent du `localStorage` du source React).
class SharedPreferencesAdFreeStore implements AdFreeStore {
  const SharedPreferencesAdFreeStore();

  @override
  Future<int?> readExpiry() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(AdFreeService.prefsKey);
  }

  @override
  Future<void> writeExpiry(int epochMillis) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(AdFreeService.prefsKey, epochMillis);
  }
}

/// Mode sans pub (guide §9.1 et §12.1) : un seul service pour le menu et les cinq jeux.
///
/// - [activate] lance 30 minutes sans bannière et les conserve (survit à un redémarrage).
/// - [active] passe à `true` à l'activation et revient à `false` tout seul à l'expiration.
/// - [load] relit l'échéance conservée ; à appeler une fois au démarrage de l'application.
class AdFreeService {
  AdFreeService({AdFreeStore? store, DateTime Function()? now})
      : _store = store ?? const SharedPreferencesAdFreeStore(),
        _now = now ?? DateTime.now;

  /// Instance partagée par toute l'application.
  static final AdFreeService instance = AdFreeService();

  /// Même clé que le source React.
  static const String prefsKey = 'kahwetne-ad-free-until';

  /// Durée d'une activation.
  static const Duration duration = Duration(minutes: 30);

  final AdFreeStore _store;
  final DateTime Function() _now;
  final ValueNotifier<bool> _active = ValueNotifier<bool>(false);
  DateTime? _expiresAt;
  Timer? _timer;

  /// `true` tant que le mode sans pub est en cours.
  ValueListenable<bool> get active => _active;

  /// Temps restant (zéro quand le mode n'est pas actif).
  Duration get remaining {
    final end = _expiresAt;
    if (end == null) return Duration.zero;
    final left = end.difference(_now());
    return left.isNegative ? Duration.zero : left;
  }

  /// Relit l'échéance conservée. Une échéance déjà passée laisse le mode inactif.
  Future<void> load() async {
    final millis = await _store.readExpiry();
    _setExpiry(
      millis == null ? null : DateTime.fromMillisecondsSinceEpoch(millis),
    );
  }

  /// Active (ou prolonge à 30 minutes pleines) le mode sans pub.
  ///
  /// L'état change tout de suite, la conservation vient ensuite : l'interface n'attend pas le disque.
  Future<void> activate() async {
    final end = _now().add(duration);
    _setExpiry(end);
    await _store.writeExpiry(end.millisecondsSinceEpoch);
  }

  void _setExpiry(DateTime? end) {
    _timer?.cancel();
    _timer = null;
    _expiresAt = end;

    final left = remaining;
    if (left <= Duration.zero) {
      _expiresAt = null;
      _active.value = false;
      return;
    }
    _active.value = true;
    // À l'échéance on réévalue (et non on force à false) : si l'horloge a bougé, le mode se prolonge juste ce qu'il faut.
    _timer = Timer(left, () => _setExpiry(_expiresAt));
  }

  /// Arrête le minuteur (tests ; l'instance partagée vit autant que l'application).
  void dispose() {
    _timer?.cancel();
    _timer = null;
    _active.dispose();
  }
}
