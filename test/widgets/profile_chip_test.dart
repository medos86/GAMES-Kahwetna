import 'package:flutter_test/flutter_test.dart';
import 'package:kahwetne/widgets/profile_chip.dart';
import 'package:material_ui/material_ui.dart';

/// Issue #546 : la pastille affiche le pseudo, se tape et tient dans une petite largeur.
void main() {
  testWidgets('affiche le pseudo et appelle onTap', (tester) async {
    var taps = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Row(
            children: [
              ProfileChip(
                name: 'Sfaxi_Lion',
                avatarId: 'lion',
                onTap: () => taps++,
              ),
            ],
          ),
        ),
      ),
    );
    expect(find.text('Sfaxi_Lion'), findsOneWidget);
    await tester.tap(find.text('Sfaxi_Lion'));
    expect(taps, 1);
  });

  testWidgets('pseudo long : pas de débordement', (tester) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Row(
            children: [
              ProfileChip(
                name: 'Chkobba_Champion',
                avatarId: 'cat',
                onTap: () {},
              ),
              const Spacer(),
              const SizedBox(width: 120),
            ],
          ),
        ),
      ),
    );
    expect(tester.takeException(), isNull);
  });
}
