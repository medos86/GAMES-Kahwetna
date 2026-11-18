import 'package:flutter_test/flutter_test.dart';
import 'package:kahwetne/core/services/ad_free_service.dart';
import 'package:kahwetne/core/services/ad_policy.dart';
import 'package:kahwetne/core/services/interstitial_service.dart';

class FakeInterstitial implements InterstitialAdAdapter {
  bool ready = true;
  int shows = 0;

  @override
  bool get loaded => ready;

  @override
  Future<void> load() async => ready = true;

  @override
  Future<void> show() async {
    shows++;
    ready = false;
  }
}

class MemoryAdFreeStore implements AdFreeStore {
  int? value;

  @override
  Future<int?> readExpiry() async => value;

  @override
  Future<void> writeExpiry(int epochMillis) async => value = epochMillis;
}

void main() {
  late DateTime clock;
  late FakeInterstitial ad;
  late AdFreeService adFree;
  late InterstitialService service;

  setUp(() {
    clock = DateTime(2026, 11, 18, 10);
    ad = FakeInterstitial();
    adFree = AdFreeService(store: MemoryAdFreeStore(), now: () => clock);
    service = InterstitialService(
      adapter: ad,
      policy: AdPolicy(
        config: const AdPolicyConfig(minGamesBeforeInterstitial: 2),
        now: () => clock,
      ),
      adFree: adFree,
    );
  });

  test('pas de pub avant la 2e partie terminée (#471)', () async {
    expect(await service.onGameFinished(), isFalse);
    expect(ad.shows, 0);
  });

  test('pub affichée à la 2e partie terminée (#471)', () async {
    await service.onGameFinished();
    expect(await service.onGameFinished(), isTrue);
    expect(ad.shows, 1);
  });

  test('délai de 3 minutes entre deux interstitiels (#471)', () async {
    await service.onGameFinished();
    await service.onGameFinished();
    clock = clock.add(const Duration(minutes: 1));
    expect(await service.onGameFinished(), isFalse);
    clock = clock.add(const Duration(minutes: 3));
    expect(await service.onGameFinished(), isTrue);
    expect(ad.shows, 2);
  });

  test('jamais pendant le mode sans pub (#471)', () async {
    await adFree.activate();
    await service.onGameFinished();
    expect(await service.onGameFinished(), isFalse);
    expect(ad.shows, 0);
  });
}
