// lib/l10n/strings_imp_code.dart
import 'package:gameflix/l10n/app_strings.dart';
import 'package:gameflix/l10n/locale_controller.dart';

/// Traductions pour L'Imposteur (imp) et Codenames (code).
extension ImpCodeStrings on AppStrings {
  // --- IMPOSTER : LOBBY ---

  String get impSelectCategoryError => switch (locale) {
        AppLocale.fr => 'Sélectionne au moins une catégorie !',
        AppLocale.en => 'Select at least one category!',
        AppLocale.es => '¡Selecciona al menos una categoría!',
      };

  String get impMisterWhiteModeTitle => switch (locale) {
        AppLocale.fr => 'Mode Mister White',
        AppLocale.en => 'Mister White Mode',
        AppLocale.es => 'Modo Mister White',
      };

  String get impMisterWhiteModeSubtitle => switch (locale) {
        AppLocale.fr => "L'imposteur n'aura AUCUN mot secret.",
        AppLocale.en => 'The imposter will have NO secret word.',
        AppLocale.es => 'El impostor NO tendrá ninguna palabra secreta.',
      };

  String get impDealRolesButton => switch (locale) {
        AppLocale.fr => 'DISTRIBUER LES RÔLES',
        AppLocale.en => 'DEAL ROLES',
        AppLocale.es => 'REPARTIR ROLES',
      };

  // --- IMPOSTER : DISTRIBUTION & DÉBAT ---

  String get impYouAreMisterWhite => switch (locale) {
        AppLocale.fr => 'TU ES MISTER WHITE',
        AppLocale.en => 'YOU ARE MISTER WHITE',
        AppLocale.es => 'ERES MISTER WHITE',
      };

  String get impMisterWhiteSubtext => switch (locale) {
        AppLocale.fr =>
          "Tu n'as aucun mot. Écoute les autres pour le deviner !",
        AppLocale.en => 'You have no word. Listen to others to guess it!',
        AppLocale.es =>
          'No tienes ninguna palabra. ¡Escucha a los demás para adivinarla!',
      };

  String get impSecretWordSubtext => switch (locale) {
        AppLocale.fr => 'Mémorise ce mot et garde-le secret.',
        AppLocale.en => 'Memorize this word and keep it secret.',
        AppLocale.es => 'Memoriza esta palabra y mantenla en secreto.',
      };

  String get impPassPhoneTo => switch (locale) {
        AppLocale.fr => 'Passez le téléphone à',
        AppLocale.en => 'Pass the phone to',
        AppLocale.es => 'Pasa el teléfono a',
      };

  String get impSeeRoleButton => switch (locale) {
        AppLocale.fr => 'VOIR MON RÔLE',
        AppLocale.en => 'SEE MY ROLE',
        AppLocale.es => 'VER MI ROL',
      };

  String get impPrivacyWarning => switch (locale) {
        AppLocale.fr => 'Assurez-vous que personne ne regarde votre écran !',
        AppLocale.en => 'Make sure no one is looking at your screen!',
        AppLocale.es => '¡Asegúrate de que nadie esté mirando tu pantalla!',
      };

  String get impAttentionLabel => switch (locale) {
        AppLocale.fr => 'ATTENTION :',
        AppLocale.en => 'WARNING:',
        AppLocale.es => 'ATENCIÓN:',
      };

  String get impYourSecretWordIs => switch (locale) {
        AppLocale.fr => 'TON MOT SECRET EST :',
        AppLocale.en => 'YOUR SECRET WORD IS:',
        AppLocale.es => 'TU PALABRA SECRETA ES:',
      };

  String get impHideAndStartButton => switch (locale) {
        AppLocale.fr => 'CACHER ET COMMENCER',
        AppLocale.en => 'HIDE AND START',
        AppLocale.es => 'OCULTAR Y EMPEZAR',
      };

  String get impHideAndPassButton => switch (locale) {
        AppLocale.fr => 'CACHER ET PASSER',
        AppLocale.en => 'HIDE AND PASS',
        AppLocale.es => 'OCULTAR Y PASAR',
      };

  String get impForgotWordDialogTitle => switch (locale) {
        AppLocale.fr => 'Qui a oublié son mot ?',
        AppLocale.en => 'Who forgot their word?',
        AppLocale.es => '¿Quién olvidó su palabra?',
      };

  String get impHideScreenFromOthers => switch (locale) {
        AppLocale.fr => "Cache l'écran aux autres !",
        AppLocale.en => 'Hide the screen from others!',
        AppLocale.es => '¡Oculta la pantalla a los demás!',
      };

  String get impHoldToSeeButton => switch (locale) {
        AppLocale.fr => 'MAINTENIR POUR VOIR',
        AppLocale.en => 'HOLD TO SEE',
        AppLocale.es => 'MANTENER PARA VER',
      };

