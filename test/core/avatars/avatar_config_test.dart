import 'package:flutter_test/flutter_test.dart';
import 'package:kahwetne/core/avatars/avatar_config.dart';

/// Issue #935 : plafond de taille d'affichage des avatars, réglable dans AvatarConfig.
void main() {
  test('taille sous le plafond : inchangée', () {
    expect(effectiveAvatarSize(40), 40);
  });

  test('taille égale au plafond : inchangée', () {
    const max = AvatarConfig.maxDisplaySize;
    expect(effectiveAvatarSize(max), max);
  });

  test('taille au-dessus du plafond : plafonnée', () {
    expect(effectiveAvatarSize(200), AvatarConfig.maxDisplaySize);
  });
}
