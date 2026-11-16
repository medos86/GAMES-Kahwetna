import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:kahwetne/widgets/exit_guard.dart';

/// Issue #409 : cliquer à côté du dialogue « Partie en cours » le ferme sans choix (résultat null).
void main() {
  testWidgets('clic hors du dialogue de reprise : pas de choix (null)', (
    tester,
  ) async {
    Object? answer = 'pas encore';
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: const [
          DefaultMaterialLocalizations.delegate,
          DefaultWidgetsLocalizations.delegate,
        ],
        home: Builder(
          builder: (context) => Scaffold(
            body: ElevatedButton(
              onPressed: () async {
                answer = await showConfirmDialog(
                  context,
                  title: 'Partie en cours',
                  body: 'Reprendre ?',
                  cancelLabel: 'Nouvelle partie',
                  confirmLabel: 'Reprendre',
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
    expect(find.text('Partie en cours'), findsOneWidget);

    await tester.tapAt(const Offset(5, 5));
    await tester.pumpAndSettle();
    expect(find.text('Partie en cours'), findsNothing);
    expect(answer, isNull);
  });
}
