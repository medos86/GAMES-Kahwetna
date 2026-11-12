import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kahwetne/features/comic_demo/comic_demo_screen.dart';

void main() {
  testWidgets(
    'la page de démo BD se construit et change de langue localement',
    (tester) async {
      await tester.pumpWidget(const MaterialApp(home: ComicDemoScreen()));
      await tester.pumpAndSettle();
      expect(find.text('Démo BD'), findsOneWidget);
      expect(find.text('PAFF !'), findsWidgets);

      // Bascule vers l'arabe : le bouton affiche alors « FR ».
      await tester.tap(find.text('AR'));
      await tester.pumpAndSettle();
      expect(find.text('FR'), findsOneWidget);
      expect(find.text('ابدأ اللعب'), findsOneWidget);
    },
  );

  testWidgets('toucher une onomatopée la rejoue sans erreur', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: ComicDemoScreen()));
    await tester.pumpAndSettle();
    await tester.tap(find.text('BAM !').first);
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });
}
