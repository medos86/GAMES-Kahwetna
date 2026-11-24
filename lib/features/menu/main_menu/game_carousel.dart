import 'dart:math' as math;

import 'package:flutter_svg/flutter_svg.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/audio/sounds.dart';
import '../../../widgets/pressable.dart';
import '../game_icons.dart';
import '../menu_models.dart';

const _carouselInk = Color(0xFF17203F);

/// Index réel (0..n-1) d'une page du carrousel, qui boucle à l'infini.
int carouselIndexOf(int page) => page % gameEntries.length;

/// Carrousel 3D des jeux : un grand carré au centre, à faire glisser ou à
/// changer avec les flèches gauche et droite.
class GameCarousel extends StatefulWidget {
  const GameCarousel({
    super.key,
    required this.onSelect,
    required this.onChanged,
  });

  final void Function(GameEntry) onSelect;
  final void Function(GameEntry) onChanged;

  @override
  State<GameCarousel> createState() => _GameCarouselState();
}

class _GameCarouselState extends State<GameCarousel> {
  // Page de départ multiple du nombre de jeux : le carrousel boucle sans bord.
  final int _start = gameEntries.length * 1000;

  late final PageController _controller = PageController(
    initialPage: _start,
    viewportFraction: 0.66,
  );
  late int _page = _start;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _move(int delta) {
    _controller.animateToPage(
      _page + delta,
      duration: const Duration(milliseconds: 380),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, c) {
        final side = math.min(c.maxWidth * 0.62, c.maxHeight * 0.86);
        final focused = gameEntries[carouselIndexOf(_page)];
        return Column(
          children: [
            Expanded(
              child: Row(
                children: [
                  _ArrowButton(
                    icon: Icons.chevron_left,
                    semanticLabel: 'Jeu précédent',
                    color: focused.gradientFrom,
                    onTap: () => _move(-1),
                  ),
                  Expanded(
                    child: PageView.builder(
                      controller: _controller,
                      onPageChanged: (page) {
                        setState(() => _page = page);
                        widget.onChanged(gameEntries[carouselIndexOf(page)]);
                      },
                      itemBuilder: (context, page) {
                        return AnimatedBuilder(
                          animation: _controller,
                          builder: (context, _) {
                            final current = _controller.hasClients
                                ? (_controller.page ?? _start.toDouble())
                                : _start.toDouble();
                            return _CarouselItem(
                              game: gameEntries[carouselIndexOf(page)],
                              offset: page - current,
                              side: side,
                              onTap: () {
                                if (page == _page) {
                                  widget.onSelect(
                                    gameEntries[carouselIndexOf(page)],
                                  );
                                } else {
                                  _controller.animateToPage(
                                    page,
                                    duration: const Duration(
                                      milliseconds: 380,
                                    ),
                                    curve: Curves.easeOutCubic,
                                  );
                                }
                              },
                            );
                          },
                        );
                      },
                    ),
                  ),
                  _ArrowButton(
                    icon: Icons.chevron_right,
                    semanticLabel: 'Jeu suivant',
                    color: focused.gradientFrom,
                    onTap: () => _move(1),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            _Dots(active: carouselIndexOf(_page)),
          ],
        );
      },
    );
  }
}

class _CarouselItem extends StatelessWidget {
  const _CarouselItem({
    required this.game,
    required this.offset,
    required this.side,
    required this.onTap,
  });

  final GameEntry game;
  final double offset;
  final double side;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final distance = offset.abs().clamp(0.0, 1.0);
    final transform = Matrix4.identity()
      ..setEntry(3, 2, 0.0012)
      ..rotateY(-offset.clamp(-1.0, 1.0) * 0.55)
      ..scaleByDouble(
        1 - 0.2 * distance,
        1 - 0.2 * distance,
        1,
        1,
      );

    return Center(
      child: Opacity(
        opacity: 1 - 0.45 * distance,
        child: Transform(
          alignment: Alignment.center,
          transform: transform,
          child: Pressable(
            sound: Sfx.uiClick,
            semanticLabel: game.name,
            onTap: onTap,
            child: SizedBox.square(
              dimension: side,
              child: _GameCard(game: game),
            ),
          ),
        ),
      ),
    );
  }
}

class _GameCard extends StatelessWidget {
  const _GameCard({required this.game});

  final GameEntry game;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(36);
    return AnimatedContainer(
      duration: const Duration(milliseconds: 400),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [game.gradientFrom, game.gradientTo],
        ),
        borderRadius: radius,
        border: Border.all(color: _carouselInk, width: 4),
        boxShadow: [
          // Épaisseur 3D : la carte « sort » de l'écran.
          BoxShadow(
            color: game.edgeColor,
            offset: const Offset(0, 14),
          ),
          const BoxShadow(
            color: Color(0x33132249),
            offset: Offset(0, 22),
            blurRadius: 30,
          ),
        ],
      ),
      child: LayoutBuilder(
        builder: (context, c) {
          final side = c.maxWidth;
          return Stack(
            // Pas de découpe ici : la tête de la mascotte peut dépasser la carte.
            clipBehavior: Clip.none,
            fit: StackFit.expand,
            children: [
              ClipRRect(
                borderRadius: radius,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Opacity(
                      opacity: 0.28,
                      child: Image.asset(
                        game.backgroundAsset,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                      ),
                    ),
                    Positioned(
                      right: -30,
                      top: -30,
                      child: Container(
                        width: 150,
                        height: 150,
                        decoration: const BoxDecoration(
                          color: Color(0x33FFFFFF),
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              // Mascotte agrandie au maximum ; la tête sort légèrement du bord haut.
              Positioned(
                top: -side * 0.06,
                left: 0,
                right: 0,
                child: Center(
                  child: _MascotPhoto(game: game, size: side * 0.56),
                ),
              ),
              // Le nom du jeu remplace l'ancien bouton « JOUER ».
              Positioned(
                left: 16,
                right: 16,
                bottom: 16,
                child: Center(child: _NamePill(game: game)),
              ),
            ],
          );
        },
      ),
    );
  }
}

/// Nom du jeu en Bangers sur une pastille encre, en bas de la carte.
class _NamePill extends StatelessWidget {
  const _NamePill({required this.game});

  final GameEntry game;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 6),
      decoration: BoxDecoration(
        color: _carouselInk,
        borderRadius: BorderRadius.circular(999),
      ),
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Text(
          game.name,
          maxLines: 1,
          style: const TextStyle(
            fontFamily: 'Bangers',
            fontSize: 30,
            letterSpacing: 2,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}

/// Mascotte détourée : elle sort du médaillon 3D (chapeau qui dépasse).
/// Sans photo (repli), l'icône SVG est posée dans le médaillon.
class _MascotPhoto extends StatelessWidget {
  const _MascotPhoto({required this.game, required this.size});

  final GameEntry game;
  final double size;

  @override
  Widget build(BuildContext context) {
    final photo = game.photoAsset;
    return SizedBox(
      width: size * 1.5,
      height: size * 1.5,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.bottomCenter,
        children: [
          Positioned(
            bottom: 0,
            child: Container(
              width: size,
              height: size,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  center: const Alignment(-0.3, -0.4),
                  colors: [Colors.white, game.gradientFrom],
                ),
                border: Border.all(color: _carouselInk, width: 5),
                boxShadow: [
                  BoxShadow(color: game.edgeColor, offset: const Offset(0, 10)),
                  const BoxShadow(
                    color: Color(0x55132249),
                    offset: Offset(0, 18),
                    blurRadius: 18,
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            bottom: size * 0.1,
            child: photo == null
                ? Padding(
                    padding: EdgeInsets.all(size * 0.2),
                    child: SizedBox.square(
                      dimension: size * 0.8,
                      child: SvgPicture.string(gameIconSvg[game.name]!),
                    ),
                  )
                : Image.asset(
                    photo,
                    height: size * 1.4,
                    fit: BoxFit.contain,
                    errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                  ),
          ),
        ],
      ),
    );
  }
}

class _ArrowButton extends StatelessWidget {
  const _ArrowButton({
    required this.icon,
    required this.semanticLabel,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final String semanticLabel;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Pressable(
        sound: Sfx.uiClick,
        semanticLabel: semanticLabel,
        onTap: onTap,
        child: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            border: Border.all(color: _carouselInk, width: 3),
            boxShadow: const [
              BoxShadow(color: _carouselInk, offset: Offset(0, 4)),
            ],
          ),
          child: Icon(icon, color: Colors.white, size: 30),
        ),
      ),
    );
  }
}

class _Dots extends StatelessWidget {
  const _Dots({required this.active});

  final int active;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        for (var i = 0; i < gameEntries.length; i++)
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            margin: const EdgeInsets.symmetric(horizontal: 4),
            width: i == active ? 22 : 9,
            height: 9,
            decoration: BoxDecoration(
              color: i == active
                  ? gameEntries[i].gradientFrom
                  : const Color(0x66FFFFFF),
              borderRadius: BorderRadius.circular(999),
            ),
          ),
      ],
    );
  }
}

/// Teinte de fond qui suit le jeu affiché : chaque jeu a sa couleur et son ambiance.
class MoodTint extends StatelessWidget {
  const MoodTint({super.key, required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeOut,
        decoration: BoxDecoration(
          gradient: RadialGradient(
            center: const Alignment(0, -0.2),
            radius: 1.1,
            colors: [
              color.withValues(alpha: 0.45),
              color.withValues(alpha: 0),
            ],
          ),
        ),
      ),
    );
  }
}
