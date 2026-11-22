import 'package:flutter_test/flutter_test.dart';
import 'package:kahwetne/features/coinche/coinche_screen.dart';
import 'package:kahwetne/features/menu/menu_models.dart';
import 'package:kahwetne/widgets/turn_avatar.dart';
import 'package:material_ui/material_ui.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Issue #735 : avatars en médaillon 3D sur les trois sièges adverses et le partenaire,
/// un seul agrandi (le joueur dont c'est le tour).
void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets('Coinche : trois médaillons 3D, au plus un actif', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: CoincheScreen(difficulty: Difficulty.facile, targetScore: 1000),
      ),
    );
    await tester.pump();
    final badges = tester.widgetList<TurnAvatar>(find.byType(TurnAvatar));
    expect(badges.length, 3);
    expect(badges.where((b) => b.active).length, lessThanOrEqualTo(1));
  });
}
