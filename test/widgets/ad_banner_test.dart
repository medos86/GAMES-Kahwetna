import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kahwetne/core/strings.dart';
import 'package:kahwetne/widgets/ad_banner.dart';

void main() {
  Future<void> pumpBanner(WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: Align(alignment: Alignment.bottomCenter, child: AdBanner()),
        ),
      ),
    );
  }

  testWidgets('affiche la bannière avec son bouton Voir', (tester) async {
    await pumpBanner(tester);
    expect(find.text(Strings.adLabel), findsOneWidget);
    expect(find.text(Strings.adSee), findsOneWidget);
    expect(find.byType(SnackBar), findsNothing);
  });

  testWidgets(
    'Voir affiche le toast « Espace publicitaire de démonstration »',
    (tester) async {
      await pumpBanner(tester);

      await tester.tap(find.text(Strings.adSee));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.byType(SnackBar), findsOneWidget);
      expect(find.text('Espace publicitaire de démonstration'), findsOneWidget);
    },
  );

  testWidgets(
    'un second appui remplace le toast au lieu d\'en empiler un autre',
    (tester) async {
      await pumpBanner(tester);

      await tester.tap(find.text(Strings.adSee));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      await tester.tap(find.text(Strings.adSee));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 600));
      await tester.pumpAndSettle();

      expect(find.text(Strings.adDemoToast), findsOneWidget);
    },
  );
}
