import 'package:flutter_test/flutter_test.dart';
import 'package:kahwetne/features/chkobba/chkobba_screen.dart';
import 'package:kahwetne/features/menu/menu_models.dart';
import 'package:kahwetne/widgets/avatar_view.dart';
import 'package:material_ui/material_ui.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Issue #551 : le scoreboard Chkobba affiche un avatar pour chaque joueur,
/// et les deux avatars sont distincts.
void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({
      'kahwetne.profile.avatarId': 'lion',
    });
  });

  testWidgets('deux avatars distincts dans le scoreboard', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: ChkobbaScreen(difficulty: Difficulty.facile, targetScore: 11),
      ),
    );
    await tester.pumpAndSettle();
    final ids = tester
        .widgetList<AvatarView>(find.byType(AvatarView))
        .map((a) => a.avatarId)
        .toList();
    expect(ids.length, greaterThanOrEqualTo(2));
    expect(ids.take(2).toSet(), hasLength(2));
    expect(ids.first, 'lion');
  });
}
