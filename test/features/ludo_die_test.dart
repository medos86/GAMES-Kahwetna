import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kahwetne/features/ludo/ludo_screen.dart';

/// Vrai si la transformation est l'identité (dé à plat, taille normale).
bool _isStill(Transform t) {
  final m = t.transform.storage;
  const identity = [1.0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1];
  for (var i = 0; i < 16; i++) {
    if ((m[i] - identity[i]).abs() > 1e-9) return false;
  }
  return true;
}

void main() {
  testWidgets('#120 : un seul dé anime quand deux joueurs sont affichés', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: Row(
            children: [
              KeyedSubtree(
                key: ValueKey('actif'),
                child: LudoDie(value: 4, tone: Colors.red, animate: true),
              ),
              KeyedSubtree(
                key: ValueKey('inactif'),
                child: LudoDie(value: null, tone: Colors.blue, animate: false),
              ),
            ],
          ),
        ),
      ),
    );
    // Premier frame : le dé animé est encore tourné, le dé inactif est déjà à plat.
    final actif = tester.widget<Transform>(
      find
          .descendant(
            of: find.byKey(const ValueKey('actif')),
            matching: find.byType(Transform),
          )
          .first,
    );
    final inactif = tester.widget<Transform>(
      find
          .descendant(
            of: find.byKey(const ValueKey('inactif')),
            matching: find.byType(Transform),
          )
          .first,
    );
    expect(_isStill(actif), isFalse);
    expect(_isStill(inactif), isTrue);

    await tester.pumpAndSettle();
    expect(_isStill(inactif), isTrue);
  });

  testWidgets('#883 : un dé bloqué secoue la tête sans afficher « Non »', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: LudoDie(
            value: 3,
            tone: Colors.red,
            animate: false,
            refused: true,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    // Le dé reste affiché (face 3), même dans le secouement.
    expect(find.byType(LudoDie), findsWidgets);
    expect(find.text('Non'), findsNothing);
    expect(find.text('لا'), findsNothing);
  });

  test('#598 : la cible tactile du dé respecte le minimum de 48 dp', () {
    expect(kLudoDieTapSize, greaterThanOrEqualTo(48));
  });
}
