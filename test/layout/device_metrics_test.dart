import 'package:flutter_test/flutter_test.dart';
import 'package:kahwetne/core/layout/device_metrics.dart';

// Valeurs calculées à partir des formules CSS du source React.
// Recalculées en Python (scratchpad/css_check.py) pour chaque appareil de référence.
void main() {
  group('Mode compact (portrait et largeur <= 600)', () {
    test('Galaxy S24 360x780', () {
      const m = DeviceMetrics(width: 360, height: 780);
      expect(m.isCompact, isTrue);
      expect(m.gameUnit, closeTo(14.0, 0.01));
      expect(m.ramiHandCardWidth, closeTo(48.6, 0.01));
      expect(m.coincheCardWidth, closeTo(53.57, 0.01));
    });

    test('iPhone 15 393x852', () {
      const m = DeviceMetrics(width: 393, height: 852);
      expect(m.isCompact, isTrue);
      expect(m.gameUnit, closeTo(14.0, 0.01));
      expect(m.ramiHandCardWidth, closeTo(53.06, 0.01));
    });

    test(
      'iPhone Pro Max 430x932 : la taille de base monte jusqu\'à 1.125rem',
      () {
        const m = DeviceMetrics(width: 430, height: 932);
        expect(m.isCompact, isTrue);
        expect(m.gameUnit, closeTo(15.05, 0.01));
      },
    );
  });

  group('Paysage ou grand écran (pas compact)', () {
    test('Paysage 852x393 utilise la formule vmin', () {
      const m = DeviceMetrics(width: 852, height: 393);
      expect(m.isCompact, isFalse);
      // 2vmin = 7.86px, borné à 12px (0.75rem)
      expect(m.gameUnit, closeTo(12.0, 0.01));
    });

    test('Paysage 640x360 : la carte Coinche atteint sa taille max', () {
      const m = DeviceMetrics(width: 640, height: 360);
      expect(m.isCompact, isFalse);
      expect(m.coincheCardWidth, closeTo(72.0, 0.01));
    });

    test('Tablette portrait 768x1024 : pas compact car largeur > 600', () {
      const m = DeviceMetrics(width: 768, height: 1024);
      expect(m.isCompact, isFalse);
    });
  });

  test('bascule exacte à 600 px', () {
    expect(const DeviceMetrics(width: 600, height: 900).isCompact, isTrue);
    expect(const DeviceMetrics(width: 601, height: 900).isCompact, isFalse);
  });
}
