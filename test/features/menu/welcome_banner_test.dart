import 'package:flutter_test/flutter_test.dart';
import 'package:kahwetne/features/menu/welcome_banner.dart';
import 'package:material_ui/material_ui.dart';

/// Issue #544 : le bandeau affiche le pseudo et « Modifier » ouvre les réglages.
void main() {
  testWidgets('affiche le pseudo et appelle onEdit au tap', (tester) async {
    var edited = false;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: WelcomeBanner(
            name: 'Sfaxi_Lion',
            onEdit: () => edited = true,
          ),
        ),
      ),
    );
    expect(find.textContaining('Sfaxi_Lion'), findsOneWidget);
    await tester.tap(find.byType(TextButton));
    expect(edited, isTrue);
  });
}
