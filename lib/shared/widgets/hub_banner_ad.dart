// lib/shared/widgets/hub_banner_ad.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:gameflix/services/ad_manager.dart';
import 'package:gameflix/state/access_control_provider.dart';

/// Widget de bannière publicitaire discrète affichée en bas du Hub principal.
///
/// Si l'utilisateur est abonné VIP ou sous Pass Soirée 1H, aucune annonce n'est chargée ni affichée.
/// Si l'annonce ne charge pas (appareil hors-ligne, plateforme non mobile, etc.),
/// le widget se replie gracieusement sans impacter l'interface ni provoquer d'erreur.
class HubBannerAd extends StatefulWidget {
  const HubBannerAd({super.key});

  @override
  State<HubBannerAd> createState() => _HubBannerAdState();
}

class _HubBannerAdState extends State<HubBannerAd> {
  BannerAd? _bannerAd;
  bool _isAdLoaded = false;

  @override
  void initState() {
    super.initState();
    final access = AccessControlProvider.instance;
    if (!access.isSubscribed && !access.isPass1hActive) {
      _loadBanner();
    }
  }

  void _loadBanner() {
    // 1. Contrôle de compatibilité plateforme / tests / abonnement VIP
    if (!AdManager.instance.isSupportedPlatform) return;
    if (AccessControlProvider.instance.isSubscribed || AccessControlProvider.instance.isPass1hActive) {
      return;
    }

    // 2. Instanciation et chargement de la bannière
    final banner = BannerAd(
      adUnitId: AdManager.instance.bannerAdUnitId,
      size: AdSize.banner,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (ad) {
          if (mounted) {
            setState(() {
              _isAdLoaded = true;
            });
          }
        },
        onAdFailedToLoad: (ad, error) {
          debugPrint('Échec de chargement de la bannière AdMob : $error');
          ad.dispose();
          if (mounted) {
            setState(() {
              _bannerAd = null;
              _isAdLoaded = false;
            });
          }
        },
      ),
    );

    _bannerAd = banner;
    banner.load();
  }

  @override
  void dispose() {
    _bannerAd?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Si l'utilisateur est VIP ou a un pass 1h actif, bannière totalement supprimée
    final access = context.watch<AccessControlProvider>();
    if (access.isSubscribed || access.isPass1hActive) {
      if (_bannerAd != null) {
        _bannerAd?.dispose();
        _bannerAd = null;
        _isAdLoaded = false;
      }
      return const SizedBox.shrink();
    }

    // Si la bannière n'est pas encore prête ou a échoué, repli invisible
    if (!_isAdLoaded || _bannerAd == null) {
      return const SizedBox.shrink();
    }

    return Container(
      width: _bannerAd!.size.width.toDouble(),
      height: _bannerAd!.size.height.toDouble(),
      margin: const EdgeInsets.only(top: 6, bottom: 4),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(6),
      ),
      child: AdWidget(ad: _bannerAd!),
    );
  }
}
