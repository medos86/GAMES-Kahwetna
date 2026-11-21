import 'package:flutter_test/flutter_test.dart';
import 'package:kahwetne/features/ludo/ludo_controller.dart';
import 'package:kahwetne/features/ludo/ludo_screen.dart';
import 'package:kahwetne/features/menu/menu_models.dart';
import 'package:kahwetne/game/ludo.dart';
import 'package:kahwetne/widgets/avatar_view.dart';
import 'package:material_ui/material_ui.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Issue #553 : un avatar par couleur dans l'en-tête, le joueur humain garde son profil.
void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('joueur humain : premier avatar, IA : les suivants', () {
    final map = ludoAvatarByColor(['tiger', 'lion', 'panda', 'cat']);
    expect(map[ludoHumanOrder.first], 'tiger');
    expect(map.length, LudoColor.values.length);
    expect(map.values.toSet().length, LudoColor.values.length);
  });

  testWidgets('cartes joueurs : un avatar par couleur (#621)', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: LudoScreen(difficulty: Difficulty.facile, players: 2),
      ),
    );
    await tester.pump();
    expect(find.byType(AvatarView), findsNWidgets(LudoColor.values.length));
  });

  testWidgets('#663 : avatar du joueur actif en pleine opacité, les autres atténués', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: LudoScreen(difficulty: Difficulty.facile, players: 2),
      ),
    );
    await tester.pump();
    final views = tester.widgetList<AvatarView>(find.byType(AvatarView));
    expect(views.where((v) => v.isActive).length, 1);
    final opacities = tester
        .widgetList<AnimatedOpacity>(
          find.descendant(
            of: find.byType(AvatarView),
            matching: find.byType(AnimatedOpacity),
          ),
        )
        .map((o) => o.opacity)
        .toList();
    expect(opacities.where((o) => o == 1).length, 1);
    expect(opacities.where((o) => o == 0.55).length, LudoColor.values.length - 1);
  });
}
