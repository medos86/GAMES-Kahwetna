import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:kahwetne/core/services/saved_game_store.dart';
import 'package:kahwetne/core/strings.dart';
import 'package:kahwetne/features/ludo/ludo_controller.dart';
import 'package:kahwetne/game/ludo.dart';
import 'package:kahwetne/widgets/resume_game.dart';

class _Store implements SavedGameStore {
  Map<String, dynamic>? saved;

  @override
  Future<Map<String, dynamic>?> load(String game) async => saved;

  @override
  Future<void> save(String game, Map<String, dynamic> json) async {
    saved = json;
  }

  @override
  Future<void> clear(String game) async {
    saved = null;
  }
}

/// Issue #410 : « Nouvelle partie » efface la sauvegarde sans second écran de vérification.
void main() {
  testWidgets('Nouvelle partie : pas de second dialogue, sauvegarde effacée', (
    tester,
  ) async {
    final store = _Store();
    final seed = LudoController(
      playerCount: 2,
      difficulty: LudoAiLevel.facile,
      store: store,
    );
    await seed.restore();
    store.saved = seed.snapshot();
    seed.dispose();

    final controller = LudoController(
      playerCount: 2,
      difficulty: LudoAiLevel.facile,
      store: store,
    );
    await controller.restore();

    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: const [
          DefaultMaterialLocalizations.delegate,
          DefaultWidgetsLocalizations.delegate,
        ],
        home: Builder(
          builder: (context) => Scaffold(
            body: ElevatedButton(
              onPressed: () => offerResume(context, controller),
              child: const Text('ouvrir'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('ouvrir'));
    await tester.pumpAndSettle();

    await tester.tap(find.text(Strings.resumeNew));
    await tester.pumpAndSettle();

    expect(find.text(Strings.resumeNewTitle), findsNothing);
    expect(store.saved, isNull);
    controller.dispose();
  });
}
