import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kahwetne/features/chkobba/chkobba_screen.dart';
import 'package:kahwetne/features/menu/menu_models.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Diagnostic temporaire (#204) : affiche le widget fautif du débordement Chkobba.
void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets('diagnostic débordement Chkobba', (tester) async {
    tester.view.physicalSize = const Size(390, 844) * 3;
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final errors = <FlutterErrorDetails>[];
    final previous = FlutterError.onError;
    FlutterError.onError = errors.add;
    await tester.pumpWidget(
      const MaterialApp(
        home: ChkobbaScreen(difficulty: Difficulty.facile, targetScore: 11),
      ),
    );
    await tester.pump(const Duration(seconds: 1));
    FlutterError.onError = previous;
    for (final e in errors) {
      debugPrint('DIAG_BEGIN ${e.exceptionAsString()}');
      final collector = e.informationCollector;
      for (final node in collector?.call() ?? <DiagnosticsNode>[]) {
        debugPrint('DIAG ${node.toStringDeep()}');
      }
      debugPrint('DIAG_END');
    }
    await tester.pumpWidget(const SizedBox());
    await tester.pump();
  });
}
