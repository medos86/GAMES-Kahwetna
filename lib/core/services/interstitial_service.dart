import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import 'ad_request_policy.dart';
import 'ad_free_service.dart';
import 'ad_policy.dart';
import 'ads_service.dart';

/// Source d'un interstitiel (issue #471). Séparée du SDK pour être testable.
abstract interface class InterstitialAdAdapter {
  bool get loaded;

  /// Charge le prochain interstitiel. Une erreur laisse [loaded] à `false`.
  Future<void> load();

  /// Montre l'interstitiel ; se termine quand il est fermé ou en échec.
  Future<void> show();
}

/// Interstitiel réel via `google_mobile_ads`.
class GoogleInterstitialAdAdapter implements InterstitialAdAdapter {
  InterstitialAd? _ad;

  @override
  bool get loaded => _ad != null;

  @override
  Future<void> load() async {
    try {
      await InterstitialAd.load(
        adUnitId: AdUnitIds.interstitial(defaultTargetPlatform),
        request: currentAdRequest(),
        adLoadCallback: InterstitialAdLoadCallback(
          onAdLoaded: (ad) => _ad = ad,
          onAdFailedToLoad: (_) => _ad = null,
        ),
      );
    } catch (_) {
      // Optionnel : une erreur ne doit jamais bloquer le jeu.
      _ad = null;
    }
  }

  @override
  Future<void> show() async {
    final ad = _ad;
    if (ad == null) return;
    _ad = null;

    final done = Completer<void>();
    void finish() {
      if (!done.isCompleted) done.complete();
      load(); // Prépare le suivant.
    }

    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (a) {
        a.dispose();
        finish();
      },
      onAdFailedToShowFullScreenContent: (a, _) {
        a.dispose();
        finish();
      },
    );
    ad.show();
    return done.future;
  }
}

/// Affiche l'interstitiel entre deux parties, selon [AdPolicy] (issue #471).
///
/// Jamais pendant le mode sans pub. Appelé une fois par partie terminée.
class InterstitialService {
  InterstitialService({
    InterstitialAdAdapter? adapter,
    AdPolicy? policy,
    AdFreeService? adFree,
  })  : _adapter = adapter ?? GoogleInterstitialAdAdapter(),
        _policy = policy ?? AdPolicy(),
        _adFree = adFree ?? AdFreeService.instance;

  /// Instance partagée par l'application.
  static final InterstitialService instance = InterstitialService();

  final InterstitialAdAdapter _adapter;
  final AdPolicy _policy;
  final AdFreeService _adFree;

  /// Charge un interstitiel à l'avance.
  Future<void> preload() => _adapter.load();

  /// À appeler à la fin de chaque partie. Renvoie `true` si une pub a été montrée.
  Future<bool> onGameFinished() async {
    _policy.recordGameFinished();
    if (_adFree.active.value) return false;
    if (!_policy.canShowInterstitial(duringTurn: false)) return false;
    if (!_adapter.loaded) {
      await _adapter.load();
      if (!_adapter.loaded) return false;
    }
    await _adapter.show();
    _policy.recordInterstitialShown();
    return true;
  }
}
