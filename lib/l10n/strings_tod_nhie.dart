// lib/l10n/strings_tod_nhie.dart
import 'package:gameflix/l10n/app_strings.dart';
import 'package:gameflix/l10n/locale_controller.dart';

/// Traductions FR / EN / ES pour Action ou Vérité (`tod`) et Je n'ai jamais (`nhie`).
extension TodNhieStrings on AppStrings {
  // ===========================================================================
  // TRUTH OR DARE (Action ou Vérité) - LOBBY
  // ===========================================================================

  String get todCardAddedSnackbar => switch (locale) {
        AppLocale.fr => 'Carte ajoutée ! 🃏',
        AppLocale.en => 'Card added! 🃏',
        AppLocale.es => '¡Carta añadida! 🃏',
      };

  String get todSelectDeckError => switch (locale) {
        AppLocale.fr => '⚠️ Sélectionne au moins un paquet !',
        AppLocale.en => '⚠️ Select at least one deck!',
        AppLocale.es => '⚠️ ¡Selecciona al menos un mazo!',
      };

  String get todActiveDecksTitle => switch (locale) {
        AppLocale.fr => 'Paquets actifs',
        AppLocale.en => 'Active decks',
        AppLocale.es => 'Mazos activos',
      };

  String get todHotPackTitle => switch (locale) {
        AppLocale.fr => 'Pack Hot & Spicy',
        AppLocale.en => 'Hot & Spicy Pack',
        AppLocale.es => 'Pack Hot & Picante',
      };

  String todManageCustomCards(int count) => switch (locale) {
        AppLocale.fr => 'Gérer les $count cartes Custom',
        AppLocale.en => count == 1
            ? 'Manage 1 Custom card'
            : 'Manage $count Custom cards',
        AppLocale.es => count == 1
            ? 'Gestionar 1 carta Custom'
            : 'Gestionar las $count cartas Custom',
      };

  String get todGameLengthTitle => switch (locale) {
        AppLocale.fr => 'Durée de la partie',
        AppLocale.en => 'Game length',
        AppLocale.es => 'Duración de la partida',
      };

  String todTurnsCount(int turns) => switch (locale) {
        AppLocale.fr => '$turns tours',
        AppLocale.en => '$turns turns',
        AppLocale.es => '$turns turnos',
      };

  String get todStartGameButton => switch (locale) {
        AppLocale.fr => 'LANCER LA PARTIE',
        AppLocale.en => 'START GAME',
        AppLocale.es => 'EMPEZAR PARTIDA',
      };

  String get todNewCardTitle => switch (locale) {
        AppLocale.fr => 'Nouvelle Carte',
        AppLocale.en => 'New Card',
        AppLocale.es => 'Nueva Carta',
      };

  String get todYourCustomCardsTitle => switch (locale) {
        AppLocale.fr => 'Tes Cartes Custom',
        AppLocale.en => 'Your Custom Cards',
        AppLocale.es => 'Tus Cartas Custom',
      };

  String get todEmptyCustomCards => switch (locale) {
        AppLocale.fr => "Aucune carte custom pour l'instant.",
        AppLocale.en => 'No custom cards yet.',
        AppLocale.es => 'Aún no hay cartas personalizadas.',
      };

  String get todCreateNewCardButton => switch (locale) {
        AppLocale.fr => 'CRÉER UNE NOUVELLE CARTE',
        AppLocale.en => 'CREATE A NEW CARD',
        AppLocale.es => 'CREAR UNA NUEVA CARTA',
      };

  String get todCustomContentLabel => switch (locale) {
        AppLocale.fr => 'Contenu (utilise {TARGET} pour cibler un joueur)',
        AppLocale.en => 'Content (use {TARGET} to target a player)',
        AppLocale.es => 'Contenido (usa {TARGET} para elegir a un jugador)',
      };

  String get todCardTypeFieldLabel => switch (locale) {
        AppLocale.fr => 'Type de carte',
        AppLocale.en => 'Card type',
        AppLocale.es => 'Tipo de carta',
      };

  String get todSaveCardButton => switch (locale) {
        AppLocale.fr => 'VALIDER LA CARTE',
        AppLocale.en => 'SAVE CARD',
        AppLocale.es => 'GUARDAR CARTA',
      };

