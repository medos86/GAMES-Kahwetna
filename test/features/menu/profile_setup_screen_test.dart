import 'package:flutter_test/flutter_test.dart';
import 'package:kahwetne/core/services/profile_store.dart';
import 'package:kahwetne/features/menu/profile_setup_screen.dart';
import 'package:material_ui/material_ui.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Issue #631 : au premier lancement, le pseudo est saisi et validé avant le menu.
void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  /// Ouvre l'écran par une route, comme le menu, et garde le profil renvoyé.
  Future<PlayerProfile? Function()> open(WidgetTester tester) async {
    PlayerProfile? result;
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () async {
                result = await Navigator.of(context).push<PlayerProfile>(
                  MaterialPageRoute<PlayerProfile>(
                    builder: (_) => const ProfileSetupScreen(
                      initial: PlayerProfile(name: '', avatarId: 'cat'),
                    ),
                  ),
                );
              },
              child: const Text('ouvrir'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('ouvrir'));
    await tester.pumpAndSettle();
    return () => result;
  }

  testWidgets('pseudo trop court : erreur, l\'écran reste ouvert', (
    tester,
  ) async {
    final result = await open(tester);
    await tester.enterText(find.byType(TextField), 'ab');
    await tester.tap(find.text('Commencer'));
    await tester.pumpAndSettle();
    expect(find.textContaining('trop court'), findsOneWidget);
    expect(find.text('Commencer'), findsOneWidget);
    expect(result(), isNull);
  });

  testWidgets('pseudo valide : renvoie le profil saisi', (tester) async {
    final result = await open(tester);
    await tester.enterText(find.byType(TextField), '  Tigre_Brave ');
    await tester.tap(find.text('Commencer'));
    await tester.pumpAndSettle();
    expect(find.text('Commencer'), findsNothing);
    expect(result()?.name, 'Tigre_Brave');
    expect(result()?.avatarId, 'cat');
  });

  testWidgets('retour arrière bloqué tant que le pseudo n\'est pas saisi', (
    tester,
  ) async {
    await open(tester);
    final scope = tester.widget<PopScope>(
      find.descendant(
        of: find.byType(ProfileSetupScreen),
        matching: find.byType(PopScope),
      ),
    );
    expect(scope.canPop, isFalse);
  });
}
