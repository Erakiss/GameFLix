// lib/l10n/app_strings.dart
import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';
import 'package:gameflix/l10n/locale_controller.dart';

/// Dictionnaire centralisé des textes de l'interface (FR / EN / ES).
class AppStrings {
  final AppLocale locale;

  const AppStrings(this.locale);

  /// Récupère l'instance [AppStrings] réactive via le [BuildContext] (écoute les changements).
  static AppStrings of(BuildContext context) {
    try {
      final controller = context.watch<LocaleController>();
      return AppStrings(controller.currentLocale);
    } catch (_) {
      return AppStrings(LocaleController.instance.currentLocale);
    }
  }

  /// Récupère l'instance [AppStrings] sans écoute réactive.
  static AppStrings read(BuildContext context) {
    try {
      final controller = context.read<LocaleController>();
      return AppStrings(controller.currentLocale);
    } catch (_) {
      return AppStrings(LocaleController.instance.currentLocale);
    }
  }

  // --- HUB & NAVIGATION ---

  String get selectGame => switch (locale) {
        AppLocale.fr => 'SÉLECTIONNE UN JEU',
        AppLocale.en => 'SELECT A GAME',
        AppLocale.es => 'SELECCIONA UN JUEGO',
      };

  String get newBadge => switch (locale) {
        AppLocale.fr => 'NEW',
        AppLocale.en => 'NEW',
        AppLocale.es => 'NUEVO',
      };

  String get proBadge => switch (locale) {
        AppLocale.fr => '🔥 PRO',
        AppLocale.en => '🔥 PRO',
        AppLocale.es => '🔥 PRO',
      };

  String get proActiveBadge => switch (locale) {
        AppLocale.fr => '👑 PRO ACTIF',
        AppLocale.en => '👑 PRO ACTIVE',
        AppLocale.es => '👑 PRO ACTIVO',
      };

  String minPlayersError(int min) => switch (locale) {
        AppLocale.fr => '⚠️ Il faut au moins $min joueurs pour ce jeu !',
        AppLocale.en => '⚠️ At least $min players are required for this game!',
        AppLocale.es => '⚠️ ¡Se necesitan al menos $min jugadores para este juego!',
      };

  String minMaxPlayersError(int min, int max) => switch (locale) {
        AppLocale.fr => '⚠️ Il faut entre $min et $max joueurs pour ce jeu !',
        AppLocale.en => '⚠️ Between $min and $max players are required for this game!',
        AppLocale.es => '⚠️ ¡Se necesitan entre $min y $max jugadores para este juego!',
      };

  /// Retourne le sous-titre traduit d'un jeu selon son identifiant.
  String gameSubtitle(String gameId, String fallback) => switch (gameId) {
        'tod' => switch (locale) {
            AppLocale.fr => 'Action ou Vérité revisité',
            AppLocale.en => 'Truth or Dare reinvented',
            AppLocale.es => 'Verdad o Reto reinventado',
          },
        'nhie' => switch (locale) {
            AppLocale.fr => "Je n'ai jamais... mais en course !",
            AppLocale.en => 'Never Have I Ever... in a race!',
            AppLocale.es => 'Yo Nunca... ¡pero en carrera!',
          },
        'imp' => switch (locale) {
            AppLocale.fr => 'Imposteur ou Mister White ?',
            AppLocale.en => 'Imposter or Mister White?',
            AppLocale.es => '¿Impostor o Mister White?',
          },
        'wyr' => switch (locale) {
            AppLocale.fr => 'Le choix impossible',
            AppLocale.en => 'The impossible choice',
            AppLocale.es => 'La elección imposible',
          },
        'board' => switch (locale) {
            AppLocale.fr => "Le plateau de l'enfer",
            AppLocale.en => 'The board of hell',
            AppLocale.es => 'El tablero del infierno',
          },
        'code' => switch (locale) {
            AppLocale.fr => 'Codenames Express',
            AppLocale.en => 'Codenames Express',
            AppLocale.es => 'Codenames Express',
          },
        'coming_soon' => switch (locale) {
            AppLocale.fr => 'Le code chauffe...',
            AppLocale.en => 'Cooking up next game...',
            AppLocale.es => 'Preparando el próximo juego...',
          },
        _ => fallback,
      };

  /// Retourne le titre traduit d'un jeu selon son identifiant.
  String gameTitle(String gameId, String fallback) => switch (gameId) {
        'tod' => switch (locale) {
            AppLocale.fr => 'Action ou Vérité',
            AppLocale.en => 'Truth or Dare',
            AppLocale.es => 'Verdad o Reto',
          },
        'nhie' => switch (locale) {
            AppLocale.fr => "Je n'ai jamais",
            AppLocale.en => 'Never Have I Ever',
            AppLocale.es => 'Yo Nunca',
          },
        'imp' => switch (locale) {
            AppLocale.fr => "L'Imposteur",
            AppLocale.en => 'The Imposter',
            AppLocale.es => 'El Impostor',
          },
        'wyr' => switch (locale) {
            AppLocale.fr => 'Tu préfères',
            AppLocale.en => 'Would You Rather',
            AppLocale.es => '¿Qué Prefieres?',
          },
        'board' => switch (locale) {
            AppLocale.fr => 'Jeu de Plateau',
            AppLocale.en => 'Board Game',
            AppLocale.es => 'Juego de Mesa',
          },
        'code' => switch (locale) {
            AppLocale.fr => 'Codenames',
            AppLocale.en => 'Codenames',
            AppLocale.es => 'Codenames',
          },
        _ => fallback,
      };

