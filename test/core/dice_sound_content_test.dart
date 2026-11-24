import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';

/// Compte les claquements d'un WAV PCM 16 bits mono : fronts montants de l'enveloppe (#846).
int countClicks(Uint8List bytes) {
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
  final samples = (dataSize! ~/ 2);
  const window = 220; // ~5 ms à 44,1 kHz
  final envelope = <double>[];
  for (var w = 0; w + window <= samples; w += window) {
    var sum = 0.0;
    for (var i = 0; i < window; i++) {
      final s = data.getInt16(dataStart! + (w + i) * 2, Endian.little) / 32768;
      sum += s * s;
    }
    envelope.add(sum / window);
  }
  final peak = envelope.reduce((a, b) => a > b ? a : b);
  final threshold = peak * 0.12;
  var clicks = 0;
  var above = false;
  for (final e in envelope) {
    if (e > threshold && !above) clicks++;
    above = e > threshold;
  }
  return clicks;
}

void main() {
  test('dice.wav : une série de claquements de dés, pas un son continu', () {
    final bytes = File('assets/sounds/common/dice.wav').readAsBytesSync();
    expect(countClicks(bytes), greaterThanOrEqualTo(8));
  });
}
