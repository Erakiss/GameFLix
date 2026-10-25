// lib/shared/navigation.dart
import 'package:flutter/material.dart';
import 'package:gameflix/services/ad_manager.dart';

/// Nom de route attribué au Hub (voir splash_screen.dart).
const String kHubRouteName = '/hub';

/// Retour unique et fiable vers le Hub depuis n'importe quel écran de jeu.
///
/// Déclenche l'affichage d'un interstitiel si le cooldown de 4 minutes est respecté,
/// puis dépile la navigation jusqu'à la route racine du Hub.
void goToHub(BuildContext context) {
  AdManager.instance.showInterstitialIfAllowed();
  Navigator.of(context).popUntil((route) => route.settings.name == kHubRouteName || route.isFirst);
}
