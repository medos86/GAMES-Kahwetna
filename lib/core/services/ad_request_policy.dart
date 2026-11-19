import 'package:google_mobile_ads/google_mobile_ads.dart';

import 'ad_audience.dart';
import 'ad_consent.dart';
import 'age_gate_service.dart';

/// Décide si une requête pub est personnalisée (issue #569).
///
/// Personnalisée seulement si les trois conditions sont vraies :
/// - le joueur a répondu « 13 ans ou plus » ([AgeAnswer.thirteenOrOver]) ;
/// - le public retenu est 13+ ([AdAudience.thirteenPlus]) ;
/// - le consentement UMP est accordé ([AdConsentState.granted]).
///
/// Dans tous les autres cas (moins de 13 ans, non répondu, refus, public
/// « tous âges ») la requête est non personnalisée.
bool allowsPersonalizedAds({
  required AgeAnswer age,
  required AdConsentState consent,
  AdAudienceRules rules = AdAudienceRules.current,
}) {
  return age == AgeAnswer.thirteenOrOver &&
      rules.allowPersonalizedAds(consent);
}

/// Requête pub pour la réponse d'âge et le consentement donnés.
AdRequest adRequestFor({
  required AgeAnswer age,
  required AdConsentState consent,
  AdAudienceRules rules = AdAudienceRules.current,
}) {
  final personalized = allowsPersonalizedAds(
    age: age,
    consent: consent,
    rules: rules,
  );
  return AdRequest(nonPersonalizedAds: !personalized);
}

/// Requête pub courante, lue au moment de la demande (bannière, interstitiel,
/// vidéo récompensée).
AdRequest currentAdRequest() {
  return adRequestFor(
    age: AgeGateService.instance.answers.value,
    consent: ConsentService.instance.state.value,
  );
}
