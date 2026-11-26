import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:kahwetne/core/audio/sounds.dart';

/// Échantillons PCM 16 bits mono d'un WAV, normalisés entre -1 et 1 (issue #968).
Float64List samplesOf(Uint8List bytes) {
  final data = ByteData.sublistView(bytes);
  var offset = 12;
  int? dataStart;
  int? dataSize;
  while (offset + 8 <= bytes.length) {
    final id = String.fromCharCodes(bytes.sublist(offset, offset + 4));
    final size = data.getUint32(offset + 4, Endian.little);
    if (id == 'data') {
      dataStart = offset + 8;
      dataSize = size;
    }
    offset += 8 + size + (size.isOdd ? 1 : 0);
  }
  expect(dataStart, isNotNull, reason: 'chunk data absent');
  final count = dataSize! ~/ 2;
  final out = Float64List(count);
  for (var i = 0; i < count; i++) {
    out[i] = data.getInt16(dataStart! + i * 2, Endian.little) / 32768;
  }
  return out;
}

void main() {
  for (final sfx in Sfx.values) {
    group(sfx.name, () {
      final bytes = File(sfx.assetPath).readAsBytesSync();
      final samples = samplesOf(bytes);

      test('pas d écrêtage : crête sous 0 dBFS avec marge', () {
        var peak = 0.0;
        for (final s in samples) {
          if (s.abs() > peak) peak = s.abs();
        }
        expect(peak, lessThanOrEqualTo(0.5));
      });

      test('fin en fondu : les 10 dernières ms sont silencieuses', () {
        const tail = 441; // 10 ms à 44,1 kHz
        var sum = 0.0;
        for (var i = samples.length - tail; i < samples.length; i++) {
          sum += samples[i] * samples[i];
        }
        expect(sum / tail, lessThan(1e-6));
      });

      test('début sans clic : premier échantillon quasi nul', () {
        expect(samples.first.abs(), lessThan(1e-3));
      });
    });
  }
}
