import 'package:material_ui/material_ui.dart';

import '../../core/strings.dart';

/// Bandeau « Bienvenue, `pseudo` ! » affiché après le premier lancement (issue #544).
/// [onEdit] ouvre la section Profil des Paramètres.
class WelcomeBanner extends StatelessWidget {
  const WelcomeBanner({super.key, required this.name, required this.onEdit});

  final String name;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xFFFFF8E7),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF15264D), width: 2),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 8, 8),
        child: Row(
          children: [
            Expanded(
              child: Text(
                Strings.welcomeTitle.replaceFirst('{name}', name),
                style: const TextStyle(
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF15264D),
                ),
              ),
            ),
            TextButton(
              onPressed: onEdit,
              child: Text(Strings.welcomeEdit),
            ),
          ],
        ),
      ),
    );
  }
}
