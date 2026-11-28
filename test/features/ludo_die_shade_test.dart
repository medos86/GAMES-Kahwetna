import 'package:flutter_test/flutter_test.dart';
import 'package:kahwetne/features/ludo/ludo_screen.dart';

void main() {
  test('#1072 : une face en pleine lumière n a pas d ombre', () {
    expect(ludoDieShade(1.0), 0.0);
  });

  test('#1072 : une face de biais est la plus sombre', () {
    expect(ludoDieShade(0.0), kLudoDieMaxShade);
  });

  test('#1072 : l ombre reste entre 0 et le maximum', () {
    final mid = ludoDieShade(0.5);
    expect(mid, greaterThan(0));
    expect(mid, lessThan(kLudoDieMaxShade));
    expect(ludoDieShade(2.0), 0.0);
    expect(ludoDieShade(-1.0), kLudoDieMaxShade);
  });
}
