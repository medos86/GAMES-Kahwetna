import 'package:flutter_test/flutter_test.dart';
import 'package:kahwetne/widgets/felt_turn_ring.dart';
import 'package:material_ui/material_ui.dart';

void main() {
  Widget host(bool active) {
    return MaterialApp(
      home: Scaffold(
        body: FeltTurnRing(
          active: active,
          child: const SizedBox(width: 40, height: 40),
        ),
      ),
    );
  }

  Color ringColor(WidgetTester tester) {
    final container = tester.widget<Container>(
      find.descendant(
        of: find.byType(FeltTurnRing),
        matching: find.byType(Container),
      ),
    );
    return (container.decoration! as BoxDecoration).color!;
  }

  testWidgets('anneau actif en accent BD', (tester) async {
    await tester.pumpWidget(host(true));
    expect(ringColor(tester), FeltTurnRing.accent);
  });

  testWidgets('anneau inactif transparent et même taille', (tester) async {
    await tester.pumpWidget(host(true));
    final activeSize = tester.getSize(find.byType(FeltTurnRing));
    await tester.pumpWidget(host(false));
    expect(ringColor(tester).a, 0);
    expect(tester.getSize(find.byType(FeltTurnRing)), activeSize);
  });
}
