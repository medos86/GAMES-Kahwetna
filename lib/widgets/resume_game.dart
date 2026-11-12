import 'package:flutter/material.dart';

import '../core/services/persistent_game_controller.dart';
import '../core/strings.dart';
import 'comic_button.dart';
import 'exit_guard.dart';

/// Si une partie sauvegardée attend : propose Reprendre (action principale) ou Nouvelle partie
/// (secondaire, avec confirmation). Ne se ferme pas sans choix (#112).
Future<void> offerResume(
  BuildContext context,
  PersistentGameController controller,
) async {
  if (!controller.awaitingResume) return;
  while (true) {
    final resume = await showConfirmDialog(
      context,
      title: Strings.resumeTitle,
      body: Strings.resumeBody,
      cancelLabel: Strings.resumeNew,
      confirmLabel: Strings.resumeContinue,
      confirmVariant: ComicButtonVariant.primary,
      dismissible: false,
    );
    if (!context.mounted) return;
    if (resume == true) {
      controller.resume();
      return;
    }
    final sure = await showConfirmDialog(
      context,
      title: Strings.resumeNewTitle,
      body: Strings.resumeNewBody,
      cancelLabel: Strings.exitStay,
      confirmLabel: Strings.resumeNew,
      dismissible: false,
    );
    if (!context.mounted) return;
    if (sure == true) {
      await controller.discardSaved();
      return;
    }
  }
}
