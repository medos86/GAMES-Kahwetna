import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Conformité du style (issue #64, skill kahwetne-cartoon-tunisien).
/// Les couleurs doivent venir de lib/core/theme. Cliquet : le nombre de couleurs
/// écrites en dur hors du thème ne doit pas augmenter (référence : style_baseline.txt).
/// Quand une couleur est migrée vers le thème, baisser la référence.
final _rawColor = RegExp(r'Color\(0x[0-9A-Fa-f]{8}\)|Colors\.[a-zA-Z]+');

void main() {
  test('pas de nouvelle couleur écrite en dur hors de lib/core/theme', () {
    var count = 0;
    final offenders = <String, int>{};
    for (final file in Directory('lib').listSync(recursive: true).whereType<File>()) {
      final path = file.path.replaceAll('\\', '/');
      if (!path.endsWith('.dart') || path.startsWith('lib/core/theme/')) continue;
      final n = _rawColor.allMatches(file.readAsStringSync()).length;
      if (n > 0) {
        count += n;
        offenders[path] = n;
      }
    }
    final baseline = int.parse(File('test/style/style_baseline.txt').readAsStringSync().trim());
    expect(
      count,
      lessThanOrEqualTo(baseline),
      reason: 'Couleurs en dur : $count (référence $baseline). Utiliser lib/core/theme. Détail : $offenders',
    );
  });
}
