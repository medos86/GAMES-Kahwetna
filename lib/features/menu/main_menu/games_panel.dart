part of '../main_menu_screen.dart';

class _GamesPanel extends StatelessWidget {
  const _GamesPanel({
    required this.difficulty,
    required this.sm,
    required this.md,
    required this.onSelect,
  });

  final Difficulty difficulty;
  final bool sm;
  final bool md;
  final void Function(GameEntry) onSelect;

  @override
  Widget build(BuildContext context) {
    return _GlassPanel(
      difficulty: difficulty,
      radius: 28,
      padding: EdgeInsets.all(md ? 20 : (sm ? 16 : 12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        Strings.menuChooseTable,
                        style: TextStyle(
                          fontSize: sm ? 12 : 10,
                          fontWeight: FontWeight.w900,
                          letterSpacing: (sm ? 12 : 10) * 0.22,
                          color: const Color(0xFFFFE277),
                        ),
                      ),
                      Text(
                        Strings.menuStart,
                        style: TextStyle(
                          fontFamily: 'RobotoSlab',
                          fontSize: sm ? 24 : 20,
                          fontWeight: FontWeight.w900,
                          height: 1.25,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: const Color(0x1AFFFFFF),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: Color(0xFF6EE7B7),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(color: Color(0xFF6EE7B7), blurRadius: 8),
                        ],
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '${gameEntries.length} tables',
                      style: TextStyle(
                        fontSize: sm ? 12 : 10,
                        fontWeight: FontWeight.w800,
                        color: const Color(0xBFFFFFFF),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: sm ? 16 : 12),
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.only(right: 4),
              itemCount: gameEntries.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, i) {
                final game = gameEntries[i];
                return FadeSlideIn(
                  delay: Duration(milliseconds: 220 + i * 70),
                  offset: const Offset(0, 0.1),
                  child: _GameTile(
                    game: game,
                    sm: sm,
                    onTap: () => onSelect(game),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _GameTile extends StatelessWidget {
  const _GameTile({required this.game, required this.sm, required this.onTap});

  final GameEntry game;
  final bool sm;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(21.6);
    return Pressable(
      semanticLabel: game.name,
      onTap: onTap,
      pressedScale: 0.97,
      child: Container(
        constraints: BoxConstraints(minHeight: sm ? 94 : 82),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [game.gradientFrom, game.gradientTo],
          ),
          borderRadius: radius,
          border: Border.all(color: _ink, width: 3),
          boxShadow: [
            BoxShadow(color: game.edgeColor, offset: const Offset(0, 6)),
            const BoxShadow(
              color: _shadowSoft,
              offset: Offset(0, 11),
              blurRadius: 22,
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: radius,
          child: Stack(
            children: [
              // Trame de points propre au bouton : radial-gradient(#17203f 1.1px) 6px, opacité 0.09.
              const Positioned.fill(
                child: DotPattern(
                  spacing: 6,
                  radius: 1.1,
                  color: Color(0x1717203F),
                ),
              ),
              Positioned(
                right: -20,
                top: -32,
                child: Container(
                  width: 112,
                  height: 112,
                  decoration: const BoxDecoration(
                    color: Color(0x33FFFFFF),
                    shape: BoxShape.circle,
                  ),
                ),
              ),
              Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: sm ? 20 : 12,
                  vertical: 10,
                ),
                child: Row(
                  children: [
                    Container(
                      width: sm ? 64 : 56,
                      height: sm ? 64 : 56,
                      decoration: BoxDecoration(
                        color: const Color(0x29FFFFFF),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0x4DFFFFFF)),
                      ),
                      alignment: Alignment.center,
                      child: Transform.scale(
                        scale: sm ? 1 : 0.88,
                        child: SvgPicture.string(
                          gameIconSvg[game.name]!,
                          width: 56,
                          height: 56,
                        ),
                      ),
                    ),
                    SizedBox(width: sm ? 16 : 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            game.name,
                            style: TextStyle(
                              fontFamily: 'RobotoSlab',
                              fontSize: sm ? 24 : 20,
                              fontWeight: FontWeight.w900,
                              height: 1,
                              letterSpacing: -0.025 * (sm ? 24 : 20),
                              color: Colors.white,
                              shadows: const [
                                Shadow(
                                  offset: Offset(0, 2),
                                  color: Color(0x73132249),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            game.tunisian,
                            style: TextStyle(
                              fontSize: sm ? 14 : 12,
                              fontWeight: FontWeight.w900,
                              color: const Color(0xB3FFFFFF),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      width: 36,
                      height: 36,
                      decoration: const BoxDecoration(
                        color: Color(0x4015264D),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.chevron_right,
                        size: 20,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
