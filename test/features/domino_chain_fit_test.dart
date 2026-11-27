// Zoom et bord du tapis recalculés ensemble (#1028), zoom en largeur seulement (#1036).
import 'package:flutter_test/flutter_test.dart';
import 'package:kahwetne/features/domino/domino_chain_layout.dart';

void main() {
  const width = 360.0;
  final unit = width / 6;

  test('#1028 : la chaîne commence à taille pleine', () {
    final fitted = layoutChainFitted(
      count: 1,
      openIndex: 0,
      width: width,
      unit: unit,
    );
    expect(fitted.scale, 1.0);
  });

  test('#1028 : la chaîne tient toujours en largeur', () {
    for (var n = 1; n <= 60; n++) {
      for (var open = 0; open < n; open += 3) {
        final fitted = layoutChainFitted(
          count: n,
          openIndex: open,
          width: width,
          unit: unit,
        );
        final s = fitted.scale;
        expect(s > 0 && s <= 1.0, isTrue, reason: 'zoom $s (n=$n)');
        var minX = 0;
        var maxX = 0;
        for (final slot in fitted.slots) {
          minX = minX < slot.x ? minX : slot.x;
          maxX = maxX > slot.x + slot.width ? maxX : slot.x + slot.width;
        }
        expect((maxX - minX) * unit * s <= width + 1e-6, isTrue,
            reason: 'débordement en largeur (n=$n, open=$open)');
      }
    }
  });

  test('#1028 : le zoom baisse quand la chaîne grandit', () {
    final few = layoutChainFitted(
      count: 2,
      openIndex: 0,
      width: width,
      unit: unit,
    );
    final many = layoutChainFitted(
      count: 40,
      openIndex: 20,
      width: width,
      unit: unit,
    );
    expect(many.scale < few.scale, isTrue);
  });

  test('#1028 : le bord du tapis suit le zoom', () {
    expect(chainEdgeAtZoom(width: width, unit: unit, zoom: 1.0), 4);
    expect(chainEdgeAtZoom(width: width, unit: unit, zoom: 0.5), 6);
    expect(chainEdgeAtZoom(width: width, unit: unit, zoom: 0.25), 12);
  });
}
