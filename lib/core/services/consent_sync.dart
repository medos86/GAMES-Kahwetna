import 'dart:async';

import 'package:app_tracking_transparency_plus/app_tracking_transparency_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import 'ad_consent.dart';

/// Pont vers le SDK UMP (message de consentement RGPD de Google) (issue #466).
///
/// Interface pour que la logique reste testable sans SDK natif.
abstract interface class UmpGateway {
  /// Met à jour les informations de consentement (à chaque lancement).
  Future<void> requestUpdate();

  /// Affiche le message RGPD seulement si le SDK l'exige.
  Future<void> loadAndShowFormIfRequired();

  /// `true` si les pubs peuvent être demandées (personnalisées ou non).
  Future<bool> canRequestAds();
}

/// Implémentation réelle : SDK UMP intégré à `google_mobile_ads`.
// coverage:ignore-start
class GoogleUmpGateway implements UmpGateway {
  const GoogleUmpGateway();

  @override
  Future<void> requestUpdate() {
    final completer = Completer<void>();
    ConsentInformation.instance.requestConsentInfoUpdate(
      ConsentRequestParameters(),
      () => completer.complete(),
      (FormError error) => completer.completeError(error),
    );
    return completer.future;
  }

  @override
  Future<void> loadAndShowFormIfRequired() {
    final completer = Completer<void>();
    ConsentForm.loadAndShowConsentFormIfRequired((FormError? error) {
      if (error == null) {
        completer.complete();
      } else {
        completer.completeError(error);
      }
    });
    return completer.future;
  }

  @override
  Future<bool> canRequestAds() => ConsentInformation.instance.canRequestAds();
}
// coverage:ignore-end

/// Autorisation de suivi iOS (ATT) (issue #466).
abstract interface class TrackingAuthorizer {
  /// `true` si le suivi est autorisé, ou si la question ne se pose pas (Android).
  Future<bool> requestAuthorization();
}

/// Choisit la bonne demande selon la plateforme.
class PlatformTrackingAuthorizer implements TrackingAuthorizer {
  PlatformTrackingAuthorizer({
    bool Function()? isIos,
    Future<bool> Function()? ask,
  })  : _isIos = isIos ?? _defaultIsIos,
        _ask = ask ?? _askIos;

  final bool Function() _isIos;
  final Future<bool> Function() _ask;

  static bool _defaultIsIos() => defaultTargetPlatform == TargetPlatform.iOS;

  // coverage:ignore-start
  static Future<bool> _askIos() async {
    final status =
        await AppTrackingTransparencyPlus.requestTrackingAuthorization();
    return status == TrackingStatus.authorized;
  }
  // coverage:ignore-end

  @override
  Future<bool> requestAuthorization() async {
    if (!_isIos()) return true;
    return _ask();
  }
}

/// Enchaîne le consentement : UMP d'abord (message RGPD), puis ATT iOS.
///
/// - Erreur UMP : l'état précédent est conservé, rien n'est demandé.
/// - UMP ne permet pas les pubs : refus, l'alerte ATT n'est pas montrée.
/// - Sinon : ATT. Accord = pubs personnalisées, refus = non personnalisées.
Future<void> syncConsent({
  required ConsentService consent,
  required UmpGateway ump,
  required TrackingAuthorizer tracking,
}) async {
  await consent.load();
  try {
    await ump.requestUpdate();
    await ump.loadAndShowFormIfRequired();
    if (!await ump.canRequestAds()) {
      await consent.deny();
      return;
    }
  } catch (_) {
    return;
  }
  final allowed = await tracking.requestAuthorization();
  if (allowed) {
    await consent.grant();
  } else {
    await consent.deny();
  }
}
