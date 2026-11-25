import 'package:flutter_test/flutter_test.dart';
import 'package:kahwetne/core/avatars/avatar_catalog.dart';
import 'package:kahwetne/features/rami/rami_meld_owner_tag.dart';
import 'package:kahwetne/widgets/avatar_view.dart';
import 'package:material_ui/material_ui.dart';

/// Issue #942 : sur un paquet posé, un avatar miniature remplace le pseudo.
void main() {
  Future<void> pump(WidgetTester tester, Widget child) {
    return tester.pumpWidget(MaterialApp(home: Scaffold(body: child)));
  }

  testWidgets('le paquet affiche un avatar miniature, sans texte', (
    tester,
  ) async {
    await pump(
      tester,
      const RamiMeldOwnerTag(avatarId: 'lion', color: Colors.red),
    );
    final view = tester.widget<AvatarView>(find.byType(AvatarView));
    expect(view.avatarId, 'lion');
    expect(view.size, RamiMeldOwnerTag.size);
    expect(view.state, AvatarState.neutral);
    expect(find.text('Ali'), findsNothing);
  });

  testWidgets('la taille du médaillon reste très petite', (tester) async {
    expect(RamiMeldOwnerTag.size, lessThanOrEqualTo(16));
  });

  testWidgets("l'état de l'avatar est transmis au médaillon", (tester) async {
    await pump(
      tester,
      const RamiMeldOwnerTag(
        avatarId: 'tiger',
        color: Colors.blue,
        state: AvatarState.happy,
      ),
    );
    final view = tester.widget<AvatarView>(find.byType(AvatarView));
    expect(view.state, AvatarState.happy);
  });
}
