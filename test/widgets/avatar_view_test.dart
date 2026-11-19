import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kahwetne/core/avatars/avatar_catalog.dart';
import 'package:kahwetne/widgets/avatar_view.dart';

/// Issue #545 : rendu des trois états, taille et label sémantique.
void main() {
  Future<void> pump(WidgetTester tester, AvatarView view) {
    return tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: view,
      ),
    );
  }

  String assetOf(WidgetTester tester) {
    final image = tester.widget<Image>(find.byType(Image));
    return (image.image as AssetImage).assetName;
  }

  testWidgets('chaque état affiche la bonne image', (tester) async {
    for (final state in AvatarState.values) {
      await pump(tester, AvatarView(avatarId: 'lion', state: state));
      expect(
        assetOf(tester),
        const Avatar('lion').assetFor(state),
      );
    }
  });

  testWidgets('id inconnu : repli par défaut', (tester) async {
    await pump(tester, const AvatarView(avatarId: 'inconnu'));
    expect(
      assetOf(tester),
      defaultAvatar.assetFor(AvatarState.neutral),
    );
  });

  testWidgets('la taille demandée est appliquée', (tester) async {
    await pump(tester, const AvatarView(avatarId: 'cat', size: 32));
    final box = tester.getSize(find.byType(ClipOval));
    expect(box, const Size(32, 32));
  });

  testWidgets('le label sémantique est exposé', (tester) async {
    await pump(
      tester,
      const AvatarView(avatarId: 'cat', semanticLabel: 'Sfaxi_Lion'),
    );
    expect(find.bySemanticsLabel('Sfaxi_Lion'), findsOneWidget);
  });
}
