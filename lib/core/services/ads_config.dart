/// App IDs AdMob (issue #465). Ce ne sont pas des secrets : AdMob les intègre dans l'app.
///
/// Ils doivent aussi figurer dans le projet natif :
/// - Android : `android/app/src/main/AndroidManifest.xml`, balise `<meta-data>`
///   `com.google.android.gms.ads.APPLICATION_ID` avec [android].
/// - iOS : `ios/Runner/Info.plist`, clé `GADApplicationIdentifier` avec [ios].
class AdAppIds {
  const AdAppIds._();

  static const String android = 'ca-app-pub-8112474614416750~9878567353';
  static const String ios = 'ca-app-pub-8112474614416750~9360913792';
}
