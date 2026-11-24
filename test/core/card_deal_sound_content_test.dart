import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';

/// Nombre de fronts d'attaque dans l'enveloppe d'un WAV PCM 16 bits mono (#847).
int countOnsets(Uint8List bytes) {
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
  final samples = dataSize! ~/ 2;
  const window = 220;
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
  final threshold = peak * 0.15;
  var onsets = 0;
  var above = false;
  for (final e in envelope) {
    if (e > threshold && !above) onsets++;
    above = e > threshold;
  }
  return onsets;
}

void main() {
  test('card_deal.wav : plusieurs cartes distribuées, pas un son unique', () {
    final bytes = File('assets/sounds/cards/card_deal.wav').readAsBytesSync();
    expect(countOnsets(bytes), greaterThanOrEqualTo(5));
  });
}
