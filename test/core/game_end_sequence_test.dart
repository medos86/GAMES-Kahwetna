import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:kahwetne/core/services/game_end_sequence.dart';

/// Laisse passer les microtâches en attente de la pub simulée.
Future<void> flush() => Future<void>.delayed(Duration.zero);

void main() {
  test('fin non révélée pendant la pub, révélée après', () async {
    final seq = GameEndSequence();
    final ad = Completer<Object?>();
    seq.start(() => ad.future);

    expect(seq.revealed.value, isFalse);
    ad.complete(true);
    await flush();
    expect(seq.revealed.value, isTrue);
  });

  test('sans pub (showAd immédiat), révélée tout de suite', () async {
    final seq = GameEndSequence();
    seq.start(() async => false);
    await flush();
    expect(seq.revealed.value, isTrue);
  });

  test('une erreur de pub ne bloque pas la révélation', () async {
    final seq = GameEndSequence();
    seq.start(() async => throw StateError('pub en échec'));
    await flush();
    expect(seq.revealed.value, isTrue);
  });

  test('une nouvelle fin repart de non révélée', () async {
    final seq = GameEndSequence();
    seq.start(() async => null);
    await flush();
    expect(seq.revealed.value, isTrue);

    final ad = Completer<Object?>();
    seq.start(() => ad.future);
    expect(seq.revealed.value, isFalse);
    ad.complete(null);
    await flush();
    expect(seq.revealed.value, isTrue);
  });

  test('reset remet la séquence à non révélée', () async {
    final seq = GameEndSequence();
    seq.start(() async => null);
    await flush();
    seq.reset();
    expect(seq.revealed.value, isFalse);
  });

  test('notifie les écouteurs au passage à révélée', () async {
    final seq = GameEndSequence();
    final seen = <bool>[];
    seq.revealed.addListener(() => seen.add(seq.revealed.value));
    seq.start(() async => null);
    await flush();
    expect(seen, [true]);
  });
}
