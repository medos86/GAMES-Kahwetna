import 'package:flutter_test/flutter_test.dart';
import 'package:kahwetne/core/services/ad_policy.dart';

void main() {
  late DateTime clock;
  late AdPolicy policy;

  setUp(() {
    clock = DateTime(2026, 11, 17, 10);
    policy = AdPolicy(now: () => clock);
  });

  AdPolicy withConfig(AdPolicyConfig config) =>
      AdPolicy(config: config, now: () => clock);

  test('aucune pub avant le nombre minimal de parties', () {
    final twoGames = withConfig(
      const AdPolicyConfig(minGamesBeforeInterstitial: 2),
    );
    expect(twoGames.canShowInterstitial(duringTurn: false), isFalse);
    twoGames.recordGameFinished();
    expect(twoGames.canShowInterstitial(duringTurn: false), isFalse);
    twoGames.recordGameFinished();
    expect(twoGames.canShowInterstitial(duringTurn: false), isTrue);
  });

  test('pub dès la première partie terminée par défaut (#520)', () {
    expect(policy.canShowInterstitial(duringTurn: false), isFalse);
    policy.recordGameFinished();
    expect(policy.canShowInterstitial(duringTurn: false), isTrue);
  });

  test('jamais pendant un tour, même après assez de parties', () {
    policy.recordGameFinished();
    policy.recordGameFinished();
    expect(policy.canShowInterstitial(duringTurn: true), isFalse);
    expect(policy.canShowInterstitial(duringTurn: false), isTrue);
  });

  test('le cooldown bloque un second interstitiel trop tôt', () {
    policy.recordGameFinished();
    policy.recordGameFinished();
    policy.recordInterstitialShown();

    clock = clock.add(const Duration(minutes: 2));
    expect(policy.canShowInterstitial(duringTurn: false), isFalse);

    clock = clock.add(const Duration(minutes: 1));
    expect(policy.canShowInterstitial(duringTurn: false), isTrue);
  });

  test('le plafond par session est respecté', () {
    final capped = withConfig(
      const AdPolicyConfig(
        minGamesBeforeInterstitial: 0,
        interstitialCooldown: Duration.zero,
        maxInterstitialsPerSession: 2,
      ),
    );
    expect(capped.canShowInterstitial(duringTurn: false), isTrue);
    capped.recordInterstitialShown();
    capped.recordInterstitialShown();
    expect(capped.canShowInterstitial(duringTurn: false), isFalse);
  });

  test('resetSession remet les compteurs et le cooldown à zéro', () {
    policy.recordGameFinished();
    policy.recordGameFinished();
    policy.recordInterstitialShown();
    expect(policy.gamesFinished, 2);
    expect(policy.interstitialsShown, 1);

    policy.resetSession();

    expect(policy.gamesFinished, 0);
    expect(policy.interstitialsShown, 0);
    expect(policy.canShowInterstitial(duringTurn: false), isFalse);
  });

  test('les compteurs sont exposés en lecture', () {
    expect(policy.gamesFinished, 0);
    policy.recordGameFinished();
    expect(policy.gamesFinished, 1);
    policy.recordInterstitialShown();
    expect(policy.interstitialsShown, 1);
  });
}
