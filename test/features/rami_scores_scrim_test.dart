import 'package:flutter_test/flutter_test.dart';
import 'package:kahwetne/features/rami/rami_scores_overlay.dart';
import 'package:material_ui/material_ui.dart';

void main() {
  testWidgets('#591 : le voile s\'estompe à l\'ouverture', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: RamiScoresScrim(open: true, onTap: _noop)),
      ),
    );
    await tester.pump();
    final fade = tester.widget<AnimatedOpacity>(find.byType(AnimatedOpacity));
    expect(fade.opacity, 1);
    expect(fade.duration, const Duration(milliseconds: 220));
  });

  testWidgets('#591 : voile fermé ignoré par les gestes', (tester) async {
    var taps = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: RamiScoresScrim(open: false, onTap: () => taps++),
        ),
      ),
    );
    await tester.tap(find.byType(RamiScoresScrim), warnIfMissed: false);
    expect(taps, 0);
  });

  testWidgets('#591 : voile ouvert, un tap le referme', (tester) async {
    var taps = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: RamiScoresScrim(open: true, onTap: () => taps++),
        ),
      ),
    );
    await tester.tap(find.byType(RamiScoresScrim));
    await tester.pump();
    expect(taps, 1);
  });
}

void _noop() {}
