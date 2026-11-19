import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:material_ui/material_ui.dart';

import '../core/services/ad_request_policy.dart';
import '../core/services/ads_service.dart';

/// Hauteur fixe de la bannière : la table ne bouge jamais (issue #469).
const double kAdBannerHeight = 56;

/// Vraie bannière AdMob (issue #469).
///
/// Tant que la pub n'est pas chargée, ou si elle échoue, la zone reste vide à hauteur fixe :
/// aucune fausse publicité n'est affichée, et le jeu n'est jamais bloqué.
class AdBanner extends StatefulWidget {
  const AdBanner({super.key});

  @override
  State<AdBanner> createState() => _AdBannerState();
}

class _AdBannerState extends State<AdBanner> {
  BannerAd? _ad;
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final ad = BannerAd(
        adUnitId: AdUnitIds.banner(defaultTargetPlatform),
        size: AdSize.banner,
        request: currentAdRequest(),
        listener: BannerAdListener(
          onAdLoaded: (_) {
            if (mounted) setState(() => _loaded = true);
          },
          onAdFailedToLoad: (failed, _) => failed.dispose(),
        ),
      );
      _ad = ad;
      await ad.load();
    } catch (_) {
      // La pub est optionnelle : une erreur ici ne doit jamais bloquer le jeu.
    }
  }

  @override
  void dispose() {
    _ad?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ad = _ad;
    return SizedBox(
      height: kAdBannerHeight,
      width: double.infinity,
      child: _loaded && ad != null
          ? Center(
              child: SizedBox(
                width: ad.size.width.toDouble(),
                height: ad.size.height.toDouble(),
                child: AdWidget(ad: ad),
              ),
            )
          : const SizedBox.shrink(),
    );
  }
}
