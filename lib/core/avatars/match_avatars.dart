import 'dart:math';

import 'avatar_allocator.dart';

/// Avatars par siège d'une partie (issue #550).
///
/// Le siège [humanSeat] reçoit [humanId] s'il est connu ; tous les autres sièges
/// (IA) reçoivent un avatar distinct, via [AvatarAllocator] (issue #549).
List<String> avatarsBySeat({
  required int seats,
  int humanSeat = 0,
  String? humanId,
  Random? random,
}) {
  if (humanSeat < 0 || humanSeat >= seats) {
    throw RangeError.range(humanSeat, 0, seats - 1, 'humanSeat');
  }
  final ids = AvatarAllocator(random: random)
      .allocate(count: seats, humanId: humanId);
  final result = List<String>.filled(seats, '');
  result[humanSeat] = ids.first;
  var next = 1;
  for (var seat = 0; seat < seats; seat++) {
    if (seat == humanSeat) continue;
    result[seat] = ids[next++];
  }
  return result;
}
