import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kahwetne/core/services/ads_service.dart';

void main() {
  test('SDK initialisé une seule fois', () async {
    var calls = 0;
    final service = AdsService(
      initializer: () async {
        calls++;
      },
    );

    expect(service.isInitialized, isFalse);
    await service.initialize();
    await service.initialize();

    expect(calls, 1);
    expect(service.isInitialized, isTrue);
  });

  test('les identifiants utilisés sont des identifiants de test', () {
    expect(AdUnitIds.useTestIds, isTrue);
    const prefix = 'ca-app-pub-3940256099942544/';
    expect(AdUnitIds.banner(TargetPlatform.android), startsWith(prefix));
    expect(AdUnitIds.banner(TargetPlatform.iOS), startsWith(prefix));
    expect(
      AdUnitIds.banner(TargetPlatform.android),
      isNot(AdUnitIds.banner(TargetPlatform.iOS)),
    );
  });
}
