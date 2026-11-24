import 'package:flutter_test/flutter_test.dart';
import 'package:kahwetne/features/rami/rami_action_button.dart';
import 'package:material_ui/material_ui.dart';

/// Issue #862 : boutons Annuler / Défausser en icône seule, libellé accessible.
void main() {
  testWidgets('icône seule : pas de texte visible, libellé accessible',
      (tester) async {
    var taps = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: RamiActionButton(
            label: 'Défausser',
            icon: Icons.south,
            onTap: () => taps++,
            iconOnly: true,
          ),
        ),
      ),
    );
    expect(find.text('Défausser'), findsNothing);
    expect(find.byIcon(Icons.south), findsOneWidget);
    expect(find.bySemanticsLabel('Défausser'), findsOneWidget);
    expect(find.byTooltip('Défausser'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.south));
    expect(taps, 1);
  });

  testWidgets('icône seule désactivée : ne réagit pas', (tester) async {
    var taps = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: RamiActionButton(
            label: 'Annuler',
            icon: Icons.close,
            onTap: () => taps++,
            enabled: false,
            iconOnly: true,
          ),
        ),
      ),
    );
    await tester.tap(find.byIcon(Icons.close), warnIfMissed: false);
    expect(taps, 0);
  });

  testWidgets('par défaut, le libellé reste affiché', (tester) async {
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
  });
}