  // ===========================================================================
  // TRUTH OR DARE (Action ou Vérité) - GAME
  // ===========================================================================

  String get todSomeoneFallback => switch (locale) {
        AppLocale.fr => "quelqu'un",
        AppLocale.en => 'someone',
        AppLocale.es => 'alguien',
      };

  String get todNoCardsAvailableError => switch (locale) {
        AppLocale.fr => 'Plus aucune carte disponible pour ce choix !',
        AppLocale.en => 'No more cards available for this choice!',
        AppLocale.es => '¡No quedan cartas disponibles para esta opción!',
      };

  String get todSwipeDoneOverlay => switch (locale) {
        AppLocale.fr => 'FAIT ! 😎',
        AppLocale.en => 'DONE! 😎',
        AppLocale.es => '¡HECHO! 😎',
      };

  String get todSwipeRefusedOverlay => switch (locale) {
        AppLocale.fr => 'REFUSÉ ! 🥴',
        AppLocale.en => 'REFUSED! 🥴',
        AppLocale.es => '¡RECHAZADO! 🥴',
      };

  String get todGetReadyBanner => switch (locale) {
        AppLocale.fr => '🔥 PRÉPARE-TOI 🔥',
        AppLocale.en => '🔥 GET READY 🔥',
        AppLocale.es => '🔥 PREPÁRATE 🔥',
      };

  String get todYourTurnSubtitle => switch (locale) {
        AppLocale.fr => "C'est à ton tour de jouer...",
        AppLocale.en => "It's your turn to play...",
        AppLocale.es => 'Es tu turno de jugar...',
      };

  String todTurnCounter(int current, int max) => switch (locale) {
        AppLocale.fr => 'Tour $current / $max',
        AppLocale.en => 'Turn $current / $max',
        AppLocale.es => 'Turno $current / $max',
      };

  String get todTurnOfLabel => switch (locale) {
        AppLocale.fr => "C'est au tour de",
        AppLocale.en => 'Up next',
        AppLocale.es => 'Es el turno de',
      };

  String todSipsCounter(int score) => switch (locale) {
        AppLocale.fr => 'Gorgées : $score',
        AppLocale.en => 'Sips: $score',
        AppLocale.es => 'Tragos: $score',
      };

  String get todRefusedButton => switch (locale) {
        AppLocale.fr => 'REFUSÉ',
        AppLocale.en => 'REFUSED',
        AppLocale.es => 'RECHAZADO',
      };

  String get todDoneButton => switch (locale) {
        AppLocale.fr => 'FAIT',
        AppLocale.en => 'DONE',
        AppLocale.es => 'HECHO',
      };

  String get todActionLabel => switch (locale) {
        AppLocale.fr => 'ACTION',
        AppLocale.en => 'DARE',
        AppLocale.es => 'RETO',
      };

  String get todActionSubtitle => switch (locale) {
        AppLocale.fr => 'Relève le défi',
        AppLocale.en => 'Take the challenge',
        AppLocale.es => 'Acepta el desafío',
      };

  String get todTruthLabel => switch (locale) {
        AppLocale.fr => 'VÉRITÉ',
        AppLocale.en => 'TRUTH',
        AppLocale.es => 'VERDAD',
      };

  String get todTruthSubtitle => switch (locale) {
        AppLocale.fr => 'Avoue sans filtre',
        AppLocale.en => 'Confess unfiltered',
        AppLocale.es => 'Confiesa sin filtro',
      };

  String todCardTypeDisplay(String rawType) {
    final normalized = rawType.toUpperCase();
    if (normalized == 'ACTION') return todActionLabel;
    if (normalized == 'VERITE' || normalized == 'VÉRITÉ') return todTruthLabel;
    return rawType;
  }

  String get todTapHint => switch (locale) {
        AppLocale.fr => 'TAP',
        AppLocale.en => 'TAP',
        AppLocale.es => 'TOCA',
      };

  String todPenaltyLabel(int shots) => switch (locale) {
        AppLocale.fr => 'Pénalité : $shots 🍺',
        AppLocale.en => 'Penalty: $shots 🍺',
        AppLocale.es => 'Castigo: $shots 🍺',
      };

  // ===========================================================================
  // TRUTH OR DARE (Action ou Vérité) - SCOREBOARD
  // ===========================================================================

