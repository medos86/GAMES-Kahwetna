// Un seul grand tapis, avatar du joueur, bouclier rouge (issue #838).
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kahwetne/core/avatars/avatar_catalog.dart';
import 'package:kahwetne/features/rami/rami_min_opening_shield.dart';
import 'package:kahwetne/features/rami/rami_seat_badge.dart';
import 'package:kahwetne/widgets/turn_avatar.dart';
import 'package:material_ui/material_ui.dart';

void main() {
  testWidgets('le badge du joueur actif agrandit son médaillon',
      (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: RamiSeatBadge(
            name: 'Ali',
            cards: 6,
            avatarId: 'lion',
            active: true,
          ),
        ),
      ),
    );
    final avatar = tester.widget<TurnAvatar>(find.byType(TurnAvatar));
    expect(avatar.active, isTrue);
    expect(avatar.avatarId, 'lion');
    expect(avatar.state, AvatarState.neutral);
  });

  testWidgets('bouclier du seuil en rouge', (tester) async {
    await tester.pumpWidget(
      const Directionality(
        textDirection: TextDirection.ltr,
        child: RamiMinOpeningShield(minimum: 51, label: 'Ouverture : 51'),
      ),
    );
    final box = tester.widget<Container>(
      find.descendant(
        of: find.byKey(const Key('ramiMinOpeningShield')),
        matching: find.byType(Container),
      ),
    );
    final decoration = box.decoration! as BoxDecoration;
    final gradient = decoration.gradient! as LinearGradient;
    expect(gradient.colors.first, const Color(0xFFE5484D));
  });
}
