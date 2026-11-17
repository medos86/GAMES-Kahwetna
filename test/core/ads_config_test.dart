import 'package:flutter_test/flutter_test.dart';
import 'package:kahwetne/core/services/ads_config.dart';

void main() {
  test('les App IDs AdMob ont le format attendu', () {
    final pattern = RegExp(r'^ca-app-pub-\d{16}~\d{10}$');
    expect(pattern.hasMatch(AdAppIds.android), isTrue);
    expect(pattern.hasMatch(AdAppIds.ios), isTrue);
    expect(AdAppIds.android, isNot(AdAppIds.ios));
  });
}
