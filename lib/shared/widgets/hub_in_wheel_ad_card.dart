// lib/shared/widgets/hub_in_wheel_ad_card.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:gameflix/l10n/app_strings.dart';
import 'package:gameflix/l10n/strings_shared.dart';
import 'package:gameflix/services/ad_manager.dart';
import 'package:gameflix/shared/widgets/unlock_pack_sheet.dart';

/// Carte publicitaire sponsorisée insérée dans la roue défilante du Hub (5e position).
///
/// Adopte les mêmes dimensions et finitions néon que les cartes de jeu de GameFlix.
/// Si l'annonce AdMob est prête, elle s'affiche au centre.
/// Sinon (hors-ligne ou test), un visuel de remplacement sobre et esthétique est proposé.
class HubInWheelAdCard extends StatefulWidget {
  final double cardRenderHeight;
  final double cardRenderWidth;

  const HubInWheelAdCard({
    super.key,
    required this.cardRenderHeight,
    required this.cardRenderWidth,
  });

  @override
  State<HubInWheelAdCard> createState() => _HubInWheelAdCardState();
}

class _HubInWheelAdCardState extends State<HubInWheelAdCard> {
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
    _loadBanner();
  }

  void _onAdsReadyChanged() {
    if (AdManager.instance.adsReadyNotifier.value) {
      _loadBanner();
    }
  }

  void _loadBanner() {
    if (!mounted || _isLoading || _bannerAd != null) return;
    if (!AdManager.instance.isSupportedPlatform) return;
    if (!AdManager.instance.adsReadyNotifier.value) return;

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
          debugPrint('Échec chargement bannière dans la roue : $error');
          ad.dispose();
          _isLoading = false;
          if (mounted) {
            setState(() {
              _bannerAd = null;
              _isAdLoaded = false;
            });
            if (_retryCount < _maxRetries) {
              _retryCount++;
              _retryTimer?.cancel();
              _retryTimer = Timer(Duration(seconds: 4 * _retryCount), _loadBanner);
            }
          }
        },
      ),
    );

    _bannerAd = banner;
    banner.load();
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
    final strings = AppStrings.of(context);

    return Container(
      key: const Key('hub_in_wheel_ad_card'),
      height: widget.cardRenderHeight,
      width: widget.cardRenderWidth,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: const Color(0xFF0F0E24),
        border: Border.all(
          color: Colors.cyanAccent.withValues(alpha: 0.45),
          width: 1.8,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.cyanAccent.withValues(alpha: 0.25),
            blurRadius: 14,
            spreadRadius: 1,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Stack(
          children: [
            // Fond subtil à motifs
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      const Color(0xFF141332),
                      const Color(0xFF0A091A).withValues(alpha: 0.95),
                    ],
                  ),
                ),
              ),
            ),

            // Contenu central : soit la bannière AdMob, soit le placeholder esthétique
            Center(
              child: _isAdLoaded && _bannerAd != null
                  ? SizedBox(
                      width: _bannerAd!.size.width.toDouble(),
                      height: _bannerAd!.size.height.toDouble(),
                      child: AdWidget(ad: _bannerAd!),
                    )
                  : GestureDetector(
                      onTap: () {
                        UnlockPackSheet.show(
                          context,
                          packId: 'vip_pass',
                          packTitle: strings.vipAdFreePackTitle,
                          onUnlocked: () {},
                        );
                      },
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: Colors.cyanAccent.withValues(alpha: 0.12),
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: Colors.cyanAccent.withValues(alpha: 0.5),
                                width: 1.2,
                              ),
                            ),
                            child: const Icon(
                              Icons.bolt_rounded,
                              color: Colors.cyanAccent,
                              size: 26,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            strings.sponsorSpaceTitle,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w900,
                              fontSize: 14,
                              letterSpacing: 1.5,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            strings.sponsorSpaceSubtitle,
                            style: TextStyle(
                              color: Colors.cyanAccent.withValues(alpha: 0.8),
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
            ),

            // Badge discret "SPONSORISÉ" en haut à droite
            Positioned(
              top: 10,
              right: 12,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.6),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: Colors.cyanAccent.withValues(alpha: 0.3),
                    width: 1,
                  ),
                ),
                child: Text(
                  strings.adBadgeLabel,
                  style: const TextStyle(
                    color: Colors.cyanAccent,
                    fontSize: 9,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.0,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
