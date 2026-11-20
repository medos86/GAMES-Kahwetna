import 'package:flutter_test/flutter_test.dart';
import 'package:kahwetne/features/settings/profile_screen.dart';
import 'package:kahwetne/features/settings/settings_screen.dart';
import 'package:kahwetne/widgets/comic/comic_backdrop.dart';
import 'package:material_ui/material_ui.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Issue #638 : le chip avatar ouvre seulement Profil ; Configuration ouvre les réglages.
/// Issue #636 : les réglages sont regroupés par thème dans des cases.
void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({
      'kahwetne.profile.name': 'Sfaxi_Lion',
      'kahwetne.profile.avatarId': 'lion',
    });
  });

  testWidgets('l\'écran Profil n\'affiche que la section Profil', (
    tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: ProfileScreen()));
    await tester.pumpAndSettle();
    expect(find.text('Profil'), findsOneWidget);
    expect(find.text('Sfaxi_Lion'), findsOneWidget);
    expect(find.text('AFFICHAGE'), findsNothing);
    expect(find.byType(ComicBackdrop), findsOneWidget);
  });

  testWidgets('les réglages sont regroupés : Affichage est une case', (
    tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: SettingsScreen()));
    await tester.pumpAndSettle();
    expect(find.text('AFFICHAGE'), findsOneWidget);
    expect(find.text('Sfaxi_Lion'), findsOneWidget);
  });

  testWidgets('retour depuis Profil ramène à l\'écran précédent', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () => Navigator.of(context).push<void>(
                MaterialPageRoute<void>(builder: (_) => const ProfileScreen()),
              ),
              child: const Text('menu'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('menu'));
    await tester.pumpAndSettle();
    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(find.text('menu'), findsOneWidget);
  });
}
