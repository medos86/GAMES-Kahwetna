import 'ad_consent.dart';

/// Public visé par l'application (issue #467).
///
/// - [allAges] : décision actuelle (18/11/2026). Seules les pubs non personnalisées sont servies.
/// - [thirteenPlus] : réglage à réactiver seulement si un juriste valide le seuil et si le consentement UMP est en place.
enum AdAudience { thirteenPlus, allAges }

/// Règles de ciblage selon le public. Logique pure, sans SDK.
///
/// Passer de 13+ à « tous âges » ne change que cette valeur : le reste du code reste identique.
class AdAudienceRules {
  const AdAudienceRules({this.audience = AdAudience.allAges});

  /// Réglage en vigueur.
  static const AdAudienceRules current = AdAudienceRules();

  final AdAudience audience;

  /// `true` seulement si le public est 13+ et que le joueur a accordé son consentement.
  bool allowPersonalizedAds(AdConsentState consent) {
    return audience == AdAudience.thirteenPlus &&
        consent == AdConsentState.granted;
  }
}
