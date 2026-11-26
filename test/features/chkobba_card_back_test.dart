import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter_test/flutter_test.dart';
import 'package:kahwetne/features/chkobba/chkobba_card_face.dart';

void main() {
  test('le dos de carte Chkobba pointe vers un fichier existant', () {
    expect(File(cardBackAsset).existsSync(), isTrue, reason: cardBackAsset);
  });

  test('le dos de carte garde le format 480x707 des faces', () async {
    final bytes = await File(cardBackAsset).readAsBytes();
    final codec = await ui.instantiateImageCodec(bytes);
    final frame = await codec.getNextFrame();
    expect(frame.image.width, 480);
    expect(frame.image.height, 707);
    frame.image.dispose();
  });
}
