import 'package:material_ui/material_ui.dart';

import '../../core/services/age_gate_service.dart';
import '../../core/strings.dart';
import '../../core/theme/game_style.dart';
import '../../widgets/comic_button.dart';

/// Question d'âge au premier lancement (issue #567, décision #565 : 13+).
///
/// Oui et Non ont le même poids visuel (même variante, même taille).
/// Aucun bouton n'est préselectionné. Le texte « Pourquoi ? » ouvre une explication.
class AgeGateScreen extends StatelessWidget {
  const AgeGateScreen({super.key, required this.onAnswer});

  /// Appelé avec la réponse du joueur.
  final void Function(AgeAnswer answer) onAnswer;

  @override
  Widget build(BuildContext context) {
    final style = GameStyle.current;
    return Scaffold(
      backgroundColor: style.felt,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Container(
              constraints: const BoxConstraints(maxWidth: 420),
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: style.zelligeAccent,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: style.outline, width: 3),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    Strings.ageGateTitle,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: style.frame,
                      fontSize: 26,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    Strings.ageGateQuestion,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: style.frame,
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: ComicButton(
                          label: Strings.ageGateYes,
                          variant: ComicButtonVariant.neutral,
                          onPressed: () => onAnswer(AgeAnswer.thirteenOrOver),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: ComicButton(
                          label: Strings.ageGateNo,
                          variant: ComicButtonVariant.neutral,
                          onPressed: () => onAnswer(AgeAnswer.underThirteen),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  TextButton(
                    onPressed: () => _showWhy(context),
                    child: Text(
                      Strings.ageGateWhy,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: style.frame,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _showWhy(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        content: Text(Strings.ageGateWhyBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: Text(Strings.ageGateClose),
          ),
        ],
      ),
    );
  }
}

/// Affiche la question tant qu'elle n'a pas été répondue, puis [next].
///
/// Une réponse est enregistrée via [AgeGateService] ; le widget se reconstruit
/// alors et laisse passer vers [next] sans navigation supplémentaire.
class AgeGateGate extends StatefulWidget {
  const AgeGateGate({super.key, required this.next});

  final Widget next;

  @override
  State<AgeGateGate> createState() => _AgeGateGateState();
}

class _AgeGateGateState extends State<AgeGateGate> {
  Future<void> _answer(AgeAnswer answer) async {
    await AgeGateService.instance.setAnswer(answer);
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    if (!AgeGateService.instance.shouldAsk) return widget.next;
    return AgeGateScreen(onAnswer: _answer);
  }
}
