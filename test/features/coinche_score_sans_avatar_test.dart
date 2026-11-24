import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:kahwetne/features/coinche/coinche_screen.dart';
import 'package:kahwetne/features/menu/menu_models.dart';
import 'package:kahwetne/widgets/avatar_view.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Issue #736 : la barre de score n'affiche plus d'avatar. Il ne reste que
/// les quatre avatars des sièges.
void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets('Coinche : pas d’avatar dans la barre de score', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: CoincheScreen(
          difficulty: Difficulty.facile,
          targetScore: 1000,
        ),
      ),
    );
    await tester.pump();
    // Quatre sièges à avatar (nord, ouest, est) et le joueur (sud, #838).
    expect(find.byType(AvatarView), findsNWidgets(4));
  });
}
