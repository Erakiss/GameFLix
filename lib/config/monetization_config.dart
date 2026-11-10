// lib/config/monetization_config.dart
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart';

/// Configuration centralisée de la monétisation pour GameFlix :
/// - Identifiants AdMob (IDs de test officiels de Google + placeholders de production)
/// - Clés publiques SDK RevenueCat (Android et iOS)
/// - Durées et temporisations (cooldowns d'interstitiels, Pass Soirée 1H)
/// - Empreinte cryptographique SHA-256 des codes promo
class MonetizationConfig {
  MonetizationConfig._();

  // ===========================================================================
  // 1. REVENUECAT (ACHATS IN-APP & ABONNEMENTS)
  // ===========================================================================

  /// Clé API publique RevenueCat pour Android (remplacez par votre clé de production commençant par goog_)
  static const String revenueCatAndroidApiKey = 'goog_sample_gameflix_revcat_key';

  /// Clé API publique RevenueCat pour iOS (remplacez par votre clé de production commençant par appl_)
  static const String revenueCatIosApiKey = 'appl_sample_gameflix_revcat_key';

  /// Identifiant d'entitlement configuré dans le dashboard RevenueCat
  static const String premiumEntitlementId = 'premium';

  /// Identifiants standard des packages de l'offre RevenueCat
  static const String weeklyPackageIdentifier = r'$rc_weekly';
  static const String annualPackageIdentifier = r'$rc_annual';

  /// Tarifs de référence affichés en mode hors-ligne / test
  static const String fallbackWeeklyPrice = '2,99 €';
  static const String fallbackAnnualPrice = '45,00 €';

  /// Retourne la clé API RevenueCat adaptée à la plateforme courante
  static String get revenueCatApiKey {
    if (kIsWeb) return '';
    if (Platform.isAndroid) return revenueCatAndroidApiKey;
    if (Platform.isIOS) return revenueCatIosApiKey;
    return '';
  }

  // ===========================================================================
  // 2. GOOGLE ADMOB (IDENTIFIANTS D'ANNONCES)
  // Remplacez les constantes de production ci-dessous lors du déploiement Store.
  // ===========================================================================

  // --- IDs Officiels de test Google AdMob ---
  static const String testBannerAndroid = 'ca-app-pub-3940256099942544/6300978111';
  static const String testBannerIos = 'ca-app-pub-3940256099942544/2934735716';

  static const String testInterstitialAndroid = 'ca-app-pub-3940256099942544/1033173712';
  static const String testInterstitialIos = 'ca-app-pub-3940256099942544/4411468910';

  static const String testRewardedAndroid = 'ca-app-pub-3940256099942544/5224354917';
  static const String testRewardedIos = 'ca-app-pub-3940256099942544/1712485313';

  // --- Mode Production (passez à true ou utilisez --dart-define=IS_PROD=true) ---
  static const bool isProductionAds = bool.fromEnvironment('IS_PROD', defaultValue: false);

  // --- IDs Production (Placeholders prêts à accueillir vos vrais blocs d'annonces) ---
  static const String prodBannerAndroid = 'ca-app-pub-XXXXXXXXXXXXXXXX/YYYYYYYYYY';
  static const String prodBannerIos = 'ca-app-pub-XXXXXXXXXXXXXXXX/YYYYYYYYYY';

  static const String prodInterstitialAndroid = 'ca-app-pub-XXXXXXXXXXXXXXXX/YYYYYYYYYY';
  static const String prodInterstitialIos = 'ca-app-pub-XXXXXXXXXXXXXXXX/YYYYYYYYYY';

  static const String prodRewardedAndroid = 'ca-app-pub-XXXXXXXXXXXXXXXX/YYYYYYYYYY';
  static const String prodRewardedIos = 'ca-app-pub-XXXXXXXXXXXXXXXX/YYYYYYYYYY';

  /// Ad Unit ID pour la bannière
  static String get bannerAdUnitId {
    if (kIsWeb) return '';
    if (Platform.isAndroid) {
      return isProductionAds ? prodBannerAndroid : testBannerAndroid;
    } else if (Platform.isIOS) {
      return isProductionAds ? prodBannerIos : testBannerIos;
    }
    return '';
  }

  /// Ad Unit ID pour l'interstitiel
  static String get interstitialAdUnitId {
    if (kIsWeb) return '';
    if (Platform.isAndroid) {
      return isProductionAds ? prodInterstitialAndroid : testInterstitialAndroid;
    } else if (Platform.isIOS) {
      return isProductionAds ? prodInterstitialIos : testInterstitialIos;
    }
    return '';
  }

  /// Ad Unit ID pour la vidéo récompensée (Rewarded)
  static String get rewardedAdUnitId {
    if (kIsWeb) return '';
    if (Platform.isAndroid) {
      return isProductionAds ? prodRewardedAndroid : testRewardedAndroid;
    } else if (Platform.isIOS) {
      return isProductionAds ? prodRewardedIos : testRewardedIos;
    }
    return '';
  }

  // ===========================================================================
  // 3. RÈGLES & TIMINGS DE MONÉTISATION
  // ===========================================================================

  /// Cooldown strict de 4 minutes entre deux interstitiels
  static const Duration interstitialCooldown = Duration(minutes: 4);

  /// Durée du pass temporaire récompensé (Pass Soirée 1H)
  static const Duration pass1hDuration = Duration(hours: 1);

  // ===========================================================================
  // 4. SÉCURITÉ CRYPTOGRAPHIQUE DES CODES PROMO
  // SHA-256 de 'erakisslebon' : 788384b0e3c33b57684087d5e0e0494ffcb4a127a0067efebc00a4be8d4755e1
  // ===========================================================================

  /// Empreinte SHA-256 du code promo VIP permanent
  static const String promoCodeSha256 =
      '788384b0e3c33b57684087d5e0e0494ffcb4a127a0067efebc00a4be8d4755e1';
}
