import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kahwetne/widgets/exit_guard.dart';

/// Retour système sur un écran de jeu (#117).
void main() {
  Future<void> openGame(WidgetTester tester, {required bool active}) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (ctx) => Scaffold(
            body: TextButton(
              onPressed: () => Navigator.of(ctx).push(
                MaterialPageRoute(
                  builder: (_) => ExitGuard(
                    active: active,
                    child: const Scaffold(body: Text('jeu')),
                  ),
                ),
              ),
              child: const Text('ouvrir'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('ouvrir'));
    await tester.pumpAndSettle();
  }

  testWidgets(
    'retour pendant une partie demande confirmation, et « Rester » reste sur le jeu',
    (tester) async {
      await openGame(tester, active: true);
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(find.text('Quitter la partie ?'), findsOneWidget);
      await tester.tap(find.text('Rester'));
      await tester.pumpAndSettle();
      expect(find.text('jeu'), findsOneWidget);
    },
  );

  testWidgets('« Quitter » ramène au menu', (tester) async {
    await openGame(tester, active: true);
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    await tester.tap(find.text('Quitter'));
    await tester.pumpAndSettle();
    expect(find.text('jeu'), findsNothing);
    expect(find.text('ouvrir'), findsOneWidget);
  });

  testWidgets('partie terminée : retour sans confirmation', (tester) async {
    await openGame(tester, active: false);
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.text('Quitter la partie ?'), findsNothing);
    expect(find.text('ouvrir'), findsOneWidget);
  });
}
