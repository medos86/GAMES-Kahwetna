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

/// Pic absolu et RMS des 10 dernières ms du WAV (fin sans coupure brutale, #966).
double tailRms(Uint8List bytes) {
  final data = ByteData.sublistView(bytes);
  final samples = (bytes.length - 44) ~/ 2;
  const tail = 441; // 10 ms à 44,1 kHz
  var sum = 0.0;
  for (var i = samples - tail; i < samples; i++) {
    final s = data.getInt16(44 + i * 2, Endian.little) / 32768;
    sum += s * s;
  }
  return sum / tail;
}

double peakOf(Uint8List bytes) {
  final data = ByteData.sublistView(bytes);
  final samples = (bytes.length - 44) ~/ 2;
  var peak = 0.0;
  for (var i = 0; i < samples; i++) {
    final s = (data.getInt16(44 + i * 2, Endian.little) / 32768).abs();
    if (s > peak) peak = s;
  }
  return peak;
}

void main() {
  final bytes = File('assets/sounds/cards/card_deal.wav').readAsBytesSync();

  test('card_deal.wav : un seul coup de carte par fichier (la boucle du code en fait la distribution)', () {
    expect(countOnsets(bytes), 1);
  });

  test('card_deal.wav : fin en fondu, pas de coupure brutale', () {
    expect(tailRms(bytes), lessThan(1e-6));
  });

  test('card_deal.wav : pas d écrêtage, niveau sous 0 dBFS', () {
    expect(peakOf(bytes), lessThanOrEqualTo(0.5));
  });
}
