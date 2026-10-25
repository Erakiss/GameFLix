// lib/shared/navigation.dart
import 'package:flutter/material.dart';

/// Nom de route attribué au Hub (voir splash_screen.dart).
const String kHubRouteName = '/hub';

/// Retour unique et fiable vers le Hub depuis n'importe quel écran de jeu.
///
/// On dépile la pile jusqu'à la route du Hub au lieu d'en recréer une
/// nouvelle instance (`pushAndRemoveUntil(GameFlixHub())`), ce qui évitait
/// de recharger le Hub et pouvait laisser plusieurs Hubs empilés.
void goToHub(BuildContext context) {
  Navigator.of(context).popUntil((route) => route.settings.name == kHubRouteName || route.isFirst);
}