  String get impDebateTimeTitle => switch (locale) {
        AppLocale.fr => 'TEMPS DE DÉBAT',
        AppLocale.en => 'DEBATE TIME',
        AppLocale.es => 'TIEMPO DE DEBATE',
      };

  String get impDebateSubtitle => switch (locale) {
        AppLocale.fr => 'Posez-vous des questions pour\ndémasquer les menteurs !',
        AppLocale.en => 'Ask each other questions to\nunmask the liars!',
        AppLocale.es => '¡Haceos preguntas para\ndesenmascarar a los mentirosos!',
      };

  String get impGoToVoteButton => switch (locale) {
        AppLocale.fr => 'PASSER AU VOTE',
        AppLocale.en => 'GO TO VOTE',
        AppLocale.es => 'IR A VOTAR',
      };

  String get impForgotWordButton => switch (locale) {
        AppLocale.fr => "J'ai oublié mon mot",
        AppLocale.en => 'I forgot my word',
        AppLocale.es => 'Olvidé mi palabra',
      };

  // --- IMPOSTER : SCOREBOARD ---

  String get impRoleMisterWhite => switch (locale) {
        AppLocale.fr => 'MISTER WHITE',
        AppLocale.en => 'MISTER WHITE',
        AppLocale.es => 'MISTER WHITE',
      };

  String get impRoleImposter => switch (locale) {
        AppLocale.fr => 'IMPOSTEUR',
        AppLocale.en => 'IMPOSTER',
        AppLocale.es => 'IMPOSTOR',
      };

  String get impRoleCivil => switch (locale) {
        AppLocale.fr => 'CIVIL',
        AppLocale.en => 'CIVILIAN',
        AppLocale.es => 'CIVIL',
      };

  String get impEliminationPhaseTitle => switch (locale) {
        AppLocale.fr => "PHASE D'ÉLIMINATION",
        AppLocale.en => 'ELIMINATION PHASE',
        AppLocale.es => 'FASE DE ELIMINACIÓN',
      };

  String get impCivilsVictory => switch (locale) {
        AppLocale.fr => 'VICTOIRE DES CIVILS !',
        AppLocale.en => 'CIVILIANS WIN!',
        AppLocale.es => '¡VICTORIA DE LOS CIVILES!',
      };

  String get impImpostersVictory => switch (locale) {
        AppLocale.fr => 'VICTOIRE DES IMPOSTEURS !',
        AppLocale.en => 'IMPOSTERS WIN!',
        AppLocale.es => '¡VICTORIA DE LOS IMPOSTORES!',
      };

  String get impMisterWhiteVictory => switch (locale) {
        AppLocale.fr => 'MISTER WHITE A TROUVÉ LE MOT !',
        AppLocale.en => 'MISTER WHITE GUESSED THE WORD!',
        AppLocale.es => '¡MISTER WHITE ADIVINÓ LA PALABRA!',
      };

  String get impMisterWhiteSaveYourself => switch (locale) {
        AppLocale.fr => 'MISTER WHITE, SAUVE TOI !',
        AppLocale.en => 'MISTER WHITE, SAVE YOURSELF!',
        AppLocale.es => '¡MISTER WHITE, SÁLVATE!',
      };

  String get impTapEliminatedPlayer => switch (locale) {
        AppLocale.fr => 'Appuyez sur un joueur éliminé par le groupe.',
        AppLocale.en => 'Tap a player eliminated by the group.',
        AppLocale.es => 'Toca a un jugador eliminado por el grupo.',
      };

  String get impWordsHiddenLabel => switch (locale) {
        AppLocale.fr => 'LES MOTS SONT CACHÉS',
        AppLocale.en => 'WORDS ARE HIDDEN',
        AppLocale.es => 'LAS PALABRAS ESTÁN OCULTAS',
      };

  String get impMisterWhiteLastChance => switch (locale) {
        AppLocale.fr =>
          'Tu as été démasqué... Mais tu as une dernière chance !',
        AppLocale.en =>
          'You were unmasked... But you have one last chance!',
        AppLocale.es =>
          '¡Te han descubierto... pero tienes una última oportunidad!',
      };

  String get impMisterWhiteGuessHint => switch (locale) {
        AppLocale.fr => 'Écris le mot ici...',
        AppLocale.en => 'Type the word here...',
        AppLocale.es => 'Escribe la palabra aquí...',
      };

  String get impValidateWordButton => switch (locale) {
        AppLocale.fr => 'VALIDER MON MOT',
        AppLocale.en => 'SUBMIT MY GUESS',
        AppLocale.es => 'CONFIRMAR PALABRA',
      };

