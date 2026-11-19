import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:kahwetne/core/avatars/avatar_allocator.dart';

/// Issue #549 : aucun doublon dans une partie, profil humain prioritaire.
void main() {
  test('aucun doublon sur 1000 tirages de 4 joueurs', () {
    final allocator = AvatarAllocator(random: Random(42));
    for (var i = 0; i < 1000; i++) {
      final ids = allocator.allocate(count: 4);
      expect(ids.toSet(), hasLength(4), reason: ids.toString());
    }
  });

  test('le profil humain est servi en premier', () {
    final allocator = AvatarAllocator(random: Random(7));
    final ids = allocator.allocate(count: 4, humanId: 'lion');
    expect(ids.first, 'lion');
    expect(ids.toSet(), hasLength(4));
  });

  test('un profil humain inconnu est ignoré', () {
    final allocator = AvatarAllocator(random: Random(7));
    final ids = allocator.allocate(count: 2, humanId: 'inconnu');
    expect(ids, isNot(contains('inconnu')));
    expect(ids.toSet(), hasLength(2));
  });

  test('16 joueurs possibles, 17 refusés', () {
    final allocator = AvatarAllocator(random: Random(1));
    expect(allocator.allocate(count: 16).toSet(), hasLength(16));
    expect(() => allocator.allocate(count: 17), throwsRangeError);
  });
}
