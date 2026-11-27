import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:kahwetne/features/rami/rami_card_view.dart';

/// Issue #1056 : toutes les faces et tous les dos Rami sont préchargés,
/// et chacun correspond à un fichier réel du dépôt.
void main() {
  test('56 images listées une seule fois', () {
    final assets = ramiCardAssets();
    expect(assets.length, 56);
    expect(assets.toSet().length, 56);
  });

  test('chaque image préchargée existe sur le disque', () {
    for (final asset in ramiCardAssets()) {
      expect(File(asset).existsSync(), isTrue, reason: 'manquant : $asset');
    }
  });
}
