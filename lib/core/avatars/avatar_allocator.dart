import 'dart:math';

import 'avatar_catalog.dart';

/// Attribue des avatars distincts aux joueurs d'une partie (issue #549).
///
/// Deux joueurs (humains ou IA) ne portent jamais le même avatar. Le profil humain,
/// s'il est connu, est servi en premier ; les autres reçoivent un avatar tiré au sort
/// parmi les libres.
class AvatarAllocator {
  AvatarAllocator({Random? random}) : _random = random ?? Random();

  final Random _random;

  /// Retourne [count] identifiants distincts. [humanId] est pris en premier s'il existe.
  /// Lève [RangeError] si [count] dépasse le nombre d'avatars disponibles.
  List<String> allocate({required int count, String? humanId}) {
    if (count < 1 || count > avatarCatalog.length) {
      throw RangeError.range(count, 1, avatarCatalog.length, 'count');
    }
    final pool = avatarCatalog.map((a) => a.id).toList()..shuffle(_random);
    final result = <String>[];
    if (humanId != null && pool.contains(humanId)) {
      result.add(humanId);
      pool.remove(humanId);
    }
    while (result.length < count) {
      result.add(pool.removeLast());
    }
    return result;
  }
}
