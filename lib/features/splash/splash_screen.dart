import 'dart:async';

import 'package:material_ui/material_ui.dart';

import '../../core/strings.dart';

/// Écran d'ouverture : fond du village, titre et message, puis passage au widget `next`.
/// Un appui sur l'écran passe directement à la suite.
class SplashScreen extends StatefulWidget {
  const SplashScreen({
    super.key,
    required this.next,
    this.duration = const Duration(milliseconds: 2400),
  });

  final Widget next;
  final Duration duration;

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  Timer? _timer;
  bool _leaving = false;

  @override
  void initState() {
    super.initState();
    _timer = Timer(widget.duration, _goNext);
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _goNext() {
    if (_leaving || !mounted) return;
    _leaving = true;
    _timer?.cancel();
    Navigator.of(context).pushReplacement(
      PageRouteBuilder<void>(
        transitionDuration: const Duration(milliseconds: 500),
        pageBuilder: (_, __, ___) => widget.next,
        transitionsBuilder: (_, animation, __, child) =>
            FadeTransition(opacity: animation, child: child),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: _goNext,
      child: Scaffold(
        backgroundColor: const Color(0xFF2BB8EA),
        body: Stack(
          fit: StackFit.expand,
          children: [
            Image.asset(
              'assets/images/background.webp',
              fit: BoxFit.cover,
              alignment: Alignment.center,
              errorBuilder: (_, error, __) => ColoredBox(
                color: const Color(0xFF2BB8EA),
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    // Diagnostic temporaire : affiche la raison exacte si l'image ne se charge pas.
                    child: Text(
                      'Fond introuvable : $error',
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.white, fontSize: 12),
                    ),
                  ),
                ),
              ),
            ),
            // Voile léger pour lire le titre sur le fond.
            const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Color(0x33063A6B),
                    Color(0x00000000),
                    Color(0x99101638),
                  ],
                ),
              ),
            ),
            SafeArea(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    'Kahwetne',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: 'BowlbyOneSC',
                      fontSize: 64,
                      height: 1,
                      color: Color(0xFFFFF8E7),
                      shadows: [
                        Shadow(offset: Offset(0, 5), color: Color(0xFF173A79)),
                        Shadow(
                          offset: Offset(0, 9),
                          blurRadius: 18,
                          color: Color(0x610B1C44),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'لمّـة، ضحكة ولعبة تونسية',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: Color(0xF2FFFFFF),
                      shadows: [
                        Shadow(
                          offset: Offset(0, 2),
                          blurRadius: 7,
                          color: Color(0xBF07193C),
                        ),
                      ],
                    ),
                  ),
                  const Spacer(),
                  Padding(
                    padding: EdgeInsets.only(bottom: 48),
                    child: Text(
                      Strings.splashTap,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: Color(0xCCFFFFFF),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
