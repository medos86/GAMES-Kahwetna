import 'package:flutter_test/flutter_test.dart';
import 'package:kahwetne/core/services/ad_audience.dart';
import 'package:kahwetne/core/services/ad_consent.dart';
import 'package:kahwetne/core/services/ad_request_policy.dart';
import 'package:kahwetne/core/services/age_gate_service.dart';

void main() {
  const thirteenPlus = AdAudienceRules(audience: AdAudience.thirteenPlus);
  const allAges = AdAudienceRules(audience: AdAudience.allAges);

  group('public 13+ (réglage thirteenPlus)', () {
    test('13 ans ou plus + consentement accordé : personnalisée', () {
      expect(
        allowsPersonalizedAds(
          age: AgeAnswer.thirteenOrOver,
          consent: AdConsentState.granted,
          rules: thirteenPlus,
        ),
        isTrue,
      );
      expect(
        adRequestFor(
          age: AgeAnswer.thirteenOrOver,
          consent: AdConsentState.granted,
          rules: thirteenPlus,
        ).nonPersonalizedAds,
        isFalse,
      );
    });

    test('moins de 13 ans : non personnalisée même avec consentement', () {
      expect(
        adRequestFor(
          age: AgeAnswer.underThirteen,
          consent: AdConsentState.granted,
          rules: thirteenPlus,
        ).nonPersonalizedAds,
        isTrue,
      );
    });

    test('âge non répondu : non personnalisée même avec consentement', () {
      expect(
        adRequestFor(
          age: AgeAnswer.unanswered,
          consent: AdConsentState.granted,
          rules: thirteenPlus,
        ).nonPersonalizedAds,
        isTrue,
      );
    });

    test('13+ sans consentement accordé : non personnalisée', () {
      for (final consent in [
        AdConsentState.denied,
        AdConsentState.notRequested,
      ]) {
        expect(
          adRequestFor(
            age: AgeAnswer.thirteenOrOver,
            consent: consent,
            rules: thirteenPlus,
          ).nonPersonalizedAds,
          isTrue,
          reason: 'consentement $consent',
        );
      }
    });
  });

  group('public tous âges (réglage actuel)', () {
    test('même 13+ avec consentement : toujours non personnalisée', () {
      expect(
        adRequestFor(
          age: AgeAnswer.thirteenOrOver,
          consent: AdConsentState.granted,
          rules: allAges,
        ).nonPersonalizedAds,
        isTrue,
      );
    });

    test('réglage par défaut : 13+ consentant personnalisée', () {
      expect(
        adRequestFor(
          age: AgeAnswer.thirteenOrOver,
          consent: AdConsentState.granted,
        ).nonPersonalizedAds,
        isFalse,
      );
    });
  });
}
