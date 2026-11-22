import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:kahwetne/core/audio/sounds.dart';

/// Durée d'un WAV PCM, lue dans l'en-tête RIFF (chunks fmt et data).
double wavDurationSeconds(Uint8List bytes) {
  final data = ByteData.sublistView(bytes);
  var offset = 12;
  int? byteRate;
  int? dataSize;
  while (offset + 8 <= bytes.length) {
    final id = String.fromCharCodes(bytes.sublist(offset, offset + 4));
    final size = data.getUint32(offset + 4, Endian.little);
    if (id == 'fmt ') byteRate = data.getUint32(offset + 16, Endian.little);
    if (id == 'data') dataSize = size;
    offset += 8 + size + (size.isOdd ? 1 : 0);
  }
  expect(byteRate, isNotNull, reason: 'chunk fmt absent');
  expect(dataSize, isNotNull, reason: 'chunk data absent');
  return dataSize! / byteRate!;
}

void main() {
  // Durées maximales par type de son (cf. issue #790 : un mouvement ne dépasse pas 1 s).
  const maxSeconds = {
    Sfx.place: 1.0,
    Sfx.draw: 1.0,
    Sfx.pass: 1.0,
    Sfx.win: 1.5,
    Sfx.lose: 1.5,
    Sfx.capture: 1.0,
    Sfx.dice: 1.0,
  };

  group('fichiers audio', () {
    // capture et dice sont ajoutés par l'issue #791.
    for (final sfx in Sfx.values.where((s) => s != Sfx.capture && s != Sfx.dice)) {
      test('${sfx.name} existe et respecte sa durée maximale', () {
        final file = File(sfx.assetPath);
        expect(file.existsSync(), isTrue, reason: '${sfx.assetPath} manquant');
        final seconds = wavDurationSeconds(file.readAsBytesSync());
        expect(seconds, lessThanOrEqualTo(maxSeconds[sfx]!),
            reason: '${sfx.assetPath} dure ${seconds.toStringAsFixed(3)} s');
      });
    }
  });
}
