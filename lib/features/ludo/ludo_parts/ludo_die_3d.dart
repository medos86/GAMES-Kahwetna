part of '../ludo_screen.dart';

/// Durée du lancer 3D, calée sur `dice.wav` (environ 1,09 s) : le son et le
/// mouvement partent et se posent ensemble (#998).
const Duration kLudoDieRollDuration = Duration(milliseconds: 1090);

/// Tours complets autour de chaque axe pendant le lancer : les six faces défilent
/// plusieurs fois avant la pose. Entiers, pour que la pose finale soit exacte.
const int _kSpinTurnsX = 3;
const int _kSpinTurnsY = 4;

/// Perspective du cube (valeur absolue plus petite = vue plus plate).
const double _kDiePerspective = 0.0015;

/// Placement de la face [value] (1 à 6) : sa normale devient l'axe Z local.
Matrix4 ludoDieFacePlacement(int value) {
  switch (value) {
    case 2:
      return Matrix4.rotationX(math.pi / 2);
    case 3:
      return Matrix4.rotationY(math.pi / 2);
    case 4:
      return Matrix4.rotationY(-math.pi / 2);
    case 5:
      return Matrix4.rotationX(-math.pi / 2);
    case 6:
      return Matrix4.rotationY(math.pi);
    default:
      return Matrix4.identity();
  }
}

/// Orientation finale du cube : ramène la face [value] face à l'écran.
Matrix4 ludoDiePose(int value) => Matrix4.inverted(ludoDieFacePlacement(value));

/// Orientation du cube à l'instant [t] (de 0 à 1). Les tours restants
/// s'annulent à la fin : la face [value] se retrouve face à l'écran.
Matrix4 ludoDieCubeMatrix(int value, double t) {
  final progress = math.min(math.max(t, 0.0), 1.0);
  final remain = 1 - Curves.easeOutCubic.transform(progress);
  final spinY = Matrix4.rotationY(remain * _kSpinTurnsY * 2 * math.pi);
  final spinX = Matrix4.rotationX(remain * _kSpinTurnsX * 2 * math.pi);
  return spinY * spinX * ludoDiePose(value);
}

/// Part d'ombre maximale d'une face (0 = face pleine lumière).
const double kLudoDieMaxShade = 0.45;

/// Face vue de biais sous ce seuil de « z » n'est pas dessinée (#1072).
const double kLudoDieEdgeCull = 0.08;

/// Ombrage d'une face selon son orientation [facing] (composante z de la normale) :
/// plus elle regarde de biais, plus elle est sombre, pour un cube qui a du volume (#1072).
double ludoDieShade(double facing) {
  final lit = facing.clamp(0.0, 1.0);
  return kLudoDieMaxShade * (1 - lit);
}

/// Valeur de la face la plus tournée vers l'écran pour l'orientation [cube].
int ludoDieFrontFace(Matrix4 cube) {
  var best = 1;
  var bestZ = double.negativeInfinity;
  for (var v = 1; v <= 6; v++) {
    final z = (cube * ludoDieFacePlacement(v)).storage[10];
    if (z > bestZ) {
      bestZ = z;
      best = v;
    }
  }
  return best;
}

/// Lancer 3D : le cube passe de l'orientation de départ à la pose de [value].
class _LudoDieTumble extends StatelessWidget {
  const _LudoDieTumble({
    required this.value,
    required this.tone,
    required this.size,
  });

  final int value;
  final Color tone;
  final double size;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: kLudoDieRollDuration,
      builder: (context, t, _) => _LudoDieCube(
        cube: ludoDieCubeMatrix(value, t),
        tone: tone,
        size: size,
      ),
    );
  }
}

/// Cube dessiné à partir de ses six faces en perspective. Les faces tournées
/// vers l'arrière sont cachées ; les autres sont peintes du fond vers l'avant.
class _LudoDieCube extends StatelessWidget {
  const _LudoDieCube({
    required this.cube,
    required this.tone,
    required this.size,
  });

  final Matrix4 cube;
  final Color tone;
  final double size;

  @override
  Widget build(BuildContext context) {
    final half = size / 2;
    // Entrée (3,2) négative : l'œil est en +Z, les faces de +Z sont vers l'écran.
    final perspective = Matrix4.identity()..setEntry(3, 2, -_kDiePerspective);
    final faces = <({double depth, Matrix4 matrix, int value, double shade})>[];
    for (var v = 1; v <= 6; v++) {
      final facing = cube * ludoDieFacePlacement(v);
      // Face de biais (quasi de profil) : trait fin qui ferait des lignes parasites (#1072).
      if (facing.storage[10] <= kLudoDieEdgeCull) continue;
      final model = facing * Matrix4.translationValues(0, 0, half);
      faces.add((
        depth: model.storage[14],
        matrix: perspective * model,
        value: v,
        shade: ludoDieShade(facing.storage[10]),
      ));
    }
    faces.sort((a, b) => a.depth.compareTo(b.depth));
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.center,
        children: [
          for (final face in faces)
            ColorFiltered(
              colorFilter: ColorFilter.mode(
                Color.fromRGBO(0, 0, 0, face.shade),
                BlendMode.srcATop,
              ),
              child: Transform(
                alignment: Alignment.center,
                transform: face.matrix,
                child: LudoDie(
                  value: face.value,
                  tone: tone,
                  size: size,
                  animate: false,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
