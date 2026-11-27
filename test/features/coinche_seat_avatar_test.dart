import 'package:flutter_test/flutter_test.dart';
import 'package:kahwetne/features/coinche/coinche_screen.dart';
import 'package:kahwetne/features/menu/menu_models.dart';
import 'package:kahwetne/widgets/turn_avatar.dart';
import 'package:material_ui/material_ui.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Issue #1032 : chaque siège a son médaillon d'avatar (joueur en bas, trois adversaires),
/// et les coins d'équipe n'en répètent plus.
void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets(
    'Belote : exactement quatre avatars, un par siège',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: CoincheScreen(
            difficulty: Difficulty.facile,
            targetScore: 1000,
          ),
        ),
      );
      await tester.pump();
      // Sud (coin bas-droite) + nord, ouest, est : un médaillon par siège.
      expect(find.byType(TurnAvatar), findsNWidgets(4));
    },
  );
}
