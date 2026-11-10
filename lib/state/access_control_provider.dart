// lib/state/access_control_provider.dart
import 'dart:convert' show utf8;
import 'dart:io' show Platform;
import 'package:crypto/crypto.dart' show sha256;
import 'package:flutter/foundation.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:gameflix/config/monetization_config.dart';

// --- GESTIONNAIRE D'ACCÈS ET D'ABONNEMENTS (REVENUECAT & ADS) ---

/// Provider centralisant les droits d'accès aux packs de contenu :
/// 1. Gestion de l'abonnement RevenueCat (accès permanent et illimité).
/// 2. Gestion des déblocages temporaires via Rewarded Ad (valable pour la session de jeu active).
/// 3. Réinitialisation automatique des déblocages temporaires lors du retour au Hub.
/// 4. Déblocage permanent par code cadeau (ex: 'ErakissLeBon').
class AccessControlProvider extends ChangeNotifier {
  static const String _promoCodePrefsKey = 'promo_code_pro_unlocked';
  static const String _pass1hExpiresAtKey = 'pass_1h_expires_at';
  static const String _hasUsedOneHourTrialKey = 'has_used_one_hour_trial';

  /// Instance singleton pour accès direct hors BuildContext (ex: goToHub)
  static final AccessControlProvider instance = AccessControlProvider._();

  AccessControlProvider._();

  bool _isInitialized = false;
  bool _isSubscribed = false;
  bool _isPromoUnlocked = false;
  DateTime? _pass1hExpiresAt;
  bool _hasUsedOneHourTrial = false;

  Package? _weeklyPackage;
  Package? _annualPackage;
  String _weeklyPrice = MonetizationConfig.fallbackWeeklyPrice;
  String _annualPrice = MonetizationConfig.fallbackAnnualPrice;

  /// Ensemble des identifiants de packs débloqués temporairement pour la session en cours
  final Set<String> _temporarilyUnlockedPacks = {};

  // --- GETTERS D'ÉTAT ---

  bool get isInitialized => _isInitialized;
  bool get isSubscribed => _isSubscribed || _isPromoUnlocked;
  bool get isPromoUnlocked => _isPromoUnlocked;
  bool get hasUsedOneHourTrial => _hasUsedOneHourTrial;
  DateTime? get pass1hExpiresAt => _pass1hExpiresAt;

  String get weeklyPrice => _weeklyPrice;
  String get annualPrice => _annualPrice;
  Package? get weeklyPackage => _weeklyPackage;
  Package? get annualPackage => _annualPackage;

  /// Indique si le Pass Soirée 1H est actuellement en cours de validité
  bool get isPass1hActive {
    if (_pass1hExpiresAt == null) return false;
    return DateTime.now().isBefore(_pass1hExpiresAt!);
  }

  /// Temps restant sur le Pass 1H (ou Duration.zero si expiré/inactif)
  Duration get pass1hRemainingTime {
    if (!isPass1hActive) return Duration.zero;
    return _pass1hExpiresAt!.difference(DateTime.now());
  }

  Set<String> get temporarilyUnlockedPacks => Set.unmodifiable(_temporarilyUnlockedPacks);

  /// Vérifie si la plateforme actuelle supporte RevenueCat
  bool get isSupportedPlatform {
    if (kIsWeb) return false;
    if (Platform.environment.containsKey('FLUTTER_TEST')) return false;
    return Platform.isAndroid || Platform.isIOS;
  }

  // --- INITIALISATION REVENUECAT & PROMO CODES ---

  /// Initialise le SDK RevenueCat, charge l'éventuel déblocage par code cadeau et l'état du Pass 1H
  Future<void> init({String? apiKey}) async {
    if (_isInitialized) return;

    try {
      final prefs = await SharedPreferences.getInstance();
      _isPromoUnlocked = prefs.getBool(_promoCodePrefsKey) ?? false;
      _hasUsedOneHourTrial = prefs.getBool(_hasUsedOneHourTrialKey) ?? false;
      final expiryStr = prefs.getString(_pass1hExpiresAtKey);
      if (expiryStr != null) {
        final parsed = DateTime.tryParse(expiryStr);
        if (parsed != null && parsed.isAfter(DateTime.now())) {
          _pass1hExpiresAt = parsed;
        }
      }
    } catch (e) {
      debugPrint('Avertissement chargement préférences monétisation : $e');
    }

    if (!isSupportedPlatform) {
      _isInitialized = true;
      notifyListeners();
      return;
    }

    try {
      // 1. Clé API RevenueCat par défaut ou fournie
      final key = apiKey ?? MonetizationConfig.revenueCatApiKey;

      // 2. Configuration du SDK
      final configuration = PurchasesConfiguration(key);
      await Purchases.configure(configuration);

      // 3. Écoute des mises à jour d'abonnement en temps réel
      Purchases.addCustomerInfoUpdateListener((customerInfo) {
        _updateSubscriptionStatus(customerInfo);
      });

      // 4. Récupération du statut d'abonnement actuel
      final customerInfo = await Purchases.getCustomerInfo();
      _updateSubscriptionStatus(customerInfo);

      // 5. Chargement des offres (packages hebdomadaire et annuel)
      await fetchOfferings();

      _isInitialized = true;
    } catch (e) {
      debugPrint('Avertissement AccessControlProvider.init() (hors-ligne ou test) : $e');
      _isInitialized = true;
    }

    notifyListeners();
  }