  // --- CODENAMES : LOBBY ---

  String get codeTeamMinPlayersError => switch (locale) {
        AppLocale.fr =>
          'Chaque équipe doit avoir au moins 2 joueurs (1 Espion + 1 Devineur) !',
        AppLocale.en =>
          'Each team must have at least 2 players (1 Spymaster + 1 Operative)!',
        AppLocale.es =>
          '¡Cada equipo debe tener al menos 2 jugadores (1 Espía + 1 Agente)!',
      };

  String get codeSpyRoleBadge => switch (locale) {
        AppLocale.fr => 'ESPION 👁️',
        AppLocale.en => 'SPYMASTER 👁️',
        AppLocale.es => 'ESPÍA 👁️',
      };

  String get codeGuesserRoleBadge => switch (locale) {
        AppLocale.fr => 'DEVINEUR',
        AppLocale.en => 'OPERATIVE',
        AppLocale.es => 'AGENTE',
      };

  String get codeTapToMoveHint => switch (locale) {
        AppLocale.fr => 'Appuyez pour déplacer',
        AppLocale.en => 'Tap to move',
        AppLocale.es => 'Toca para mover',
      };

  String get codeExpressModeLabel => switch (locale) {
        AppLocale.fr => 'Activer le mode Express',
        AppLocale.en => 'Enable Express Mode',
        AppLocale.es => 'Activar el modo Express',
      };

  String get codeTeamRed => switch (locale) {
        AppLocale.fr => 'ROUGE',
        AppLocale.en => 'RED',
        AppLocale.es => 'ROJO',
      };

  String get codeTeamBlue => switch (locale) {
        AppLocale.fr => 'BLEU',
        AppLocale.en => 'BLUE',
        AppLocale.es => 'AZUL',
      };

  String get codeGenerateGridButton => switch (locale) {
        AppLocale.fr => 'GÉNÉRER LA GRILLE',
        AppLocale.en => 'GENERATE GRID',
        AppLocale.es => 'GENERAR CUADRÍCULA',
      };

  // --- CODENAMES : GAME ---

  String get codeAssassinOverlay => switch (locale) {
        AppLocale.fr => 'SYSTÈME COMPROMIS\nÉCHEC CRITIQUE',
        AppLocale.en => 'SYSTEM COMPROMISED\nCRITICAL FAILURE',
        AppLocale.es => 'SISTEMA COMPROMETIDO\nFALLO CRÍTICO',
      };

  String get codeNeutralOverlay => switch (locale) {
        AppLocale.fr => 'CIBLE NEUTRE\nFIN DE TRANSMISSION',
        AppLocale.en => 'NEUTRAL TARGET\nEND OF TRANSMISSION',
        AppLocale.es => 'OBJETIVO NEUTRAL\nFIN DE TRANSMISIÓN',
      };

  String get codeEnemyFirewallOverlay => switch (locale) {
        AppLocale.fr => 'FIREWALL ENNEMI\nACCÈS REFUSÉ',
        AppLocale.en => 'ENEMY FIREWALL\nACCESS DENIED',
        AppLocale.es => 'FIREWALL ENEMIGO\nACCESO DENEGADO',
      };

  String codeOverlayMessage(String key) => switch (key) {
        'ASSASSIN' => codeAssassinOverlay,
        'NEUTRAL' => codeNeutralOverlay,
        'ENEMY' => codeEnemyFirewallOverlay,
        _ => key,
      };

  String get codeAssassinFoundReason => switch (locale) {
        AppLocale.fr => "L'ASSASSIN A ÉTÉ TROUVÉ !",
        AppLocale.en => 'THE ASSASSIN WAS FOUND!',
        AppLocale.es => '¡SE ENCONTRÓ AL ASESINO!',
      };

  String get codeAllRedFoundReason => switch (locale) {
        AppLocale.fr => 'TOUS LES MOTS ROUGES ONT ÉTÉ TROUVÉS !',
        AppLocale.en => 'ALL RED WORDS HAVE BEEN FOUND!',
        AppLocale.es => '¡TODAS LAS PALABRAS ROJAS HAN SIDO ENCONTRADAS!',
      };

  String get codeAllBlueFoundReason => switch (locale) {
        AppLocale.fr => 'TOUS LES MOTS CYBER-BLEUS ONT ÉTÉ TROUVÉS !',
        AppLocale.en => 'ALL CYBER-BLUE WORDS HAVE BEEN FOUND!',
        AppLocale.es => '¡TODAS LAS PALABRAS CIBER-AZULES HAN SIDO ENCONTRADAS!',
      };

  String codeWinReason(String key) => switch (key) {
        'ASSASSIN' => codeAssassinFoundReason,
        'RED_ALL' => codeAllRedFoundReason,
        'BLUE_ALL' => codeAllBlueFoundReason,
        _ => key,
      };

