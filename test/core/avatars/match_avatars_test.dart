import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:kahwetne/core/avatars/match_avatars.dart';

/// Issue #550 : chaque IA a un avatar distinct de celui du joueur.
void main() {
  test('tous les sièges ont un avatar distinct', () {
    for (var seed = 0; seed < 200; seed++) {
      final ids = avatarsBySeat(seats: 4, random: Random(seed));
      expect(ids.toSet(), hasLength(4), reason: 'seed $seed');
    }
  });

  test('le siège humain reçoit son profil, les IA un autre avatar', () {
    final ids = avatarsBySeat(
      seats: 4,
      humanSeat: 2,
      humanId: 'lion',
      random: Random(3),
    );
    expect(ids[2], 'lion');
    expect(ids.where((id) => id == 'lion'), hasLength(1));
  });

  test('siège humain hors plage refusé', () {
    expect(
      () => avatarsBySeat(seats: 2, humanSeat: 2),
      throwsRangeError,
    );
  });
}
