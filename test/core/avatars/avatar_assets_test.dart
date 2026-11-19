import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Issue #540 : les 48 avatars (16 personnages × 3 états) sont présents, légers et déclarés.
const _ids = [
  'boy_tn',
  'girl_scarf',
  'young_man',
  'girl_hat',
  'boy_glasses',
  'redhead',
  'man_keffiyeh',
  'woman_hijab',
  'lion',
  'horse',
  'camel',
  'dolphin',
  'panda',
  'penguin',
  'tiger',
  'cat',
];

const _states = [
  'neutral',
  'happy',
  'angry',
];

void main() {
  test('les 48 fichiers webp existent', () {
    for (final state in _states) {
      for (final id in _ids) {
        final file = File('assets/images/avatars/$state/$id.webp');
        expect(file.existsSync(), isTrue, reason: file.path);
      }
    }
  });

  test('chaque avatar fait moins de 15 Ko', () {
    for (final state in _states) {
      for (final id in _ids) {
        final file = File('assets/images/avatars/$state/$id.webp');
        expect(
          file.lengthSync(),
          lessThan(15 * 1024),
          reason: '$state/$id',
        );
      }
    }
  });

  test('les dossiers d\'états sont déclarés dans pubspec.yaml', () {
    final pubspec = File('pubspec.yaml').readAsStringSync();
    for (final state in _states) {
      expect(pubspec, contains('assets/images/avatars/$state/'));
    }
  });
}