  String todPlayerTitle(int rank, int score, int totalPlayers) {
    if (score == 0) {
      return switch (locale) {
        AppLocale.fr => "L'Ange 😇 (Même pas soif)",
        AppLocale.en => 'The Angel 😇 (Not even thirsty)',
        AppLocale.es => 'El Ángel 😇 (Ni una gota)',
      };
    }
    if (rank == 0) {
      if (score >= 15) {
        return switch (locale) {
          AppLocale.fr => "L'Éponge Légendaire 🧽",
          AppLocale.en => 'The Legendary Sponge 🧽',
          AppLocale.es => 'La Esponja Legendaria 🧽',
        };
      }
      return switch (locale) {
        AppLocale.fr => 'Le Pilier de Bar 🍺',
        AppLocale.en => 'The Bar Regular 🍺',
        AppLocale.es => 'El Rey de la Barra 🍺',
      };
    }
    if (rank == totalPlayers - 1) {
      return switch (locale) {
        AppLocale.fr => 'Le Sam (Capitaine de soirée) 🚗',
        AppLocale.en => 'Designated Driver 🚗',
        AppLocale.es => 'El Conductor Designado 🚗',
      };
    }
    if (score <= 3) {
      return switch (locale) {
        AppLocale.fr => "L'Esquiveur 🥷",
        AppLocale.en => 'The Dodger 🥷',
        AppLocale.es => 'El Esquivador 🥷',
      };
    }
    if (score <= 8) {
      return switch (locale) {
        AppLocale.fr => 'Vitesse de Croisière 🛥️',
        AppLocale.en => 'Cruising Speed 🛥️',
        AppLocale.es => 'Velocidad de Crucero 🛥️',
      };
    }
    return switch (locale) {
      AppLocale.fr => 'Bien Chaud 🔥',
      AppLocale.en => 'Feeling It 🔥',
      AppLocale.es => 'Bien Encendido 🔥',
    };
  }

  String get todGameOverTitle => switch (locale) {
        AppLocale.fr => '🏆 FIN DE PARTIE 🏆',
        AppLocale.en => '🏆 GAME OVER 🏆',
        AppLocale.es => '🏆 FIN DE PARTIDA 🏆',
      };

  String get todScoreboardSubtitle => switch (locale) {
        AppLocale.fr => 'Qui a pris le plus cher ce soir ?',
        AppLocale.en => 'Who took the biggest hit tonight?',
        AppLocale.es => '¿Quién salió peor parado esta noche?',
      };

  String get todBackToHubButton => switch (locale) {
        AppLocale.fr => 'RETOUR AU HUB',
        AppLocale.en => 'BACK TO HUB',
        AppLocale.es => 'VOLVER AL HUB',
      };

  // ===========================================================================
  // NEVER HAVE I EVER (Je n'ai jamais) - LOBBY
  // ===========================================================================

  String get nhieSelectCategoryError => switch (locale) {
        AppLocale.fr => 'Sélectionne au moins une catégorie !',
        AppLocale.en => 'Select at least one category!',
        AppLocale.es => '¡Selecciona al menos una categoría!',
      };

  String get nhieRaceDistanceTitle => switch (locale) {
        AppLocale.fr => 'DISTANCE DE LA COURSE',
        AppLocale.en => 'RACE DISTANCE',
        AppLocale.es => 'DISTANCIA DE LA CARRERA',
      };

  String get nhieClassicLabel => switch (locale) {
        AppLocale.fr => 'CLASSIQUE',
        AppLocale.en => 'CLASSIC',
        AppLocale.es => 'CLÁSICA',
      };

  String get nhieCustomLabel => switch (locale) {
        AppLocale.fr => 'MODULABLE',
        AppLocale.en => 'CUSTOM',
        AppLocale.es => 'PERSONALIZADA',
      };

  String nhiePointsText(int points) => switch (locale) {
        AppLocale.fr => '$points points',
        AppLocale.en => '$points points',
        AppLocale.es => '$points puntos',
      };

  String get nhiePointsRange => switch (locale) {
        AppLocale.fr => '5 à 25 pts',
        AppLocale.en => '5 to 25 pts',
        AppLocale.es => '5 a 25 pts',
      };

  String nhiePointsBadge(int points) => '$points PTS';

