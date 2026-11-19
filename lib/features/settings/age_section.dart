import 'package:material_ui/material_ui.dart';

import '../../core/services/age_gate_service.dart';
import '../../core/strings.dart';
import '../../core/theme/game_style.dart';
import '../../widgets/comic_button.dart';

/// Section « Âge » des Paramètres (issue #568) : affiche la réponse et permet
/// de la changer. Le changement est enregistré tout de suite, sans alerte.
class AgeSection extends StatelessWidget {
  const AgeSection({super.key});

  static String labelFor(AgeAnswer answer) {
    if (answer == AgeAnswer.thirteenOrOver) return Strings.ageCurrentOver;
    if (answer == AgeAnswer.underThirteen) return Strings.ageCurrentUnder;
    return Strings.ageNotAnswered;
  }

  @override
  Widget build(BuildContext context) {
    final style = GameStyle.current;
    return ValueListenableBuilder<AgeAnswer>(
      valueListenable: AgeGateService.instance.answers,
      builder: (context, answer, _) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            Strings.ageSection.toUpperCase(),
            style: TextStyle(
              fontWeight: FontWeight.w900,
              letterSpacing: 1,
              color: style.frame,
            ),
          ),
          const SizedBox(height: 8),
          ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 48),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    labelFor(answer),
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      color: style.frame,
                    ),
                  ),
                ),
                ComicButton(
                  label: Strings.ageChange,
                  variant: ComicButtonVariant.neutral,
                  onPressed: () => _showChange(context),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showChange(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(Strings.ageChangeTitle),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ComicButton(
              label: Strings.ageCurrentOver,
              variant: ComicButtonVariant.neutral,
              onPressed: () => _select(ctx, AgeAnswer.thirteenOrOver),
            ),
            const SizedBox(height: 12),
            ComicButton(
              label: Strings.ageCurrentUnder,
              variant: ComicButtonVariant.neutral,
              onPressed: () => _select(ctx, AgeAnswer.underThirteen),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(Strings.ageCancel),
          ),
        ],
      ),
    );
  }

  Future<void> _select(BuildContext ctx, AgeAnswer answer) async {
    await AgeGateService.instance.setAnswer(answer);
    if (ctx.mounted) Navigator.of(ctx).pop();
  }
}