  void _updateSubscriptionStatus(CustomerInfo customerInfo) {
    // Vérifie si l'utilisateur possède l'entitlement 'premium' ou un abonnement actif
    final hasPremium = customerInfo.entitlements.all[MonetizationConfig.premiumEntitlementId]?.isActive ?? false;
    final hasActiveSub = customerInfo.activeSubscriptions.isNotEmpty;
    _isSubscribed = hasPremium || hasActiveSub;
    notifyListeners();
  }

  // --- GESTION DU CODE CADEAU / PROMO ---

  /// Valide et applique un code cadeau sécurisé par hachage SHA-256.
  /// Le code valide (insensible à la casse/espaces) débloque le mode Pro pour toujours.
  Future<bool> redeemPromoCode(String rawCode) async {
    final code = rawCode.trim().toLowerCase();
    if (code.isEmpty) return false;

    final hash = sha256.convert(utf8.encode(code)).toString();
    if (hash == MonetizationConfig.promoCodeSha256) {
      _isPromoUnlocked = true;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_promoCodePrefsKey, true);
      notifyListeners();
      return true;
    }
    return false;
  }

  // --- VÉRIFICATION DES DROITS D'ACCÈS ---

  /// Vérifie si l'utilisateur peut accéder au pack spécifié :
  /// - Gratuit (non premium) : toujours accessible
  /// - Abonné VIP ou Pass 1H actif : accès illimité à tous les packs
  /// - Débloqué temporairement via Rewarded Ad : accessible pour la partie
  bool canAccess(String packId, {bool isPremium = false}) {
    // 1. Les packs gratuits sont toujours accessibles
    if (!isPremium) return true;

    // 2. Les abonnés VIP, détenteurs du code cadeau ou détenteurs du Pass 1H ont accès à tout
    if (isSubscribed || isPass1hActive) return true;

    // 3. Vérification du déblocage temporaire pour la session
    return _temporarilyUnlockedPacks.contains(packId);
  }

  /// Indique si un pack précis a été débloqué temporairement
  bool isTemporarilyUnlocked(String packId) {
    return _temporarilyUnlockedPacks.contains(packId);
  }

  // --- GESTION DU PASS SOIRÉE 1H (ESSAI RÉCOMPENSÉ UNIQUE PAR APPAREIL) ---

  /// Active le Pass Soirée 1H suite au visionnage complet d'une publicité récompensée.
  /// Règle d'unicité : ne peut être activé qu'une seule et unique fois par appareil à vie.
  /// Retourne [true] si le pass a été activé avec succès, [false] si l'essai a déjà été consommé.
  Future<bool> activateOneHourPass({DateTime? now}) async {
    // Si l'essai a déjà été utilisé (ou est en cours), on interdit une réactivation
    if (_hasUsedOneHourTrial && !isPass1hActive) {
      debugPrint('AccessControlProvider : Essai Pass 1H déjà consommé sur cet appareil');
      return false;
    }

    final current = now ?? DateTime.now();
    _pass1hExpiresAt = current.add(MonetizationConfig.pass1hDuration);
    _hasUsedOneHourTrial = true;

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_hasUsedOneHourTrialKey, true);
      await prefs.setString(_pass1hExpiresAtKey, _pass1hExpiresAt!.toIso8601String());
    } catch (e) {
      debugPrint('Avertissement sauvegarde état Pass 1H : $e');
    }

    notifyListeners();
    return true;
  }

  // --- DÉBLOCAGE TEMPORAIRE (REWARDED AD PAR SESSION) ---

  /// Débloque un pack pour la durée de la partie active (après visionnage d'une pub récompensée)
  void unlockTemporarily(String packId) {
    if (_temporarilyUnlockedPacks.add(packId)) {
      notifyListeners();
    }
  }

  /// Réinitialise l'ensemble des déblocages temporaires (appelé lors du retour au Hub)
  void resetTemporaryUnlocks() {
    if (_temporarilyUnlockedPacks.isNotEmpty) {
      _temporarilyUnlockedPacks.clear();
      notifyListeners();
    }
  }

  // --- GESTION DES ACHATS REVENUECAT ---

  /// Charge les offres RevenueCat en temps réel et extrait les tarifs réels
  Future<void> fetchOfferings() async {
    if (!isSupportedPlatform) return;
    try {
      final offerings = await Purchases.getOfferings();
      final currentOffering = offerings.current;
      if (currentOffering != null) {
        for (final pkg in currentOffering.availablePackages) {
          if (pkg.packageType == PackageType.weekly ||
              pkg.identifier == MonetizationConfig.weeklyPackageIdentifier) {
            _weeklyPackage = pkg;
            _weeklyPrice = pkg.storeProduct.priceString;
          } else if (pkg.packageType == PackageType.annual ||
              pkg.identifier == MonetizationConfig.annualPackageIdentifier) {
            _annualPackage = pkg;
            _annualPrice = pkg.storeProduct.priceString;
          }
        }
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Avertissement chargement offerings RevenueCat : $e');
    }
  }

  /// Déclenche l'achat de la formule Duo choisie (annuelle avec -70% ou hebdomadaire)
  Future<bool> purchasePlan({required bool isAnnual}) async {
    if (!isSupportedPlatform) {
      debugPrint('Achat simulé en environnement non supporté');
      _isSubscribed = true;
      notifyListeners();
      return true;
    }

    final targetPkg = isAnnual ? _annualPackage : _weeklyPackage;
    if (targetPkg != null) {
      try {
        final purchaseResult = await Purchases.purchase(PurchaseParams.package(targetPkg));
        _updateSubscriptionStatus(purchaseResult.customerInfo);
        return _isSubscribed;
      } catch (e) {
        debugPrint('Erreur achat package spécifique RevenueCat : $e');
        return false;
      }
    }

    return purchaseSubscription();
  }

  /// Déclenche le flux d'achat par défaut de l'abonnement VIP
  Future<bool> purchaseSubscription() async {
    if (!isSupportedPlatform) {
      debugPrint('Achat simulé en environnement non supporté');
      _isSubscribed = true;
      notifyListeners();
      return true;
    }

    try {
      final offerings = await Purchases.getOfferings();
      final currentOffering = offerings.current;
      if (currentOffering != null && currentOffering.availablePackages.isNotEmpty) {
        final packageToBuy = currentOffering.availablePackages.first;
        final purchaseResult = await Purchases.purchase(PurchaseParams.package(packageToBuy));
        _updateSubscriptionStatus(purchaseResult.customerInfo);
        return _isSubscribed;
      }
    } catch (e) {
      debugPrint('Erreur lors de l\'achat d\'abonnement : $e');
    }
    return false;
  }

  /// Restaure les achats existants de l'utilisateur
  Future<bool> restorePurchases() async {
    if (!isSupportedPlatform) {
      return false;
    }

    try {
      final customerInfo = await Purchases.restorePurchases();
      _updateSubscriptionStatus(customerInfo);
      return _isSubscribed;
    } catch (e) {
      debugPrint('Erreur restauration des achats : $e');
      return false;
    }
  }

  // --- MÉTHODES UTILITAIRES POUR LES TESTS ---

  @visibleForTesting
  void setPricesForTest({String? weekly, String? annual}) {
    if (weekly != null) _weeklyPrice = weekly;
    if (annual != null) _annualPrice = annual;
    notifyListeners();
  }

  @visibleForTesting
  void setSubscribedForTest(bool subscribed) {
    _isSubscribed = subscribed;
    notifyListeners();
  }

  @visibleForTesting
  void setPass1hForTest({DateTime? expiresAt, bool hasUsed = false}) {
    _pass1hExpiresAt = expiresAt;
    _hasUsedOneHourTrial = hasUsed;
    notifyListeners();
  }

  @visibleForTesting
  void clearForTest() {
    _isSubscribed = false;
    _isPromoUnlocked = false;
    _pass1hExpiresAt = null;
    _hasUsedOneHourTrial = false;
    _temporarilyUnlockedPacks.clear();
    notifyListeners();
  }
}
