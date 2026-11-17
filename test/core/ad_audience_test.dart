import 'package:flutter_test/flutter_test.dart';
import 'package:kahwetne/core/services/ad_audience.dart';
import 'package:kahwetne/core/services/ad_consent.dart';

void main() {
  test('public 13+ par défaut', () {
    expect(AdAudienceRules.current.audience, AdAudience.thirteenPlus);
  });

  test('13+ avec consentement accordé : pubs personnalisées permises', () {
    const rules = AdAudienceRules();
    expect(rules.allowPersonalizedAds(AdConsentState.granted), isTrue);
  });

  test('13+ sans consentement accordé : pas de pubs personnalisées', () {
    const rules = AdAudienceRules();
    expect(rules.allowPersonalizedAds(AdConsentState.denied), isFalse);
    expect(rules.allowPersonalizedAds(AdConsentState.notRequested), isFalse);
  });

  test('tous âges : jamais de pubs personnalisées, même avec consentement', () {
    const rules = AdAudienceRules(audience: AdAudience.allAges);
    expect(rules.allowPersonalizedAds(AdConsentState.granted), isFalse);
    expect(rules.allowPersonalizedAds(AdConsentState.denied), isFalse);
  });
}
