import 'package:flutter_test/flutter_test.dart';
import 'package:kahwetne/core/services/rewarded_video_service.dart';

/// Faux adaptateur : contrôle si une vidéo est prête et si le joueur la regarde jusqu'au bout.
class FakeRewardedAd implements RewardedAdAdapter {
  FakeRewardedAd({this.ready = true, this.completes = true});

  bool ready;
  bool completes;
  int shows = 0;

  @override
  bool get loaded => ready;

  @override
  Future<void> load() async {}

  @override
  Future<bool> show() async {
    shows++;
    ready = false; // La vidéo est consommée après la lecture.
    return completes;
  }
}

void main() {
  test('pas de récompense quand aucune vidéo n\'est prête', () async {
    final ad = FakeRewardedAd(ready: false);
    final service = RewardedVideoService(adapter: ad);

    expect(service.isReady, isFalse);
    expect(await service.watch(), isFalse);
    expect(ad.shows, 0);
  });

  test('récompense accordée après visionnage complet', () async {
    final ad = FakeRewardedAd(completes: true);
    final service = RewardedVideoService(adapter: ad);

    expect(await service.watch(), isTrue);
    expect(ad.shows, 1);
  });

  test('pas de récompense si la vidéo est fermée avant la fin', () async {
    final ad = FakeRewardedAd(completes: false);
    final service = RewardedVideoService(adapter: ad);

    expect(await service.watch(), isFalse);
  });

  test('preload met à jour le signal de disponibilité', () async {
    final ad = FakeRewardedAd(ready: true);
    final service = RewardedVideoService(adapter: ad);

    await service.preload();
    expect(service.ready.value, isTrue);

    expect(await service.watch(), isTrue);
    expect(service.ready.value, isFalse);
  });
}
