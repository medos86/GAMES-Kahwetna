import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:kahwetne/core/services/game_end_sequence.dart';

void main() {
  test('fin non révélée tant que la pub tourne, révélée après', () async {
    final seq = GameEndSequence();
    final ad = Completer<Object?>();
    final future = seq.start(() => ad.future);

    expect(seq.revealed.value, isFalse);
    ad.complete(true);
    await future;
    expect(seq.revealed.value, isTrue);
  });

  test('sans pub (showAd immédiat), révélée tout de suite', () async {
    final seq = GameEndSequence();
    await seq.start(() async => false);
    expect(seq.revealed.value, isTrue);
  });

  test('une erreur de pub ne bloque pas la révélation', () async {
    final seq = GameEndSequence();
    await seq.start(() async => throw StateError('pub en échec'));
    expect(seq.revealed.value, isTrue);
  });

  test('une nouvelle fin repart de non révélée', () async {
    final seq = GameEndSequence();
    await seq.start(() async => null);
    expect(seq.revealed.value, isTrue);

    final ad = Completer<Object?>();
    final future = seq.start(() => ad.future);
    expect(seq.revealed.value, isFalse);
    ad.complete(null);
    await future;
    expect(seq.revealed.value, isTrue);
  });

  test('reset remet la séquence à non révélée', () async {
    final seq = GameEndSequence();
    await seq.start(() async => null);
    seq.reset();
    expect(seq.revealed.value, isFalse);
  });

  test('notifie les écouteurs au passage à révélée', () async {
    final seq = GameEndSequence();
    final seen = <bool>[];
    seq.revealed.addListener(() => seen.add(seq.revealed.value));
    await seq.start(() async => null);
    expect(seen, [false, true]);
  });
}
