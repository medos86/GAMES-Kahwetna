import 'dart:async';

import 'package:google_mobile_ads/google_mobile_ads.dart';

/// Rouvre le formulaire UMP « options de confidentialité » (issue #570).
///
/// Appelé depuis le dialogue Confidentialité du menu. Le future se termine
/// quand le formulaire est fermé ; l'appelant ne doit pas bloquer dessus.
// coverage:ignore-start
Future<void> showUmpPrivacyOptions() {
  final completer = Completer<void>();
  ConsentForm.showPrivacyOptionsForm((FormError? error) {
    if (error == null) {
      completer.complete();
    } else {
      completer.completeError(error);
    }
  });
  return completer.future;
}
// coverage:ignore-end
