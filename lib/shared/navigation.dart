// lib/shared/navigation.dart
import 'package:flutter/material.dart';
import 'package:gameflix/services/ad_manager.dart';
import 'package:gameflix/state/access_control_provider.dart';

/// Nom de route attribué au Hub (voir splash_screen.dart).
const String kHubRouteName = '/hub';

/// Retour unique et fiable vers le Hub depuis n'importe quel écran de jeu.
///
/// 1. Réinitialise les déblocages temporaires de packs.
/// 2. Déclenche l'affichage d'un interstitiel si le cooldown de 4 minutes est respecté.
/// 3. Dépile la navigation jusqu'à la route racine du Hub.
void goToHub(BuildContext context) {
  AccessControlProvider.instance.resetTemporaryUnlocks();
  AdManager.instance.showInterstitialIfAllowed();
  Navigator.of(context).popUntil((route) => route.settings.name == kHubRouteName || route.isFirst);
}
