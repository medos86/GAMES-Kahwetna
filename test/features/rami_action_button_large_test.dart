import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kahwetne/features/rami/rami_action_button.dart';

void main() {
  testWidgets('bouton d\'action dans une cible de 48 dp (#522)', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 200,
            child: SizedBox(
              height: 48,
              child: RamiActionButton(
                label: 'Annuler',
                icon: Icons.close,
                onTap: () {},
              ),
            ),
          ),
        ),
      ),
    );
    expect(
      tester.getSize(find.byType(RamiActionButton)).height,
      48,
    );
  });
}
