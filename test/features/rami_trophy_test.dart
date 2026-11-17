import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kahwetne/features/menu/menu_models.dart';
import 'package:kahwetne/features/rami/rami_screen.dart';
import 'package:kahwetne/widgets/trophy_badge.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Issue #371 : le score cible de Rami utilise la coupe commune (TrophyBadge),
/// centrée sur le bol comme dans les autres jeux.
void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets('Rami : la coupe affiche le score cible', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: RamiScreen(difficulty: Difficulty.facile, targetScore: 100),
      ),
    );
    await tester.pump();

    expect(find.byType(TrophyBadge), findsOneWidget);
    expect(tester.widget<TrophyBadge>(find.byType(TrophyBadge)).target, 100);
    expect(tester.takeException(), isNull);
  });
}
