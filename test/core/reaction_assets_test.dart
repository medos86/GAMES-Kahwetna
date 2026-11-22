import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Les 9 stickers de réaction BD (#758) : présents, déclarés dans le pubspec.
const List<String> reactionAssetNames = [
  'grrr',
  'hahaha',
  'boouhou',
  'oh_wow',
  'kiss',
  'beerk',
  'eum_hm',
  'aaah_eek',
  'chut_shh',
];

void main() {
  test('chaque sticker de réaction existe', () {
    for (final name in reactionAssetNames) {
      expect(
        File('assets/images/reactions/$name.png').existsSync(),
        isTrue,
        reason: '$name.png manquant',
      );
    }
  });

  test('le dossier reactions est déclaré dans le pubspec', () {
    final pubspec = File('pubspec.yaml').readAsStringSync();
    expect(pubspec, contains('assets/images/reactions/'));
  });
}
