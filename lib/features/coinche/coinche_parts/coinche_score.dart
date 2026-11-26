part of '../coinche_screen.dart';

class _Header extends StatelessWidget {
  const _Header({required this.controller, required this.difficulty});

  final CoincheController controller;
  final Difficulty difficulty;

  @override
  Widget build(BuildContext context) {
    return GameHeader(
      onMenu: () => Navigator.of(context).maybePop(),
      center: Expanded(
        child: Center(
          child: Text(
            'Manche ${controller.match.round}',
            style: const TextStyle(fontWeight: FontWeight.w800),
          ),
        ),
      ),
      trailing: TrophyBadge(
        target: controller.match.target,
        size: 48,
        tint: difficultyTint(difficulty),
      ),
    );
  }
}