  String get nhieHotPackTitle => switch (locale) {
        AppLocale.fr => 'Pack Hot & Piquant',
        AppLocale.en => 'Hot & Spicy Pack',
        AppLocale.es => 'Pack Hot & Picante',
      };

  String nhieStartRaceButton(int targetScore) => switch (locale) {
        AppLocale.fr => 'LANCER LA COURSE ($targetScore PTS)',
        AppLocale.en => 'START THE RACE ($targetScore PTS)',
        AppLocale.es => 'EMPEZAR CARRERA ($targetScore PTS)',
      };

  // ===========================================================================
  // NEVER HAVE I EVER (Je n'ai jamais) - GAME
  // ===========================================================================

  String nhieFinishBanner(int targetScore) => switch (locale) {
        AppLocale.fr => 'ARRIVÉE • $targetScore PTS',
        AppLocale.en => 'FINISH • $targetScore PTS',
        AppLocale.es => 'META • $targetScore PTS',
      };

  String get nhieCardHeaderTitle => switch (locale) {
        AppLocale.fr => "JE N'AI JAMAIS...",
        AppLocale.en => 'NEVER HAVE I EVER...',
        AppLocale.es => 'YO NUNCA...',
      };

  String nhieStatusText(int selectedCount) {
    if (selectedCount == 0) {
      return switch (locale) {
        AppLocale.fr => "Appuie sur ton couloir si tu l'as déjà fait 👇",
        AppLocale.en => 'Tap your lane if you have done it 👇',
        AppLocale.es => 'Toca tu carril si ya lo has hecho 👇',
      };
    }
    if (selectedCount == 1) {
      return switch (locale) {
        AppLocale.fr => "1 joueur avoue, avance d'une case et boit ! 🍺",
        AppLocale.en => '1 player confesses, moves forward and drinks! 🍺',
        AppLocale.es => '¡1 jugador confiesa, avanza una casilla y bebe! 🍺',
      };
    }
    return switch (locale) {
      AppLocale.fr =>
        '$selectedCount joueurs avouent, avancent et trinquent ! 🍻',
      AppLocale.en => '$selectedCount players confess, advance and cheers! 🍻',
      AppLocale.es =>
        '¡$selectedCount jugadores confiesan, avanzan y brindan! 🍻',
    };
  }

  String nhieActionButtonLabel(int selectedCount, bool willSomeoneWin) {
    if (willSomeoneWin) {
      return switch (locale) {
        AppLocale.fr => "FRANCHIR L'ARRIVÉE 🏆 ($selectedCount)",
        AppLocale.en => 'CROSS THE FINISH 🏆 ($selectedCount)',
        AppLocale.es => 'CRUZAR LA META 🏆 ($selectedCount)',
      };
    }
    if (selectedCount > 0) {
      return switch (locale) {
        AppLocale.fr => 'TRINQUER & AVANCER ($selectedCount) 🍻',
        AppLocale.en => 'CHEERS & ADVANCE ($selectedCount) 🍻',
        AppLocale.es => 'BRINDAR Y AVANZAR ($selectedCount) 🍻',
      };
    }
    return switch (locale) {
      AppLocale.fr => 'PASSER LA CARTE 😇 →',
      AppLocale.en => 'SKIP CARD 😇 →',
      AppLocale.es => 'PASAR CARTA 😇 →',
    };
  }

  String get nhieUndoTooltip => switch (locale) {
        AppLocale.fr => 'Annuler le tour précédent',
        AppLocale.en => 'Undo previous turn',
        AppLocale.es => 'Deshacer turno anterior',
      };

  String get nhieRaceAppBarTitle => switch (locale) {
        AppLocale.fr => 'HIPPODROME NÉON',
        AppLocale.en => 'NEON RACECOURSE',
        AppLocale.es => 'HIPÓDROMO NEÓN',
      };

  String get nhieRulesTooltip => switch (locale) {
        AppLocale.fr => 'Règles du jeu',
        AppLocale.en => 'Game rules',
        AppLocale.es => 'Reglas del juego',
      };

  // ===========================================================================
  // NEVER HAVE I EVER (Je n'ai jamais) - SCOREBOARD
  // ===========================================================================

