import 'dart:ui';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kahwetne/widgets/round_result_panel.dart';
import 'package:kahwetne/widgets/win_celebration.dart';

Widget host(Widget child, {bool disableAnimations = false}) => MediaQuery(
      data: MediaQueryData(disableAnimations: disableAnimations),
      child: Directionality(
        textDirection: TextDirection.ltr,
        child: SizedBox(width: 400, height: 700, child: child),
      ),
    );

void main() {
  testWidgets('victoire : confettis, pas de défaite', (tester) async {
    await tester.pumpWidget(host(const WinCelebration(won: true)));
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.byKey(const Key('win-celebration-confetti')), findsOneWidget);
    expect(find.byKey(const Key('win-celebration-defeat')), findsNothing);
    final paint = tester.widget<CustomPaint>(
      find.byKey(const Key('win-celebration-confetti')),
    );
    expect(paint.painter, isA<WinCelebrationPainter>());
    expect((paint.painter! as WinCelebrationPainter).won, isTrue);
  });

  testWidgets('défaite : aucun confetti', (tester) async {
    await tester.pumpWidget(host(const WinCelebration(won: false)));
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.byKey(const Key('win-celebration-confetti')), findsNothing);
    expect(find.byKey(const Key('win-celebration-defeat')), findsOneWidget);
    final paint = tester.widget<CustomPaint>(
      find.byKey(const Key('win-celebration-defeat')),
    );
    expect((paint.painter! as WinCelebrationPainter).won, isFalse);
  });

  testWidgets('animation finie, plus de frame', (tester) async {
    await tester.pumpWidget(host(const WinCelebration(won: true)));

    // pumpAndSettle échoue si une animation tourne sans fin.
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('win-celebration-confetti')), findsNothing);
    expect(tester.hasRunningAnimations, isFalse);
    expect(tester.binding.hasScheduledFrame, isFalse);
  });

  testWidgets('réduction des animations', (tester) async {
    await tester.pumpWidget(
      host(
        const WinCelebration(won: true),
        disableAnimations: true,
      ),
    );
    await tester.pump();

    expect(find.byKey(const Key('win-celebration-confetti')), findsNothing);
    expect(find.byKey(const Key('win-celebration-defeat')), findsNothing);
    expect(tester.hasRunningAnimations, isFalse);
  });

  testWidgets('ne capte pas les touches', (tester) async {
    var taps = 0;
    await tester.pumpWidget(
      host(
        Stack(
          children: [
            Positioned.fill(
              child: GestureDetector(
                onTap: () => taps++,
                child: const SizedBox.expand(),
              ),
            ),
            const WinCelebration(won: true),
          ],
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 200));
    await tester.tap(find.byType(GestureDetector));
    expect(taps, 1);
  });

  testWidgets('RoundResultPanel won: true', (tester) async {
    await tester.pumpWidget(
      host(
        const RoundResultPanel(
          title: 'Victoire !',
          badge: 'PARTIE TERMINÉE',
          rows: [],
          actions: [],
          won: true,
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.byKey(const Key('win-celebration-confetti')), findsOneWidget);
  });

  testWidgets('RoundResultPanel sans won', (tester) async {
    await tester.pumpWidget(
      host(
        const RoundResultPanel(
          title: 'Manche 1',
          badge: 'MANCHE 1',
          rows: [],
          actions: [],
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.byType(WinCelebration), findsNothing);
  });

  group('WinCelebrationPainter', () {
    // Peint à plusieurs instants de l'animation, victoire comme défaite :
    // vérifie qu'aucun chemin de dessin ne lève d'erreur.
    for (final won in [true, false]) {
      test('peint sans erreur (won: $won) à toutes les étapes', () {
        const size = Size(400, 700);
        for (final t in [0.0, 0.1, 0.3, 0.5, 0.8, 0.95, 1.0]) {
          final recorder = PictureRecorder();
          final canvas = Canvas(recorder);
          WinCelebrationPainter(progress: t, won: won).paint(canvas, size);
          expect(recorder.endRecording(), isNotNull);
        }
      });
    }

    test('repeint seulement si la progression ou le résultat change', () {
      final a = WinCelebrationPainter(progress: 0.5, won: true);
      final same = WinCelebrationPainter(progress: 0.5, won: true);
      final later = WinCelebrationPainter(progress: 0.6, won: true);
      final lost = WinCelebrationPainter(progress: 0.5, won: false);
      expect(a.shouldRepaint(same), isFalse);
      expect(a.shouldRepaint(later), isTrue);
      expect(a.shouldRepaint(lost), isTrue);
    });
  });
}
