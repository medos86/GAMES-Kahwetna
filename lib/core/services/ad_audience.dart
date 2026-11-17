import 'ad_consent.dart';

/// Public visé par l'application (issue #467).
///
/// - [thirteenPlus] : décision actuelle. Pubs personnalisées permises avec consentement.
/// - [allAges] : point de bascule si Google refuse la classification ou si l'app attire les enfants.
///   Seules les pubs non personnalisées sont alors servies.
enum AdAudience { thirteenPlus, allAges }

/// Règles de ciblage selon le public. Logique pure, sans SDK.
///
/// Passer de 13+ à « tous âges » ne change que cette valeur : le reste du code reste identique.
class AdAudienceRules {
  const AdAudienceRules({this.audience = AdAudience.thirteenPlus});

  /// Réglage en vigueur.
  static const AdAudienceRules current = AdAudienceRules();

  final AdAudience audience;

  /// `true` seulement si le public est 13+ et que le joueur a accordé son consentement.
  bool allowPersonalizedAds(AdConsentState consent) {
    return audience == AdAudience.thirteenPlus &&
        consent == AdConsentState.granted;
  }
}
