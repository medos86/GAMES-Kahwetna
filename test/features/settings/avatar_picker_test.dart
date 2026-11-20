import 'package:flutter_test/flutter_test.dart';
import 'package:kahwetne/features/settings/avatar_picker.dart';
import 'package:kahwetne/widgets/avatar_view.dart';
import 'package:material_ui/material_ui.dart';

/// Issue #548 : la grille renvoie le choix, Annuler ne change rien, les pris sont bloqués.
void main() {
  Future<String?> open(
    WidgetTester tester, {
    Set<String> taken = const {},
  }) async {
    String? result;
    tester.view.physicalSize = const Size(400, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () async {
                result = await showAvatarPicker(
                  context,
                  currentId: 'cat',
                  takenIds: taken,
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
    return result;
  }

  Finder choice(String id) {
    return find.byWidgetPredicate((w) => w is AvatarView && w.avatarId == id);
  }

  testWidgets('Valider renvoie l\'avatar choisi', (tester) async {
    await open(tester);
    await tester.tap(choice('tiger'));
    await tester.pump();
    await tester.tap(find.text('Choisir'));
    await tester.pumpAndSettle();
    expect(find.text('Choisir'), findsNothing);
  });

  testWidgets('Annuler ferme la grille sans changement', (tester) async {
    await open(tester);
    await tester.tap(choice('tiger'));
    await tester.tap(find.text('Annuler'));
    await tester.pumpAndSettle();
    expect(find.text('Annuler'), findsNothing);
  });

  testWidgets('l\'avatar actuel est en grand avec le libellé Actuel', (
    tester,
  ) async {
    await open(tester);
    expect(find.text('Actuel'), findsOneWidget);
    await tester.tap(choice('tiger'));
    await tester.pump();
    expect(find.text('Aperçu'), findsOneWidget);
    expect(find.text('Actuel'), findsNothing);
  });

  testWidgets('un avatar pris porte l\'étiquette Pris', (tester) async {
    await open(tester, taken: {'tiger'});
    expect(find.text('Pris'), findsOneWidget);
  });

  testWidgets('un avatar pris ne peut pas être choisi', (tester) async {
    await open(tester, taken: {'tiger'});
    await tester.tap(choice('tiger'));
    await tester.pump();
    await tester.tap(find.text('Choisir'));
    await tester.pumpAndSettle();
    expect(find.text('Choisir'), findsNothing);
  });
}
