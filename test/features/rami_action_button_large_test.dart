import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kahwetne/features/rami/rami_action_button.dart';

void main() {
  testWidgets('bouton dans une cible de 48 dp (#522)', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            height: 48,
            child: RamiActionButton(
              label: 'Annuler',
              icon: Icons.close,
              onTap: () {},
            ),
          ),
        ),
      ),
    );
    final size = tester.getSize(find.byType(RamiActionButton));
    expect(size.height, 48);
  });
}
