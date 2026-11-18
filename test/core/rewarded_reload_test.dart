import 'package:flutter_test/flutter_test.dart';
import 'package:kahwetne/core/services/rewarded_video_service.dart';

/// Faux adaptateur : la vidéo n'est prête qu'après un rechargement (issue #504).
class ReloadableRewardedAd implements RewardedAdAdapter {
  bool ready = false;
  int loads = 0;

  @override
  bool get loaded => ready;

  @override
  Future<void> load() async {
    loads++;
    ready = true;
  }

  @override
  Future<bool> show() async {
    ready = false;
    return true;
  }
}

void main() {
  test('watch recharge la vidéo si elle n\'était pas prête (#504)', () async {
    final ad = ReloadableRewardedAd();
    final service = RewardedVideoService(adapter: ad);

    expect(await service.watch(), isTrue);
    expect(ad.loads, 1);
  });
}
