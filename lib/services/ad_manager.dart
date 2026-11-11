// lib/services/ad_manager.dart
import 'dart:async';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:gameflix/config/monetization_config.dart';

// --- SERVICE CENTRALISÉ DE PUBLICITÉS ADMOB & CONSENTEMENT RGPD ---

/// Gestionnaire publicitaire singleton assurant :
/// 1. Le recueil du consentement RGPD via Google UMP (User Messaging Platform).
/// 2. L'initialisation sécurisée de Google Mobile Ads (robuste hors-ligne et en tests).
/// 3. La gestion des bannières hors-jeu.
/// 4. La régulation des interstitiels avec un cooldown strict de 4 minutes.
/// 5. La préparation des publicités récompensées (Rewarded Ads) pour le Pass Soirée 1H.
class AdManager {
  /// Instance singleton
  static final AdManager instance = AdManager._();

  AdManager._();

  bool _isInitialized = false;
  bool _isMobileAdsSdkStarted = false;
  bool _isPrivacyOptionsRequired = false;
  DateTime? _lastInterstitialShownAt;

  /// Notifie les widgets (bannières) dès que le SDK AdMob est initialisé et prêt.
  final ValueNotifier<bool> adsReadyNotifier = ValueNotifier<bool>(false);

  /// Cooldown strict entre deux interstitiels pour ne pas briser la soirée
  Duration cooldownDuration = MonetizationConfig.interstitialCooldown;

  InterstitialAd? _interstitialAd;
  bool _isInterstitialLoading = false;

  RewardedAd? _rewardedAd;
  bool _isRewardedLoading = false;

  // --- GETTERS D'ÉTAT ---

  bool get isInitialized => _isInitialized;
  bool get isMobileAdsSdkStarted => _isMobileAdsSdkStarted;
  bool get isPrivacyOptionsRequired => _isPrivacyOptionsRequired;
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

  // --- IDENTIFIANTS ADMOB (TEST / PROD CONFIGURABLES) ---

  String get bannerAdUnitId => MonetizationConfig.bannerAdUnitId;

  String get interstitialAdUnitId => MonetizationConfig.interstitialAdUnitId;

  String get rewardedAdUnitId => MonetizationConfig.rewardedAdUnitId;

  // --- INITIALISATION DU SDK & CONSENTEMENT RGPD (UMP) ---

  /// Lance le flux de consentement RGPD (UMP), puis initialise le SDK AdMob
  Future<void> init() async {
    if (_isInitialized) return;

    // Fixe le timestamp initial pour éviter un interstitiel direct dès l'ouverture
    _lastInterstitialShownAt ??= DateTime.now();

    if (!isSupportedPlatform) {
      _isInitialized = true;
      return;
    }

    _isInitialized = true;

    try {
      // 1. Si un consentement valide existe déjà d'une session précédente,
      // on initialise immédiatement AdMob en parallèle.
      if (await ConsentInformation.instance.canRequestAds()) {
        await _initializeMobileAdsSdk();
      }

      // 2. Mise à jour du statut de consentement RGPD auprès de Google UMP
      await _gatherConsent();
    } catch (e) {
      debugPrint('Avertissement AdManager.init() (mode hors-ligne ou erreur) : $e');
    }
  }

  Future<void> _gatherConsent() async {
    final completer = Completer<void>();

    ConsentInformation.instance.requestConsentInfoUpdate(
      ConsentRequestParameters(),
      () async {
        try {
          await ConsentForm.loadAndShowConsentFormIfRequired((formError) {
            if (formError != null) {
              debugPrint('Erreur formulaire RGPD UMP : ${formError.message}');
            }
          });
          await _refreshPrivacyOptionsStatus();
          if (await ConsentInformation.instance.canRequestAds()) {
            await _initializeMobileAdsSdk();
          }
        } catch (e) {
          debugPrint('Avertissement affichage formulaire RGPD : $e');
        } finally {
          if (!completer.isCompleted) completer.complete();
        }
      },
      (FormError error) async {
        debugPrint('Avertissement mise à jour RGPD UMP : ${error.message}');
        await _refreshPrivacyOptionsStatus();
        try {
          if (await ConsentInformation.instance.canRequestAds()) {
            await _initializeMobileAdsSdk();
          }
        } catch (e) {
          debugPrint('Avertissement reprise initialisation AdMob : $e');
        }
        if (!completer.isCompleted) completer.complete();
      },
    );

    await completer.future;
  }

  Future<void> _initializeMobileAdsSdk() async {
    if (_isMobileAdsSdkStarted) return;
    _isMobileAdsSdkStarted = true;
    await MobileAds.instance.initialize();
    adsReadyNotifier.value = true;
    preloadInterstitial();
    preloadRewarded();
  }

  Future<void> _refreshPrivacyOptionsStatus() async {
    try {
      final status = await ConsentInformation.instance.getPrivacyOptionsRequirementStatus();
      _isPrivacyOptionsRequired = status == PrivacyOptionsRequirementStatus.required;
    } catch (e) {
      debugPrint('Avertissement statut options RGPD : $e');
    }
  }

  /// Permet à l'utilisateur de rouvrir le formulaire de préférences RGPD (obligatoire en UE)
  Future<void> showPrivacyOptionsForm({VoidCallback? onCompleted}) async {
    if (!isSupportedPlatform) {
      onCompleted?.call();
      return;
    }

    await ConsentForm.showPrivacyOptionsForm((formError) {
      if (formError != null) {
        debugPrint('Erreur options de confidentialité RGPD : ${formError.message}');
      }
      _refreshPrivacyOptionsStatus();
      onCompleted?.call();
    });
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

  /// Affiche l'interstitiel uniquement si le cooldown de 4 minutes est écoulé
  /// et si l'utilisateur n'est pas VIP ou sous Pass Soirée 1H actif.
  /// Retourne [true] si la publicité a été affichée, [false] sinon.
  bool showInterstitialIfAllowed({DateTime? now, bool isVipOrPassActive = false}) {
    // 0. Si l'utilisateur est VIP ou a un pass 1h actif, pas de pub interstitielle
    if (isVipOrPassActive) {
      debugPrint('AdManager : Interstitiel ignoré (utilisateur VIP ou Pass 1H actif)');
      return false;
    }

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