  // --- GESTION DES JOUEURS (PLAYER MANAGER SHEET) ---

  String get playersTitle => switch (locale) {
        AppLocale.fr => 'LES JOUEURS',
        AppLocale.en => 'PLAYERS',
        AppLocale.es => 'JUGADORES',
      };

  String get boyLabel => switch (locale) {
        AppLocale.fr => '♂ Garçon',
        AppLocale.en => '♂ Boy',
        AppLocale.es => '♂ Chico',
      };

  String get girlLabel => switch (locale) {
        AppLocale.fr => '♀ Fille',
        AppLocale.en => '♀ Girl',
        AppLocale.es => '♀ Chica',
      };

  String get targetsPrompt => switch (locale) {
        AppLocale.fr => 'Cibles pour les gages rapprochés :',
        AppLocale.en => 'Targets for close/spicy dares:',
        AppLocale.es => 'Objetivos para retos cercanos:',
      };

  String get targetBoys => switch (locale) {
        AppLocale.fr => '♂ Garçons',
        AppLocale.en => '♂ Boys',
        AppLocale.es => '♂ Chicos',
      };

  String get targetGirls => switch (locale) {
        AppLocale.fr => '♀ Filles',
        AppLocale.en => '♀ Girls',
        AppLocale.es => '♀ Chicas',
      };

  String get firstNameHint => switch (locale) {
        AppLocale.fr => 'Prénom...',
        AppLocale.en => 'First name...',
        AppLocale.es => 'Nombre...',
      };

  String get duplicateNameError => switch (locale) {
        AppLocale.fr => 'Ce nom est déjà pris ! Ajoute une initiale (ex: Test 2).',
        AppLocale.en => 'This name is already taken! Add an initial (e.g. Alex 2).',
        AppLocale.es => '¡Este nombre ya está en uso! Añade una inicial (ej: Alex 2).',
      };

  String get emptyPlayersMessage => switch (locale) {
        AppLocale.fr => 'Aucun joueur pour le moment.\nAjoute tes potes pour commencer !',
        AppLocale.en => 'No players yet.\nAdd your friends to start!',
        AppLocale.es => 'Aún no hay jugadores.\n¡Añade a tus amigos para empezar!',
      };

  // --- MENU RÉGLAGES (SETTINGS OVERLAY) & AUDIO ---

  String get settingsTitle => switch (locale) {
        AppLocale.fr => 'RÉGLAGES',
        AppLocale.en => 'SETTINGS',
        AppLocale.es => 'AJUSTES',
      };

  String get volumeSectionTitle => switch (locale) {
        AppLocale.fr => 'CONTRÔLE DU VOLUME',
        AppLocale.en => 'VOLUME CONTROL',
        AppLocale.es => 'CONTROL DE VOLUMEN',
      };

  String get masterVolumeLabel => switch (locale) {
        AppLocale.fr => 'Volume général',
        AppLocale.en => 'Master Volume',
        AppLocale.es => 'Volumen general',
      };

  String get bgmToggleLabel => switch (locale) {
        AppLocale.fr => 'Musique (BGM)',
        AppLocale.en => 'Music (BGM)',
        AppLocale.es => 'Música (BGM)',
      };

  String get sfxToggleLabel => switch (locale) {
        AppLocale.fr => 'Effets sonores (SFX)',
        AppLocale.en => 'Sound Effects (SFX)',
        AppLocale.es => 'Efectos de sonido (SFX)',
      };

  String get languageSectionTitle => switch (locale) {
        AppLocale.fr => 'LANGUE',
        AppLocale.en => 'LANGUAGE',
        AppLocale.es => 'IDIOMA',
      };

  String get subscriptionSectionTitle => switch (locale) {
        AppLocale.fr => 'GÉRER MON ABONNEMENT',
        AppLocale.en => 'MANAGE MY SUBSCRIPTION',
        AppLocale.es => 'GESTIONAR MI SUSCRIPCIÓN',
      };

  String get subStatusActive => switch (locale) {
        AppLocale.fr => 'Statut : Membre VIP Actif 👑',
        AppLocale.en => 'Status: Active VIP Member 👑',
        AppLocale.es => 'Estado: Miembro VIP Activo 👑',
      };

  String get subStatusFree => switch (locale) {
        AppLocale.fr => 'Statut : Version Gratuite',
        AppLocale.en => 'Status: Free Version',
        AppLocale.es => 'Estado: Versión Gratuita',
      };