  String nhiePlayerTitle(int score, int maxScore, int minScore, int targetScore) {
    if (score == maxScore && maxScore > 0) {
      return switch (locale) {
        AppLocale.fr => 'Légende Vivante 🏆',
        AppLocale.en => 'Living Legend 🏆',
        AppLocale.es => 'Leyenda Viva 🏆',
      };
    }
    if (score == 0 || (score == minScore && maxScore > minScore)) {
      return switch (locale) {
        AppLocale.fr => 'Ange Gardien 😇',
        AppLocale.en => 'Guardian Angel 😇',
        AppLocale.es => 'Ángel Guardián 😇',
      };
    }
    final double ratio = targetScore > 0 ? (score / targetScore) : 0.5;
    if (ratio >= 0.7) {
      return switch (locale) {
        AppLocale.fr => 'Pur-Sang Déchaîné 🔥',
        AppLocale.en => 'Unleashed Thoroughbred 🔥',
        AppLocale.es => 'Pura Sangre Desatado 🔥',
      };
    }
    return switch (locale) {
      AppLocale.fr => "Galop d'Essai 🐎",
      AppLocale.en => 'Trial Gallop 🐎',
      AppLocale.es => 'Galope de Prueba 🐎',
    };
  }

  String get nhiePodiumAppBarTitle => switch (locale) {
        AppLocale.fr => 'PODIUM DE LA COURSE',
        AppLocale.en => 'RACE PODIUM',
        AppLocale.es => 'PODIO DE LA CARRERA',
      };

  String nhieRaceBannerTitle(bool isPhotoFinish) {
    if (isPhotoFinish) {
      return switch (locale) {
        AppLocale.fr => 'PHOTO-FINISH !',
        AppLocale.en => 'PHOTO FINISH!',
        AppLocale.es => '¡FOTO FINISH!',
      };
    }
    return switch (locale) {
      AppLocale.fr => 'ARRIVÉE FRANCHIE !',
      AppLocale.en => 'FINISH LINE CROSSED!',
      AppLocale.es => '¡META CRUZADA!',
    };
  }

  String nhieWinnerHeader(bool isPhotoFinish) {
    if (isPhotoFinish) {
      return switch (locale) {
        AppLocale.fr => 'CHAMPIONS EX-AEQUO',
        AppLocale.en => 'TIED CHAMPIONS',
        AppLocale.es => 'CAMPEONES EMPATADOS',
      };
    }
    return switch (locale) {
      AppLocale.fr => 'GRAND VAINQUEUR DE LA SOIRÉE',
      AppLocale.en => 'GRAND WINNER OF THE NIGHT',
      AppLocale.es => 'GRAN GANADOR DE LA NOCHE',
    };
  }

  String nhieWinnerSubtitle(bool isPhotoFinish, int maxScore) {
    if (isPhotoFinish) {
      return switch (locale) {
        AppLocale.fr =>
          'Avec $maxScore aveux chacun, vous avez vécu mille vies ! 🍻',
        AppLocale.en =>
          'With $maxScore confessions each, you have lived a thousand lives! 🍻',
        AppLocale.es =>
          '¡Con $maxScore confesiones cada uno, habéis vivido mil vidas! 🍻',
      };
    }
    return switch (locale) {
      AppLocale.fr =>
        "Avec $maxScore aveux au compteur, rien ne t'arrête ! 🍻",
      AppLocale.en =>
        'With $maxScore confessions on the board, nothing can stop you! 🍻',
      AppLocale.es =>
        '¡Con $maxScore confesiones en tu marcador, nada te detiene! 🍻',
    };
  }

  String get nhieStandingsHeader => switch (locale) {
        AppLocale.fr => "CLASSEMENT DE L'HIPPODROME",
        AppLocale.en => 'RACECOURSE STANDINGS',
        AppLocale.es => 'CLASIFICACIÓN DEL HIPÓDROMO',
      };

  String nhiePointsShort(int score) => '$score pt${score > 1 ? 's' : ''}';

  String get nhieMenuButton => switch (locale) {
        AppLocale.fr => 'MENU',
        AppLocale.en => 'MENU',
        AppLocale.es => 'MENÚ',
      };

  String get nhieReplayButton => switch (locale) {
        AppLocale.fr => 'REJOUER',
        AppLocale.en => 'PLAY AGAIN',
        AppLocale.es => 'VOLVER A JUGAR',
      };
}
