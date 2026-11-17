import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// État du consentement publicitaire (issue #466).
///
/// - [notRequested] : le joueur n'a encore rien répondu (ou a retiré son choix).
/// - [granted] : pubs personnalisées autorisées.
/// - [denied] : pubs non personnalisées seulement.
enum AdConsentState { notRequested, granted, denied }

/// Où le choix de consentement est conservé.
abstract interface class AdConsentStore {
  Future<AdConsentState?> read();

  Future<void> write(AdConsentState state);
}

/// Stockage réel : `SharedPreferences`, même mécanisme que le mode sans pub.
class SharedPreferencesAdConsentStore implements AdConsentStore {
  const SharedPreferencesAdConsentStore();

  @override
  Future<AdConsentState?> read() async {
    final prefs = await SharedPreferences.getInstance();
    final name = prefs.getString(ConsentService.prefsKey);
    for (final state in AdConsentState.values) {
      if (state.name == name) return state;
    }
    return null;
  }

  @override
  Future<void> write(AdConsentState state) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(ConsentService.prefsKey, state.name);
  }
}

/// Consentement publicitaire (issue #466).
///
/// Garde le choix du joueur et dit si les pubs personnalisées sont permises.
/// Le SDK UMP et l'alerte ATT iOS viendront s'appuyer sur cet état.
class ConsentService {
  ConsentService({AdConsentStore? store})
      : _store = store ?? const SharedPreferencesAdConsentStore();

  /// Instance partagée par toute l'application.
  static final ConsentService instance = ConsentService();

  /// Clé de conservation du choix.
  static const String prefsKey = 'kahwetne-ad-consent';

  final AdConsentStore _store;
  final ValueNotifier<AdConsentState> _state =
      ValueNotifier<AdConsentState>(AdConsentState.notRequested);

  /// État courant, observable par l'interface (bouton « Confidentialité »).
  ValueListenable<AdConsentState> get state => _state;

  /// `true` seulement si le joueur a accordé le consentement.
  bool get canShowPersonalizedAds => _state.value == AdConsentState.granted;

  /// Relit le choix conservé. À appeler une fois au démarrage.
  Future<void> load() async {
    _state.value = await _store.read() ?? AdConsentState.notRequested;
  }

  /// Le joueur accepte les pubs personnalisées.
  Future<void> grant() => _set(AdConsentState.granted);

  /// Le joueur refuse les pubs personnalisées.
  Future<void> deny() => _set(AdConsentState.denied);

  /// Le joueur retire son choix depuis le menu « Confidentialité ».
  Future<void> withdraw() => _set(AdConsentState.notRequested);

  Future<void> _set(AdConsentState next) async {
    _state.value = next;
    await _store.write(next);
  }
}
