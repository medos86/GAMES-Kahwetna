import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:kahwetne/core/avatars/avatar_catalog.dart';

/// Issue #541 : catalogue des 16 avatars, chemins et repli.
void main() {
  test('le catalogue contient 16 avatars aux identifiants uniques', () {
    expect(avatarCatalog, hasLength(16));
    final ids = avatarCatalog.map((a) => a.id).toSet();
    expect(ids, hasLength(16));
  });

  test('chaque état produit un chemin vers un fichier existant', () {
    for (final avatar in avatarCatalog) {
      for (final state in AvatarState.values) {
        final path = avatar.assetFor(state);
        expect(File(path).existsSync(), isTrue, reason: path);
      }
    }
  });

  test('le chemin suit le format assets/images/avatars/<état>/<id>.webp', () {
    expect(
      const Avatar('lion').assetFor(AvatarState.happy),
      'assets/images/avatars/happy/lion.webp',
    );
  });

  test('un identifiant connu retourne son avatar', () {
    expect(avatarById('tiger').id, 'tiger');
  });

  test('un identifiant inconnu ou absent retourne le repli', () {
    expect(avatarById('inconnu'), defaultAvatar);
    expect(avatarById(null), defaultAvatar);
  });
}