  String codeSpyTurnTitle(String teamKey) => teamKey == 'RED'
      ? switch (locale) {
          AppLocale.fr => 'TOUR ESPION ROUGE',
          AppLocale.en => 'RED SPYMASTER TURN',
          AppLocale.es => 'TURNO ESPÍA ROJO',
        }
      : switch (locale) {
          AppLocale.fr => 'TOUR ESPION BLEU',
          AppLocale.en => 'BLUE SPYMASTER TURN',
          AppLocale.es => 'TURNO ESPÍA AZUL',
        };

  String codeSpyTurnSubtitle(String spyName) => switch (locale) {
        AppLocale.fr =>
          'Autorisation requise pour $spyName. Sécurisez le périmètre.',
        AppLocale.en =>
          'Authorization required for $spyName. Secure the perimeter.',
        AppLocale.es =>
          'Autorización requerida para $spyName. Asegura el perímetro.',
      };

  String get codeUnlockButton => switch (locale) {
        AppLocale.fr => 'DÉVERROUILLER',
        AppLocale.en => 'UNLOCK',
        AppLocale.es => 'DESBLOQUEAR',
      };

  String codeSpyNetworkTitle(String teamKey) => teamKey == 'RED'
      ? switch (locale) {
          AppLocale.fr => 'RÉSEAU ESPION ROUGE',
          AppLocale.en => 'RED SPY NETWORK',
          AppLocale.es => 'CANAL ESPÍA ROJO',
        }
      : switch (locale) {
          AppLocale.fr => 'RÉSEAU ESPION BLEU',
          AppLocale.en => 'BLUE SPY NETWORK',
          AppLocale.es => 'CANAL ESPÍA AZUL',
        };

  String get codeTransmitButton => switch (locale) {
        AppLocale.fr => 'TRANSMETTRE',
        AppLocale.en => 'TRANSMIT',
        AppLocale.es => 'TRANSMITIR',
      };

  String codeRedTargets(int count) => switch (locale) {
        AppLocale.fr => 'CIBLES ROUGE : $count',
        AppLocale.en => 'RED TARGETS: $count',
        AppLocale.es => 'OBJETIVOS ROJOS: $count',
      };

  String codeBlueTargets(int count) => switch (locale) {
        AppLocale.fr => 'CIBLES BLEU : $count',
        AppLocale.en => 'BLUE TARGETS: $count',
        AppLocale.es => 'OBJETIVOS AZULES: $count',
      };

  String codeHackingTitle(String teamKey) => teamKey == 'RED'
      ? switch (locale) {
          AppLocale.fr => 'PIRATAGE ROUGE',
          AppLocale.en => 'RED HACKING',
          AppLocale.es => 'HACKEO ROJO',
        }
      : switch (locale) {
          AppLocale.fr => 'PIRATAGE BLEU',
          AppLocale.en => 'BLUE HACKING',
          AppLocale.es => 'HACKEO AZUL',
        };

  String get codeEndTurnTooltip => switch (locale) {
        AppLocale.fr => 'Fin de transmission',
        AppLocale.en => 'End transmission',
        AppLocale.es => 'Fin de transmisión',
      };

  // --- CODENAMES : SCOREBOARD ---

  String get codeRedTeamName => switch (locale) {
        AppLocale.fr => 'ÉQUIPE ROUGE',
        AppLocale.en => 'RED TEAM',
        AppLocale.es => 'EQUIPO ROJO',
      };

  String get codeBlueTeamName => switch (locale) {
        AppLocale.fr => 'ÉQUIPE BLEUE',
        AppLocale.en => 'BLUE TEAM',
        AppLocale.es => 'EQUIPO AZUL',
      };

  String codeVictoryHeader(String teamName) => switch (locale) {
        AppLocale.fr => 'VICTOIRE\n$teamName',
        AppLocale.en => 'VICTORY\n$teamName',
        AppLocale.es => 'VICTORIA\n$teamName',
      };

  String get codeRedTeamBadge => switch (locale) {
        AppLocale.fr => '🔴 ROUGE',
        AppLocale.en => '🔴 RED',
        AppLocale.es => '🔴 ROJO',
      };

  String get codeBlueTeamBadge => switch (locale) {
        AppLocale.fr => '🔵 BLEU',
        AppLocale.en => '🔵 BLUE',
        AppLocale.es => '🔵 AZUL',
      };

  // --- COMMUN SCOREBOARD ---

  String get backToHubButton => switch (locale) {
        AppLocale.fr => 'RETOUR AU HUB',
        AppLocale.en => 'BACK TO HUB',
        AppLocale.es => 'VOLVER AL HUB',
      };
}
