import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';

// Issue #976 : l'icône source doit être un PNG carré 1024×1024 (format attendu par
// tool/apply_app_identity.sh pour les icônes Android et iOS).
int _readUint32(Uint8List b, int o) =>
    (b[o] << 24) | (b[o + 1] << 16) | (b[o + 2] << 8) | b[o + 3];

void main() {
  test('app_icon.png est un PNG carré 1024×1024', () {
    final bytes = File('assets/images/app_icon.png').readAsBytesSync();
    final header = bytes.sublist(0, 8);
    expect(header, equals([137, 80, 78, 71, 13, 10, 26, 10]));
    // Le chunk IHDR commence à l'octet 8 : longueur (4), type (4), puis largeur et hauteur.
    final width = _readUint32(bytes, 16);
    final height = _readUint32(bytes, 20);
    expect(width, 1024);
    expect(height, 1024);
  });
}
