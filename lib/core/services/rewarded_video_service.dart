import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import 'ad_request_policy.dart';
import 'ads_service.dart';

/// Source d'une vidéo récompensée (issue #470).
///
/// Séparée du SDK pour que la logique de récompense soit testable sans AdMob.
abstract interface class RewardedAdAdapter {
  /// `true` quand une vidéo est prête à être montrée.
  bool get loaded;

  /// Charge la prochaine vidéo. Une erreur laisse [loaded] à `false`.
  Future<void> load();

  /// Montre la vidéo. Renvoie `true` seulement si le joueur l'a regardée jusqu'au bout.
  Future<bool> show();
}

/// Vidéo récompensée réelle via `google_mobile_ads`.
class GoogleRewardedAdAdapter implements RewardedAdAdapter {
  RewardedAd? _ad;

  @override
  bool get loaded => _ad != null;

  @override
  Future<void> load() async {
    try {
      await RewardedAd.load(
        adUnitId: AdUnitIds.rewarded(defaultTargetPlatform),
        request: currentAdRequest(),
        rewardedAdLoadCallback: RewardedAdLoadCallback(
          onAdLoaded: (ad) => _ad = ad,
          onAdFailedToLoad: (_) => _ad = null,
        ),
      );
    } catch (_) {
      // La vidéo est optionnelle : une erreur ne doit jamais bloquer le jeu.
      _ad = null;
    }
  }

  @override
  Future<bool> show() async {
    final ad = _ad;
    if (ad == null) return false;
    _ad = null;

    final done = Completer<bool>();
    var earned = false;

    void finish(bool value) {
      if (!done.isCompleted) done.complete(value);
      load(); // Prépare la vidéo suivante.
    }

    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (a) {
        a.dispose();
        finish(earned);
      },
      onAdFailedToShowFullScreenContent: (a, _) {
        a.dispose();
        finish(false);
      },
    );
    ad.show(onUserEarnedReward: (_, __) => earned = true);
    return done.future;
  }
}

/// Décide si une vidéo récompensée est proposée et accorde la récompense (issue #470).
///
/// Règles : pas de bouton si aucune vidéo n'est prête ; la récompense n'est accordée
/// qu'après visionnage complet.
class RewardedVideoService {
  RewardedVideoService({RewardedAdAdapter? adapter})
      : _adapter = adapter ?? GoogleRewardedAdAdapter();

  /// Instance partagée par l'application.
  static final RewardedVideoService instance = RewardedVideoService();

  final RewardedAdAdapter _adapter;

  /// `true` quand le bouton « regarder une vidéo » peut être affiché.
  final ValueNotifier<bool> ready = ValueNotifier<bool>(false);

  /// `true` si une vidéo est prête maintenant.
  bool get isReady => _adapter.loaded;

  /// Charge une vidéo à l'avance (à appeler au démarrage des écrans concernés).
  Future<void> preload() async {
    await _adapter.load();
    ready.value = _adapter.loaded;
  }

  /// Propose la vidéo au joueur. Renvoie `true` uniquement si la récompense est acquise.
  Future<bool> watch() async {
    // Issue #504 : si la vidéo n'est pas prête, on tente un rechargement avant d'abandonner.
    if (!isReady) await preload();
    if (!isReady) return false;
    final earned = await _adapter.show();
    ready.value = _adapter.loaded;
    return earned;
  }
}
