import 'package:flutter_test/flutter_test.dart';
import 'package:kahwetne/widgets/pulse_glow.dart';
import 'package:material_ui/material_ui.dart';

// Halo de la pioche (#276) : le contenu reste affiché, actif ou non.
void main() {
  testWidgets('halo actif : le contenu reste affiché pendant la pulsation', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Center(child: PulseGlow(active: true, child: Text('pioche'))),
      ),
    );
    await tester.pump(const Duration(milliseconds: 450));
    expect(find.text('pioche'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('halo inactif : le contenu est affiché sans animation', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Center(child: PulseGlow(active: false, child: Text('pioche'))),
      ),
    );
    expect(find.text('pioche'), findsOneWidget);
    expect(tester.hasRunningAnimations, isFalse);
  });
}