  String get unlockProButton => switch (locale) {
        AppLocale.fr => 'Passer en PRO / VIP 🔥',
        AppLocale.en => 'Upgrade to PRO / VIP 🔥',
        AppLocale.es => 'Pasar a PRO / VIP 🔥',
      };

  String get restorePurchasesButton => switch (locale) {
        AppLocale.fr => 'Restaurer mes achats',
        AppLocale.en => 'Restore Purchases',
        AppLocale.es => 'Restaurar compras',
      };

  String get restoreSuccessMessage => switch (locale) {
        AppLocale.fr => '👑 Achats restaurés avec succès !',
        AppLocale.en => '👑 Purchases successfully restored!',
        AppLocale.es => '👑 ¡Compras restauradas con éxito!',
      };

  String get restoreEmptyMessage => switch (locale) {
        AppLocale.fr => 'Aucun abonnement actif trouvé à restaurer.',
        AppLocale.en => 'No active subscription found to restore.',
        AppLocale.es => 'No se encontró ninguna suscripción activa para restaurar.',
      };

  String get giftCodeTitle => switch (locale) {
        AppLocale.fr => 'ESPACE CADEAU 🎁',
        AppLocale.en => 'GIFT CODE 🎁',
        AppLocale.es => 'CÓDIGO DE REGALO 🎁',
      };

  String get giftCodeHint => switch (locale) {
        AppLocale.fr => 'Code cadeau...',
        AppLocale.en => 'Gift code...',
        AppLocale.es => 'Código de regalo...',
      };

  String get giftCodeValidateButton => switch (locale) {
        AppLocale.fr => 'Activer',
        AppLocale.en => 'Activate',
        AppLocale.es => 'Activar',
      };

  String get giftCodeSuccessMessage => switch (locale) {
        AppLocale.fr => '✨ Code validé ! Le mode Pro est débloqué à vie ! 👑',
        AppLocale.en => '✨ Code activated! Pro mode unlocked for life! 👑',
        AppLocale.es => '¡Código activado! ¡Modo Pro desbloqueado de por vida! 👑',
      };

  String get giftCodeErrorMessage => switch (locale) {
        AppLocale.fr => 'Code cadeau invalide ou expiré.',
        AppLocale.en => 'Invalid or expired gift code.',
        AppLocale.es => 'Código de regalo no válido o caducado.',
      };

  String get suggestQuestionSectionTitle => switch (locale) {
        AppLocale.fr => 'PROPOSER UNE QUESTION',
        AppLocale.en => 'SUGGEST A QUESTION',
        AppLocale.es => 'SUGERIR UNA PREGUNTA',
      };

  String get suggestQuestionButton => switch (locale) {
        AppLocale.fr => 'Envoyer une idée de carte / gage 💡',
        AppLocale.en => 'Submit a card or dare idea 💡',
        AppLocale.es => 'Enviar una idea de carta / reto 💡',
      };

  String get suggestDialogTitle => switch (locale) {
        AppLocale.fr => 'PROPOSER UNE IDÉE 💡',
        AppLocale.en => 'SUGGEST AN IDEA 💡',
        AppLocale.es => 'SUGERIR UNA IDEA 💡',
      };

  String get suggestInputHint => switch (locale) {
        AppLocale.fr => 'Ton idée de carte ou gage...',
        AppLocale.en => 'Your card or dare idea...',
        AppLocale.es => 'Tu idea de carta o reto...',
      };

  String get sendButton => switch (locale) {
        AppLocale.fr => 'ENVOYER',
        AppLocale.en => 'SEND',
        AppLocale.es => 'ENVIAR',
      };

  String get cancelButton => switch (locale) {
        AppLocale.fr => 'Annuler',
        AppLocale.en => 'Cancel',
        AppLocale.es => 'Cancelar',
      };

  String get suggestionSentMessage => switch (locale) {
        AppLocale.fr => 'Merci ! Ta suggestion est prête à être envoyée (et copiée dans le presse-papier).',
        AppLocale.en => 'Thanks! Your suggestion is ready to send (and copied to clipboard).',
        AppLocale.es => '¡Gracias! Tu sugerencia está lista para enviarse (y copiada al portapapeles).',
      };

  String get contactSectionTitle => switch (locale) {
        AppLocale.fr => 'NOUS CONTACTER',
        AppLocale.en => 'CONTACT US',
        AppLocale.es => 'CONTÁCTANOS',
      };

  String get contactButton => switch (locale) {
        AppLocale.fr => 'Contacter le support ✉️',
        AppLocale.en => 'Contact Support ✉️',
        AppLocale.es => 'Contactar con soporte ✉️',
      };

  String contactCopiedMessage(String email) => switch (locale) {
        AppLocale.fr => 'Email de support copié : $email',
        AppLocale.en => 'Support email copied: $email',
        AppLocale.es => 'Correo de soporte copiado: $email',
      };
}
