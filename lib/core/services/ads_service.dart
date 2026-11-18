import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

/// Identifiants d'unités publicitaires (issue #465).
///
/// Tant que [useTestIds] est vrai, seuls les identifiants de test Google sont utilisés :
/// aucune vraie pub n'est diffusée, et aucun revenu n'est généré par erreur pendant le développement.
/// Les identifiants de production seront ajoutés à l'issue #466 / publication.
class AdUnitIds {
  const AdUnitIds._();

  /// Passer à `false` seulement avec les identifiants de production.
  static const bool useTestIds = true;

  static const String _testBannerAndroid =
      'ca-app-pub-3940256099942544/6300978111';
  static const String _testBannerIos = 'ca-app-pub-3940256099942544/2934735716';

  static const String _testRewardedAndroid =
      'ca-app-pub-3940256099942544/5224354917';
  static const String _testRewardedIos =
      'ca-app-pub-3940256099942544/1712485313';

  /// Identifiant de bannière pour la plateforme donnée.
  static String banner(TargetPlatform platform) {
    if (!useTestIds) {
      throw StateError(
        'Identifiants de production non configurés (voir #466).',
      );
    }
    return platform == TargetPlatform.iOS ? _testBannerIos : _testBannerAndroid;
  }

  static const String _testInterstitialAndroid =
      'ca-app-pub-3940256099942544/1033173712';
  static const String _testInterstitialIos =
      'ca-app-pub-3940256099942544/4411468910';

  /// Identifiant d'interstitiel entre deux parties (issue #471).
  static String interstitial(TargetPlatform platform) {
    if (!useTestIds) {
      throw StateError(
        'Identifiants de production non configurés (voir #466).',
      );
    }
    return platform == TargetPlatform.iOS
        ? _testInterstitialIos
        : _testInterstitialAndroid;
  }

  /// Identifiant de vidéo récompensée pour la plateforme donnée (issue #470).
  static String rewarded(TargetPlatform platform) {
    if (!useTestIds) {
      throw StateError(
        'Identifiants de production non configurés (voir #466).',
      );
    }
    return platform == TargetPlatform.iOS
        ? _testRewardedIos
        : _testRewardedAndroid;
  }
}

/// Initialise le SDK publicitaire une seule fois (issue #465).
class AdsService {
  AdsService({Future<void> Function()? initializer})
      : _initializer = initializer ?? _defaultInitializer;

  /// Instance partagée par l'application.
  static final AdsService instance = AdsService();

  final Future<void> Function() _initializer;
  Future<void>? _initialization;

  static Future<void> _defaultInitializer() async {
    await MobileAds.instance.initialize();
  }

  /// `true` une fois le SDK initialisé avec succès.
  bool get isInitialized => _initialization != null;

  /// Appels suivants : aucune réinitialisation.
  Future<void> initialize() {
    return _initialization ??= _initializer();
  }
}
