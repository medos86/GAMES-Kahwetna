import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kahwetne/core/services/card_animations.dart';
import 'package:kahwetne/widgets/card_motion.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Moteur commun de mouvement (#266) : la case d'arrivée reste masquée pendant le vol.
class _Probe extends StatefulWidget {
  const _Probe({super.key});

  @override
  State<_Probe> createState() => _ProbeState();
}

class _ProbeState extends State<_Probe> with CardMotionMixin<_Probe> {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        MaskedSlot(
          hidden: landing.contains('a'),
          child: const SizedBox(width: 40, height: 40, child: Text('case')),
        ),
      ],
    );
  }
}

Finder maskedSlots() =>
    find.byWidgetPredicate((w) => w is MaskedSlot && w.hidden);

CardFlight flightA() {
  return CardFlight(
    from: const Rect.fromLTWH(0, 0, 40, 40),
    to: () => const Rect.fromLTWH(200, 200, 40, 40),
    child: const Text('vol'),
    landingId: 'a',
  );
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    cardAnimations.value = true;
  });

  tearDown(() => cardAnimations.value = false);

  testWidgets('MaskedSlot vide quand masqué', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Column(
          children: [
            MaskedSlot(hidden: true, child: Text('cache')),
          ],
        ),
      ),
    );
    expect(
      find.byWidgetPredicate((w) => w is Opacity && w.opacity == 0),
      findsOneWidget,
    );
  });

  testWidgets('case masquée pendant le vol', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: Scaffold(body: _Probe())));
    final state = tester.state<_ProbeState>(find.byType(_Probe));

    state.flyAfterRender([flightA()]);
    // Masque posé dès l'appel, avant le premier rendu du vol.
    expect(state.landing, contains('a'));
    await tester.pump();
    await tester.pump();
    expect(maskedSlots(), findsOneWidget);
    expect(find.text('vol'), findsOneWidget);

    await tester.pump(const Duration(seconds: 1));
    expect(state.landing, isEmpty);
    expect(maskedSlots(), findsNothing);
    expect(find.text('vol'), findsNothing);
  });

  testWidgets('sans animations : pas de vol', (tester) async {
    cardAnimations.value = false;
    await tester.pumpWidget(const MaterialApp(home: Scaffold(body: _Probe())));
    final state = tester.state<_ProbeState>(find.byType(_Probe));

    state.flyAfterRender([flightA()]);
    await tester.pump();
    await tester.pump();
    expect(find.text('vol'), findsNothing);
    expect(state.landing, isEmpty);
    expect(maskedSlots(), findsNothing);
  });
}
