/// Réglages de la politique publicitaire (issue #468).
class AdPolicyConfig {
  const AdPolicyConfig({
    this.minGamesBeforeInterstitial = 2,
    this.interstitialCooldown = const Duration(minutes: 3),
    this.maxInterstitialsPerSession = 3,
  });

  /// Nombre de parties terminées avant la première pub entre deux parties.
  final int minGamesBeforeInterstitial;

  /// Délai minimal entre deux interstitiels.
  final Duration interstitialCooldown;

  /// Plafond d'interstitiels par session de jeu.
  final int maxInterstitialsPerSession;
}

/// Décide quand un interstitiel peut apparaître, pour ne pas frustrer le joueur.
///
/// Logique pure : aucun SDK, horloge injectée pour les tests.
/// Règles : pas avant [AdPolicyConfig.minGamesBeforeInterstitial] parties,
/// pas pendant un tour, pas avant le délai de [AdPolicyConfig.interstitialCooldown],
/// et au plus [AdPolicyConfig.maxInterstitialsPerSession] par session.
class AdPolicy {
  AdPolicy({this.config = const AdPolicyConfig(), DateTime Function()? now})
      : _now = now ?? DateTime.now;

  final AdPolicyConfig config;
  final DateTime Function() _now;

  int _gamesFinished = 0;
  int _interstitialsShown = 0;
  DateTime? _lastInterstitialAt;

  /// Parties terminées dans la session courante.
  int get gamesFinished => _gamesFinished;

  /// Interstitiels déjà affichés dans la session courante.
  int get interstitialsShown => _interstitialsShown;

  /// À appeler à la fin de chaque partie.
  void recordGameFinished() {
    _gamesFinished++;
  }

  /// `true` si un interstitiel peut être affiché maintenant.
  ///
  /// [duringTurn] : `true` si une manche ou un tour est en cours. Dans ce cas, jamais de pub.
  bool canShowInterstitial({required bool duringTurn}) {
    if (duringTurn) return false;
    if (_gamesFinished < config.minGamesBeforeInterstitial) return false;
    if (_interstitialsShown >= config.maxInterstitialsPerSession) return false;
    final last = _lastInterstitialAt;
    if (last != null &&
        _now().difference(last) < config.interstitialCooldown) {
      return false;
    }
    return true;
  }

  /// À appeler une fois l'interstitiel réellement affiché.
  void recordInterstitialShown() {
    _interstitialsShown++;
    _lastInterstitialAt = _now();
  }

  /// Repart de zéro (nouvelle session).
  void resetSession() {
    _gamesFinished = 0;
    _interstitialsShown = 0;
    _lastInterstitialAt = null;
  }
}
