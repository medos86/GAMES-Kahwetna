import 'package:flutter_test/flutter_test.dart';
import 'package:kahwetne/core/app/app_identity.dart';

void main() {
  test('le nom public est Korti Fans', () {
    expect(kAppName, 'Korti Fans');
  });

  test('le nom en majuscules correspond au nom public', () {
    expect(kAppNameUpper, kAppName.toUpperCase());
  });
}
