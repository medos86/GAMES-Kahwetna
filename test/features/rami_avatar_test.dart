import 'package:flutter_test/flutter_test.dart';
import 'package:kahwetne/core/avatars/avatar_catalog.dart';
import 'package:kahwetne/features/rami/rami_seat_badge.dart';
import 'package:kahwetne/widgets/avatar_view.dart';
import 'package:material_ui/material_ui.dart';

/// Issue #552 : avatar sur le badge du siège, état selon le résultat.
void main() {
  Future<void> pump(WidgetTester tester, RamiSeatBadge badge) {
    return tester.pumpWidget(MaterialApp(home: Scaffold(body: badge)));
  }

  testWidgets('sans avatar, le badge reste textuel', (tester) async {
    await pump(tester, const RamiSeatBadge(name: 'Ali', cards: 6));
    expect(find.byType(AvatarView), findsNothing);
    expect(find.text('Ali ×6'), findsOneWidget);
  });

  testWidgets('avatar neutre pendant la manche', (tester) async {
    await pump(
      tester,
      const RamiSeatBadge(name: 'Ali', cards: 6, avatarId: 'lion'),
    );
    final view = tester.widget<AvatarView>(find.byType(AvatarView));
    expect(view.avatarId, 'lion');
    expect(view.state, AvatarState.neutral);
    expect(find.text('Ali ×6'), findsOneWidget);
  });

  testWidgets('avatar fâché pour un perdant de manche', (tester) async {
    await pump(
      tester,
      const RamiSeatBadge(
        name: 'Ali',
        cards: 3,
        avatarId: 'tiger',
        avatarState: AvatarState.angry,
      ),
    );
    final view = tester.widget<AvatarView>(find.byType(AvatarView));
    expect(view.state, AvatarState.angry);
  });
}
