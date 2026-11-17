// Bouton d'action compact du Rami : icône et libellé visibles, tap seulement si activé.
import 'package:flutter_test/flutter_test.dart';
import 'package:kahwetne/features/rami/rami_action_button.dart';
import 'package:material_ui/material_ui.dart';

void main() {
  testWidgets('affiche son icône et son libellé', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: RamiActionButton(
            label: 'Poser',
            icon: Icons.check,
            onTap: () {},
          ),
        ),
      ),
    );
    expect(find.text('Poser'), findsOneWidget);
    expect(find.byIcon(Icons.check), findsOneWidget);
  });

  testWidgets('un tap appelle onTap', (tester) async {
    var taps = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: RamiActionButton(
            label: 'Poser',
            icon: Icons.check,
            onTap: () => taps++,
          ),
        ),
      ),
    );
    await tester.tap(find.text('Poser'));
    expect(taps, 1);
  });

  testWidgets('un bouton désactivé ne réagit pas', (tester) async {
    var taps = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: RamiActionButton(
            label: 'Poser',
            icon: Icons.check,
            enabled: false,
            onTap: () => taps++,
          ),
        ),
      ),
    );
    await tester.tap(find.text('Poser'));
    expect(taps, 0);
  });
}
