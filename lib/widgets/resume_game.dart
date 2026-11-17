import 'package:material_ui/material_ui.dart';

import '../core/services/persistent_game_controller.dart';
import '../core/strings.dart';
import 'comic_button.dart';
import 'exit_guard.dart';

final Set<String> _resumeConfirmed = {};

/// Le menu a déjà demandé « Reprendre » pour ce jeu : l'écran de jeu reprend sans redemander (#219).
void markResumeConfirmed(String gameKey) => _resumeConfirmed.add(gameKey);

/// Si une partie sauvegardée attend : propose Reprendre (action principale) ou Nouvelle partie
/// (secondaire, avec confirmation). Ne se ferme pas sans choix (#112).
Future<void> offerResume(
  BuildContext context,
  PersistentGameController controller,
) async {
  if (!controller.awaitingResume) return;
  if (_resumeConfirmed.remove(controller.gameKey)) {
    controller.resume();
    return;
  }
  final resume = await showConfirmDialog(
    context,
    title: Strings.resumeTitle,
    body: Strings.resumeBody,
    cancelLabel: Strings.resumeNew,
    confirmLabel: Strings.resumeContinue,
    confirmVariant: ComicButtonVariant.primary,
  );
  if (!context.mounted) return;
  // Clic ailleurs (null) : la partie reste sauvegardée (#409).
  if (resume == null) return;
  if (resume == true) {
    controller.resume();
    return;
  }
  // « Nouvelle partie » efface la sauvegarde sans second écran (#410).
  await controller.discardSaved();
}
