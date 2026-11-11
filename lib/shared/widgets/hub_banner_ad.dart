// lib/shared/widgets/hub_banner_ad.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:gameflix/services/ad_manager.dart';
import 'package:gameflix/state/access_control_provider.dart';

/// Widget de bannière publicitaire discrète affichée en bas du Hub principal.
///
/// Si l'utilisateur est abonné VIP ou sous Pass Soirée 1H, aucune annonce n'est chargée ni affichée.
/// Attend que le SDK AdMob soit prêt (après consentement UMP) et réessaie en cas d'échec temporaire.
class HubBannerAd extends StatefulWidget {
  const HubBannerAd({super.key});

  @override
  State<HubBannerAd> createState() => _HubBannerAdState();
}

class _HubBannerAdState extends State<HubBannerAd> {
  static const int _maxRetries = 3;

  BannerAd? _bannerAd;
  bool _isAdLoaded = false;
  bool _isLoading = false;
  int _retryCount = 0;
  Timer? _retryTimer;

  @override
  void initState() {
    super.initState();
    AdManager.instance.adsReadyNotifier.addListener(_onAdsReadyChanged);
    _loadBannerIfEligible();
  }

  void _onAdsReadyChanged() {
    if (AdManager.instance.adsReadyNotifier.value) {
      _loadBannerIfEligible();
    }
  }

  void _loadBannerIfEligible() {
    if (!mounted || _isLoading || _bannerAd != null) return;
    if (!AdManager.instance.isSupportedPlatform) return;
    if (!AdManager.instance.adsReadyNotifier.value) return;
    final access = AccessControlProvider.instance;
    if (access.isSubscribed || access.isPass1hActive) return;

    _isLoading = true;
    final banner = BannerAd(
      adUnitId: AdManager.instance.bannerAdUnitId,
      size: AdSize.banner,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (ad) {
          _isLoading = false;
          _retryCount = 0;
          if (mounted) {
            setState(() {
              _isAdLoaded = true;
            });
          } else {
            ad.dispose();
          }
        },
        onAdFailedToLoad: (ad, error) {
          debugPrint('Échec de chargement de la bannière AdMob : $error');
          ad.dispose();
          _isLoading = false;
          if (mounted) {
            setState(() {
              _bannerAd = null;
              _isAdLoaded = false;
            });
            _scheduleRetry();
          }
        },
      ),
    );

    _bannerAd = banner;
    banner.load();
  }

  void _scheduleRetry() {
    if (_retryCount >= _maxRetries) return;
    _retryCount++;
    _retryTimer?.cancel();
    _retryTimer = Timer(Duration(seconds: 4 * _retryCount), _loadBannerIfEligible);
  }

  @override
  void dispose() {
    AdManager.instance.adsReadyNotifier.removeListener(_onAdsReadyChanged);
    _retryTimer?.cancel();
    _bannerAd?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Si l'utilisateur est VIP ou a un pass 1h actif, bannière totalement supprimée
    final access = context.watch<AccessControlProvider>();
    if (access.isSubscribed || access.isPass1hActive) {
      _retryTimer?.cancel();
      _retryCount = 0;
      if (_bannerAd != null) {
        _bannerAd?.dispose();
        _bannerAd = null;
        _isAdLoaded = false;
        _isLoading = false;
      }
      return const SizedBox.shrink();
    }

    // Si le Pass 1H vient d'expirer et qu'aucune bannière n'est chargée, on relance le chargement
    if (_bannerAd == null && !_isLoading && _retryCount == 0) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _loadBannerIfEligible());
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
