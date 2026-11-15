part of '../chkobba_screen.dart';

/// Fond bois du jeu React (style d'origine) : bandes brunes verticales.
/// Fond village calmé : image désaturée et voilée, pour que le tapis et les cartes ressortent.
class _CalmBackground extends StatelessWidget {
  const _CalmBackground();

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        ColorFiltered(
          colorFilter: const ColorFilter.matrix(_saturation40),
          child: Image.asset(
            'assets/images/background.webp',
            fit: BoxFit.cover,
          ),
        ),
        const DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0x99000000), Color(0xCC000000)],
            ),
          ),
        ),
      ],
    );
  }
}

// Matrice de saturation à 40 % (luminance Rec. 709).
const _saturation40 = <double>[
  0.52756,
  0.42912,
  0.04332,
  0,
  0,
  0.12756,
  0.82912,
  0.04332,
  0,
  0,
  0.12756,
  0.42912,
  0.44332,
  0,
  0,
  0,
  0,
  0,
  1,
  0,
];

class _WoodBackground extends StatelessWidget {
  const _WoodBackground();

  @override
  Widget build(BuildContext context) {
    return CustomPaint(painter: _WoodPainter());
  }
}

class _WoodPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(
      Offset.zero & size,
      Paint()..color = const Color(0xFF8B4513),
    );
    final light = Paint()..color = const Color(0xFFA0522D);
    final dark = Paint()..color = const Color(0xFF654321);
    for (double x = 0; x < size.width; x += 8) {
      canvas.drawRect(Rect.fromLTWH(x + 2, 0, 2, size.height), light);
      canvas.drawRect(Rect.fromLTWH(x + 6, 0, 2, size.height), dark);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
