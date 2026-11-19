import 'ad_consent.dart';

/// Public visé par l'application (issue #467).
///
/// - [thirteenPlus] : réglage actuel (19/11/2026, décision du responsable du projet).
///   Pubs personnalisées seulement pour les 13+ ayant consenti via UMP. Avis juridique
///   (#575) non obtenu : à valider avant mise en production.
/// - [allAges] : ancien réglage (18/11/2026). Seules les pubs non personnalisées sont servies.
enum AdAudience { thirteenPlus, allAges }

/// Règles de ciblage selon le public. Logique pure, sans SDK.
///
/// Passer de 13+ à « tous âges » ne change que cette valeur : le reste du code reste identique.
class AdAudienceRules {
  const AdAudienceRules({this.audience = AdAudience.thirteenPlus});

  /// Réglage en vigueur.
  static const AdAudienceRules current =
      AdAudienceRules(audience: AdAudience.thirteenPlus);

  final AdAudience audience;

  /// `true` seulement si le public est 13+ et que le joueur a accordé son consentement.
  bool allowPersonalizedAds(AdConsentState consent) {
    return audience == AdAudience.thirteenPlus &&
        consent == AdConsentState.granted;
  }
}
