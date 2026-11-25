import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kahwetne/core/avatars/avatar_catalog.dart';
import 'package:kahwetne/core/avatars/avatar_config.dart';
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

  testWidgets('le label sémantique est exposé', (tester) async {
    await pump(
      tester,
      const AvatarView(avatarId: 'cat', semanticLabel: 'Sfaxi_Lion'),
    );
    expect(find.bySemanticsLabel('Sfaxi_Lion'), findsOneWidget);
  });

  testWidgets('actif : pleine opacité ; inactif : 0,55', (tester) async {
    await pump(tester, const AvatarView(avatarId: 'cat'));
    expect(
      tester.widget<AnimatedOpacity>(find.byType(AnimatedOpacity)).opacity,
      1,
    );
    await pump(tester, const AvatarView(avatarId: 'cat', isActive: false));
    expect(
      tester.widget<AnimatedOpacity>(find.byType(AnimatedOpacity)).opacity,
      0.55,
    );
  });

  testWidgets('taille plafonnée, qualité configurée (#935)', (
    tester,
  ) async {
    await pump(tester, const AvatarView(avatarId: 'cat', size: 300));
    final box = tester.widget<SizedBox>(
      find
          .ancestor(of: find.byType(Image), matching: find.byType(SizedBox))
          .first,
    );
    expect(box.width, AvatarConfig.maxDisplaySize);
    expect(box.height, AvatarConfig.maxDisplaySize);
    expect(
      tester.widget<Image>(find.byType(Image)).filterQuality,
      AvatarConfig.filterQuality,
    );
  });
}
