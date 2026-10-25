// lib/services/ad_manager.dart
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

// --- SERVICE CENTRALISÉ DE PUBLICITÉS ADMOB ---

/// Gestionnaire publicitaire singleton assurant :
/// 1. L'initialisation sécurisée de Google Mobile Ads (robuste hors-ligne et en tests).
/// 2. La gestion des bannières hors-jeu.
/// 3. La régulation des interstitiels avec un cooldown strict de 4 minutes.
/// 4. La préparation des publicités récompensées (Rewarded Ads) pour les futurs déblocages.
class AdManager {
  /// Instance singleton
  static final AdManager instance = AdManager._();

  AdManager._();

  bool _isInitialized = false;
  DateTime? _lastInterstitialShownAt;

  /// Cooldown strict de 4 minutes entre deux interstitiels pour ne pas briser la soirée
  Duration cooldownDuration = const Duration(minutes: 4);

  InterstitialAd? _interstitialAd;
  bool _isInterstitialLoading = false;

  RewardedAd? _rewardedAd;
  bool _isRewardedLoading = false;

  // --- GETTERS D'ÉTAT ---

  bool get isInitialized => _isInitialized;
  DateTime? get lastInterstitialShownAt => _lastInterstitialShownAt;
  bool get isInterstitialReady => _interstitialAd != null;
  bool get isRewardedReady => _rewardedAd != null;

  /// Vérifie si l'environnement supporte nativement les annonces Google Mobile Ads
  bool get isSupportedPlatform {
    if (kIsWeb) return false;
    if (Platform.environment.containsKey('FLUTTER_TEST')) return false;
    return Platform.isAndroid || Platform.isIOS;
  }

  /// Indique si un interstitiel a le droit d'être affiché selon le cooldown
  bool canShowInterstitial({DateTime? now}) {
    if (_lastInterstitialShownAt == null) return true;
    final current = now ?? DateTime.now();
    return current.difference(_lastInterstitialShownAt!) >= cooldownDuration;
  }

  // --- IDENTIFIANTS OFFICIELS DE TEST ADMOB ---

  String get bannerAdUnitId {
    if (Platform.isAndroid) {
      return 'ca-app-pub-3940256099942544/6300978111';
    } else if (Platform.isIOS) {
      return 'ca-app-pub-3940256099942544/2934735716';
    }
    return '';
  }

  String get interstitialAdUnitId {
    if (Platform.isAndroid) {
      return 'ca-app-pub-3940256099942544/1033173712';
    } else if (Platform.isIOS) {
      return 'ca-app-pub-3940256099942544/4411468910';
    }
    return '';
  }

  String get rewardedAdUnitId {
    if (Platform.isAndroid) {
      return 'ca-app-pub-3940256099942544/5224354917';
    } else if (Platform.isIOS) {
      return 'ca-app-pub-3940256099942544/1712485313';
    }
    return '';
  }

  // --- INITIALISATION DU SDK ---

  /// Initialise le SDK AdMob et précharge le premier interstitiel
  Future<void> init() async {
    if (_isInitialized) return;

    // Fixe le timestamp initial pour éviter un interstitiel direct dès l'ouverture
    _lastInterstitialShownAt ??= DateTime.now();

    if (!isSupportedPlatform) {
      _isInitialized = true;
      return;
    }

    try {
      // 1. Initialisation asynchrone du SDK Google Mobile Ads
      await MobileAds.instance.initialize();
      _isInitialized = true;

      // 2. Préchargement en tâche de fond des annonces
      preloadInterstitial();
      preloadRewarded();
    } catch (e) {
      debugPrint('Avertissement AdManager.init() (mode hors-ligne ou erreur) : $e');
      _isInitialized = true;
    }
  }

  // --- GESTION DES INTERSTITIELS (TIMÉS AVEC COOLDOWN) ---

  /// Précharge un interstitiel en mémoire
  void preloadInterstitial() {
    if (!isSupportedPlatform || _interstitialAd != null || _isInterstitialLoading) {
      return;
    }

    _isInterstitialLoading = true;
    InterstitialAd.load(
      adUnitId: interstitialAdUnitId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          _interstitialAd = ad;
          _isInterstitialLoading = false;
        },
        onAdFailedToLoad: (error) {
          debugPrint('Échec de préchargement de l\'interstitiel : $error');
          _interstitialAd = null;
          _isInterstitialLoading = false;
        },
      ),
    );
  }

  /// Affiche l'interstitiel uniquement si le cooldown de 4 minutes est écoulé.
  /// Retourne [true] si la publicité a été affichée, [false] sinon.
  bool showInterstitialIfAllowed({DateTime? now}) {
    // 1. Contrôle strict du cooldown de 4 minutes
    if (!canShowInterstitial(now: now)) {
      debugPrint('AdManager : Interstitiel ignoré (cooldown de 4 min non écoulé)');
      return false;
    }

    // 2. Vérification de la disponibilité de l'annonce
    if (_interstitialAd == null) {
      debugPrint('AdManager : Aucun interstitiel prêt (hors-ligne ou non chargé)');
      preloadInterstitial();
      return false;
    }

    // 3. Configuration des callbacks de cycle de vie
    final adToShow = _interstitialAd!;
    _interstitialAd = null;

    adToShow.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (ad) {
        ad.dispose();
        preloadInterstitial();
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        debugPrint('Erreur lors de l\'affichage de l\'interstitiel : $error');
        ad.dispose();
        preloadInterstitial();
      },
    );

    // 4. Affichage et mise à jour de l'horodatage
    adToShow.show();
    _lastInterstitialShownAt = now ?? DateTime.now();
    return true;
  }

  // --- GESTION DES REWARDED ADS (DÉBLOCAGE TEMPORAIRE) ---

  /// Précharge une publicité récompensée
  void preloadRewarded() {
    if (!isSupportedPlatform || _rewardedAd != null || _isRewardedLoading) {
      return;
    }

    _isRewardedLoading = true;
    RewardedAd.load(
      adUnitId: rewardedAdUnitId,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) {
          _rewardedAd = ad;
          _isRewardedLoading = false;
        },
        onAdFailedToLoad: (error) {
          debugPrint('Échec de chargement Rewarded Ad : $error');
          _rewardedAd = null;
          _isRewardedLoading = false;
        },
      ),
    );
  }

  /// Affiche une vidéo récompensée et exécute le callback [onUserEarnedReward] si terminée.
  void showRewardedAd({
    required VoidCallback onUserEarnedReward,
    VoidCallback? onAdClosed,
    VoidCallback? onAdFailed,
  }) {
    if (_rewardedAd == null) {
      debugPrint('AdManager : Rewarded Ad non disponible');
      onAdFailed?.call();
      preloadRewarded();
      return;
    }

    final adToShow = _rewardedAd!;
    _rewardedAd = null;

    adToShow.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (ad) {
        ad.dispose();
        onAdClosed?.call();
        preloadRewarded();
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        debugPrint('Erreur affichage Rewarded Ad : $error');
        ad.dispose();
        onAdFailed?.call();
        preloadRewarded();
      },
    );

    adToShow.show(
      onUserEarnedReward: (AdWithoutView ad, RewardItem reward) {
        onUserEarnedReward();
      },
    );
  }

  // --- MÉTHODES UTILITAIRES POUR LES TESTS ---

  /// Permet de réinitialiser le cooldown ou forcer une date dans les tests
  @visibleForTesting
  void setLastInterstitialShownAtForTest(DateTime? time) {
    _lastInterstitialShownAt = time;
  }
}
