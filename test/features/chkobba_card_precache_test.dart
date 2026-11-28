// Préchargement des cartes Chkobba (#1082) : les 40 faces et le dos existent
// et sont listés une seule fois, pour que chaque vol ait son image en cache.
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:kahwetne/features/chkobba/chkobba_card_face.dart';

void main() {
  test('41 images : 40 faces et un dos, sans doublon', () {
    final paths = chkobbaCardAssets();
    expect(paths, hasLength(41));
    expect(paths.toSet(), hasLength(41));
  });

  test('chaque image préchargée existe dans assets/', () {
    for (final path in chkobbaCardAssets()) {
      expect(File(path).existsSync(), isTrue, reason: 'manquant : $path');
    }
  });
}
