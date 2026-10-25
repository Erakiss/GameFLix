// lib/state/access_control_provider.dart
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart';
import 'package:purchases_flutter/purchases_flutter.dart';

// --- GESTIONNAIRE D'ACCÈS ET D'ABONNEMENTS (REVENUECAT & ADS) ---

/// Provider centralisant les droits d'accès aux packs de contenu :
/// 1. Gestion de l'abonnement RevenueCat (accès permanent et illimité).
/// 2. Gestion des déblocages temporaires via Rewarded Ad (valable pour la session de jeu active).
/// 3. Réinitialisation automatique des déblocages temporaires lors du retour au Hub.
class AccessControlProvider extends ChangeNotifier {
  /// Instance singleton pour accès direct hors BuildContext (ex: goToHub)
  static final AccessControlProvider instance = AccessControlProvider._();

  AccessControlProvider._();

  bool _isInitialized = false;
  bool _isSubscribed = false;

  /// Ensemble des identifiants de packs débloqués temporairement pour la session en cours
  final Set<String> _temporarilyUnlockedPacks = {};

  // --- GETTERS D'ÉTAT ---

  bool get isInitialized => _isInitialized;
  bool get isSubscribed => _isSubscribed;
  Set<String> get temporarilyUnlockedPacks => Set.unmodifiable(_temporarilyUnlockedPacks);

  /// Vérifie si la plateforme actuelle supporte RevenueCat
  bool get isSupportedPlatform {
    if (kIsWeb) return false;
    if (Platform.environment.containsKey('FLUTTER_TEST')) return false;
    return Platform.isAndroid || Platform.isIOS;
  }

  // --- INITIALISATION REVENUECAT ---

  /// Initialise le SDK RevenueCat avec gestion d'erreur hors-ligne
  Future<void> init({String? apiKey}) async {
    if (_isInitialized) return;

    if (!isSupportedPlatform) {
      _isInitialized = true;
      notifyListeners();
      return;
    }

    try {
      // 1. Clé API RevenueCat par défaut ou fournie
      final key = apiKey ??
          (Platform.isAndroid
              ? 'goog_sample_gameflix_revcat_key'
              : 'appl_sample_gameflix_revcat_key');

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

      _isInitialized = true;
    } catch (e) {
      debugPrint('Avertissement AccessControlProvider.init() (hors-ligne ou test) : $e');
      _isInitialized = true;
    }

    notifyListeners();
  }

  void _updateSubscriptionStatus(CustomerInfo customerInfo) {
    // Vérifie si l'utilisateur possède l'entitlement 'premium' ou un abonnement actif
    final hasPremium = customerInfo.entitlements.all['premium']?.isActive ?? false;
    final hasActiveSub = customerInfo.activeSubscriptions.isNotEmpty;
    _isSubscribed = hasPremium || hasActiveSub;
    notifyListeners();
  }

  // --- VÉRIFICATION DES DROITS D'ACCÈS ---

  /// Vérifie si l'utilisateur peut accéder au pack spécifié :
  /// - Gratuit (non premium) : toujours accessible
  /// - Abonné VIP : accès illimité à tous les packs
  /// - Débloqué temporairement via Rewarded Ad : accessible pour la partie
  bool canAccess(String packId, {bool isPremium = false}) {
    // 1. Les packs gratuits sont toujours accessibles
    if (!isPremium) return true;

    // 2. Les abonnés ont accès à l'ensemble du catalogue
    if (_isSubscribed) return true;

    // 3. Vérification du déblocage temporaire pour la session
    return _temporarilyUnlockedPacks.contains(packId);
  }

  /// Indique si un pack précis a été débloqué temporairement
  bool isTemporarilyUnlocked(String packId) {
    return _temporarilyUnlockedPacks.contains(packId);
  }

  // --- DÉBLOCAGE TEMPORAIRE (REWARDED AD) ---

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

  /// Déclenche le flux d'achat de l'abonnement VIP
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
  void setSubscribedForTest(bool subscribed) {
    _isSubscribed = subscribed;
    notifyListeners();
  }

  @visibleForTesting
  void clearForTest() {
    _isSubscribed = false;
    _temporarilyUnlockedPacks.clear();
    notifyListeners();
  }
}
