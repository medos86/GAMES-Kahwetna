import 'package:flutter_test/flutter_test.dart';
import 'package:kahwetne/core/i18n/app_language.dart';
import 'package:kahwetne/features/domino/domino_screen.dart';
import 'package:kahwetne/features/menu/menu_models.dart';
import 'package:kahwetne/widgets/turn_avatar.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Domino : avatar, pseudo et score affichés comme au Chkobba (#1030).
/// Chaque joueur a un médaillon d'avatar (TurnAvatar), une pastille de pseudo
/// et une pastille de score, dans cet ordre.
void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets('Domino : avatar et pastilles de score pour les deux joueurs', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: DominoScreen(difficulty: Difficulty.facile, targetScore: 50),
      ),
    );
    await tester.pump();

    // Un médaillon d'avatar par joueur, comme au Chkobba.
    expect(find.byType(TurnAvatar), findsNWidgets(2));
    // Pseudo du joueur et de l'adversaire affichés en pastille.
    expect(find.text(t('you')), findsOneWidget);
    expect(find.text(t('opponentShort')), findsOneWidget);
    // Score de départ 0 pour chacun, dans une pastille.
    expect(find.text('0'), findsNWidgets(2));
  });
}
