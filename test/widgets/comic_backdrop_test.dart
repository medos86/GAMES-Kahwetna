import 'package:flutter_test/flutter_test.dart';
import 'package:kahwetne/widgets/comic/comic_backdrop.dart';
import 'package:kahwetne/widgets/comic/halftone_overlay.dart';
import 'package:material_ui/material_ui.dart';

/// Issue #636 : le fond de page BD affiche son contenu au-dessus de la trame.
void main() {
  testWidgets('affiche le contenu avec la trame dessous', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: ComicBackdrop(child: Text('contenu')),
      ),
    );
    expect(find.text('contenu'), findsOneWidget);
    final paint = tester.widget<CustomPaint>(find.byType(CustomPaint).first);
    expect(paint.painter, isA<HalftonePainter>());
  });
}
