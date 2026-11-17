import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kahwetne/widgets/trophy_badge.dart';

// Coupe BD : le score est centré dans le bol de la coupe (#351).
void main() {
  testWidgets(
    'le score est centré dans le bol de la coupe',
    (tester) async {
      const size = 80.0;
      await tester.pumpWidget(
        const MaterialApp(
          home: Center(child: TrophyBadge(target: 11, size: size)),
        ),
      );
      await tester.pump();

      final cup = tester.getRect(find.byType(SvgPicture));
      final score = tester.getCenter(find.text('11').first);

      expect(score.dx, closeTo(cup.center.dx, 1));
      // Centre du bol : 34 % de la hauteur de la coupe.
      expect(score.dy, closeTo(cup.top + cup.height * 0.34, 2));
    },
  );

  testWidgets(
    'la coupe affiche le score en contour et en remplissage',
    (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Center(child: TrophyBadge(target: 21)),
        ),
      );
      await tester.pump();

      expect(find.text('21'), findsNWidgets(2));
      expect(find.byType(SvgPicture), findsOneWidget);
    },
  );
}
