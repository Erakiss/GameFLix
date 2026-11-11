// lib/l10n/strings_wyr_viper.dart
import 'package:gameflix/games/viper/viper_game.dart';
import 'package:gameflix/l10n/app_strings.dart';
import 'package:gameflix/l10n/locale_controller.dart';

/// Traductions FR / EN / ES pour les jeux "Tu préfères" (WYR) et "Viper".
extension WyrViperStrings on AppStrings {
  // --- WOULD YOU RATHER : LOBBY ---

  String get wyrSelectCategoryError => switch (locale) {
        AppLocale.fr => 'Sélectionne au moins une catégorie !',
        AppLocale.en => 'Select at least one category!',
        AppLocale.es => '¡Selecciona al menos una categoría!',
      };

  String get wyrGameLengthTitle => switch (locale) {
        AppLocale.fr => 'DURÉE DE LA PARTIE',
        AppLocale.en => 'GAME LENGTH',
        AppLocale.es => 'DURACIÓN DE LA PARTIDA',
      };

  String get wyrLengthExpress => switch (locale) {
        AppLocale.fr => 'Express',
        AppLocale.en => 'Express',
        AppLocale.es => 'Exprés',
      };

  String get wyrLengthStandard => switch (locale) {
        AppLocale.fr => 'Standard',
        AppLocale.en => 'Standard',
        AppLocale.es => 'Estándar',
      };

  String get wyrLengthIntense => switch (locale) {
        AppLocale.fr => 'Intense',
        AppLocale.en => 'Intense',
        AppLocale.es => 'Intenso',
      };

  String get wyrLengthAll => switch (locale) {
        AppLocale.fr => 'Tout',
        AppLocale.en => 'All',
        AppLocale.es => 'Todo',
      };

  String get wyrHotPackTitle => switch (locale) {
        AppLocale.fr => 'Pack Hot & Piquant',
        AppLocale.en => 'Hot & Spicy Pack',
        AppLocale.es => 'Pack Hot & Picante',
      };

  String get wyrStartGameButton => switch (locale) {
        AppLocale.fr => 'LANCER LE JEU',
        AppLocale.en => 'START GAME',
        AppLocale.es => 'EMPEZAR EL JUEGO',
      };

  // --- WOULD YOU RATHER : GAME ---

  String get wyrLiveScoresTitle => switch (locale) {
        AppLocale.fr => 'SCORES EN DIRECT',
        AppLocale.en => 'LIVE SCORES',
        AppLocale.es => 'PUNTUACIONES EN VIVO',
      };

  String get wyrLiveScoresSubtitle => switch (locale) {
        AppLocale.fr => 'Le joueur avec le plus de points boira le shot final !',
        AppLocale.en => 'The player with the most points will take the final shot!',
        AppLocale.es => '¡El jugador con más puntos se tomará el chupito final!',
      };

  String get wyrLiveScoresTooltip => switch (locale) {
        AppLocale.fr => 'Classement en direct',
        AppLocale.en => 'Live leaderboard',
        AppLocale.es => 'Clasificación en vivo',
      };

  String get wyrQuitDialogTitle => switch (locale) {
        AppLocale.fr => 'Quitter la partie ?',
        AppLocale.en => 'Quit the game?',
        AppLocale.es => '¿Salir de la partida?',
      };

  String get wyrQuitDialogBody => switch (locale) {
        AppLocale.fr =>
          'La progression et les pénalités de cette manche seront perdues.',
        AppLocale.en => 'Progress and penalties from this round will be lost.',
        AppLocale.es =>
          'Se perderán el progreso y las penalizaciones de esta ronda.',
      };

  String get wyrContinueButton => switch (locale) {
        AppLocale.fr => 'CONTINUER',
        AppLocale.en => 'CONTINUE',
        AppLocale.es => 'CONTINUAR',
      };

  String get wyrQuitButton => switch (locale) {
        AppLocale.fr => 'QUITTER',
        AppLocale.en => 'QUIT',
        AppLocale.es => 'SALIR',
      };

  String get wyrNoCards => switch (locale) {
        AppLocale.fr => 'Aucune carte',
        AppLocale.en => 'No cards available',
        AppLocale.es => 'No hay cartas disponibles',
      };

  String wyrRoundCounter(int current, int total) => switch (locale) {
        AppLocale.fr => 'MANCHE $current / $total',
        AppLocale.en => 'ROUND $current / $total',
        AppLocale.es => 'RONDA $current / $total',
      };

  String get wyrChoiceA => switch (locale) {
        AppLocale.fr => 'CHOIX A',
        AppLocale.en => 'CHOICE A',
        AppLocale.es => 'OPCIÓN A',
      };

  String get wyrChoiceB => switch (locale) {
        AppLocale.fr => 'CHOIX B',
        AppLocale.en => 'CHOICE B',
        AppLocale.es => 'OPCIÓN B',
      };

  String get wyrShameBadge => switch (locale) {
        AppLocale.fr => '💀 CHOIX DE LA HONTE (<35%) • +1 PT MALUS',
        AppLocale.en => '💀 CHOICE OF SHAME (<35%) • +1 PT PENALTY',
        AppLocale.es => '💀 ELECCIÓN DE LA VERGÜENZA (<35%) • +1 PT PENALIZACIÓN',
      };

  String get wyrWorldLabel => switch (locale) {
        AppLocale.fr => 'MONDE',
        AppLocale.en => 'WORLD',
        AppLocale.es => 'MUNDO',
      };

  String wyrMiniDareBanner(String miniGage) => switch (locale) {
        AppLocale.fr => 'MINI-GAGE : $miniGage',
        AppLocale.en => 'MINI-DARE: $miniGage',
        AppLocale.es => 'MINI-RETO: $miniGage',
      };

  String get wyrVoteHint => switch (locale) {
        AppLocale.fr => 'Votez à main levée à la table !',
        AppLocale.en => 'Vote by raising hands at the table!',
        AppLocale.es => '¡Votad a mano alzada en la mesa!',
      };

  String get wyrRevealButton => switch (locale) {
        AppLocale.fr => 'RÉVÉLER LES POURCENTAGES',
        AppLocale.en => 'REVEAL PERCENTAGES',
        AppLocale.es => 'REVELAR PORCENTAJES',
      };

  String wyrMinorityPrompt(bool hasShameOption) => hasShameOption
      ? switch (locale) {
          AppLocale.fr => 'QUI EST EN MINORITÉ ? (+2 pts, tap = +3 si honte)',
          AppLocale.en => "WHO'S IN THE MINORITY? (+2 pts, tap = +3 if shame)",
          AppLocale.es =>
            '¿QUIÉN ESTÁ EN MINORÍA? (+2 pts, toca = +3 si vergüenza)',
        }
      : switch (locale) {
          AppLocale.fr => 'QUI EST EN MINORITÉ ? (+2 pts)',
          AppLocale.en => "WHO'S IN THE MINORITY? (+2 pts)",
          AppLocale.es => '¿QUIÉN ESTÁ EN MINORÍA? (+2 pts)',
        };

  String get wyrViewHallOfShame => switch (locale) {
        AppLocale.fr => 'VOIR LE HALL OF SHAME 💀',
        AppLocale.en => 'VIEW HALL OF SHAME 💀',
        AppLocale.es => 'VER EL HALL OF SHAME 💀',
      };

  String get wyrNextDilemma => switch (locale) {
        AppLocale.fr => 'DILEMME SUIVANT ➔',
        AppLocale.en => 'NEXT DILEMMA ➔',
        AppLocale.es => 'SIGUIENTE DILEMA ➔',
      };

  // --- WOULD YOU RATHER : SCOREBOARD ---

  String get wyrScoreboardAppBarTitle => switch (locale) {
        AppLocale.fr => 'RÉSULTATS DE LA SOIRÉE',
        AppLocale.en => "TONIGHT'S RESULTS",
        AppLocale.es => 'RESULTADOS DE LA NOCHE',
      };

  String get wyrHallOfShameTitle => switch (locale) {
        AppLocale.fr => '💀 HALL OF SHAME 💀',
        AppLocale.en => '💀 HALL OF SHAME 💀',
        AppLocale.es => '💀 HALL OF SHAME 💀',
      };

  String get wyrHallOfShameSubtitle => switch (locale) {
        AppLocale.fr => 'Qui a les goûts les plus impardonnables de la table ?',
        AppLocale.en => 'Who has the most unforgivable tastes at the table?',
        AppLocale.es => '¿Quién tiene los gustos más imperdonables de la mesa?',
      };

  String get wyrBiggestLoserLabel => switch (locale) {
        AppLocale.fr => 'LE GRAND PERDANT',
        AppLocale.en => 'THE BIGGEST LOSER',
        AppLocale.es => 'EL GRAN PERDEDOR',
      };

  String wyrPenaltyPoints(int score) => switch (locale) {
        AppLocale.fr => '$score points de pénalité',
        AppLocale.en => '$score penalty points',
        AppLocale.es => '$score puntos de penalización',
      };

  String wyrSentenceShots(int shots) => shots > 0
      ? switch (locale) {
          AppLocale.fr => "🥃 SENTENCE : $shots SHOT${shots > 1 ? 'S' : ''} !",
          AppLocale.en => "🥃 SENTENCE: $shots SHOT${shots > 1 ? 'S' : ''}!",
          AppLocale.es =>
            "🥃 SENTENCIA: ¡$shots CHUPITO${shots > 1 ? 'S' : ''}!",
        }
      : switch (locale) {
          AppLocale.fr => '🎉 AUCUN SHOT À BOIRE !',
          AppLocale.en => '🎉 NO SHOTS TO DRINK!',
          AppLocale.es => '🎉 ¡NINGÚN CHUPITO QUE BEBER!',
        };

  String wyrVerdictMessage(int shots, int score) {
    if (score == 0) {
      return switch (locale) {
        AppLocale.fr => "Miracle absolu ! Personne n'a pris de points 🎉",
        AppLocale.en => 'Absolute miracle! Nobody got any points 🎉',
        AppLocale.es => '¡Milagro absoluto! Nadie sumó puntos 🎉',
      };
    }
    if (shots == 1) {
      return switch (locale) {
        AppLocale.fr => 'Ça passe encore... mais santé quand même ! 🍻',
        AppLocale.en => 'Could be worse... cheers anyway! 🍻',
        AppLocale.es => 'No está tan mal... ¡salud de todos modos! 🍻',
      };
    }
    if (shots == 2) {
      return switch (locale) {
        AppLocale.fr => 'Deux shots bien mérités pour tes goûts douteux ! 💀',
        AppLocale.en => 'Two well-deserved shots for your questionable taste! 💀',
        AppLocale.es =>
          '¡Dos chupitos bien merecidos por tus gustos dudosos! 💀',
      };
    }
    if (shots == 3) {
      return switch (locale) {
        AppLocale.fr =>
          'Trois shots ! La table ne te fait plus confiance... 🔥',
        AppLocale.en => "Three shots! The table doesn't trust you anymore... 🔥",
        AppLocale.es => '¡Tres chupitos! La mesa ya no confía en ti... 🔥',
      };
    }
    return switch (locale) {
      AppLocale.fr =>
        "$shots shots ! Préparez le verre d'eau et appelez un taxi 🚑",
      AppLocale.en => '$shots shots! Grab a glass of water and call a cab 🚑',
      AppLocale.es =>
        '¡$shots chupitos! Preparad un vaso de agua y llamad a un taxi 🚑',
    };
  }

  String wyrPlayerStatus(int score, int minScore, int maxScore) {
    if (score == minScore) {
      return switch (locale) {
        AppLocale.fr => 'Le Propre 😇 (Gagnant)',
        AppLocale.en => 'The Innocent 😇 (Winner)',
        AppLocale.es => 'El Inocente 😇 (Ganador)',
      };
    }
    if (score == maxScore) {
      return switch (locale) {
        AppLocale.fr => 'Le Condamné 💀 (Grand perdant)',
        AppLocale.en => 'The Condemned 💀 (Biggest loser)',
        AppLocale.es => 'El Condenado 💀 (Gran perdedor)',
      };
    }
    if (score - minScore <= 2) {
      return switch (locale) {
        AppLocale.fr => 'À deux doigts du désastre 😅',
        AppLocale.en => 'Inches away from disaster 😅',
        AppLocale.es => 'A un pelo del desastre 😅',
      };
    }
    return switch (locale) {
      AppLocale.fr => 'Dans la tourmente 😬',
      AppLocale.en => 'In hot water 😬',
      AppLocale.es => 'En la tormenta 😬',
    };
  }

  String get wyrTableStandingsTitle => switch (locale) {
        AppLocale.fr => 'CLASSEMENT DE LA TABLE',
        AppLocale.en => 'TABLE STANDINGS',
        AppLocale.es => 'CLASIFICACIÓN DE LA MESA',
      };

  String wyrPlayersCount(int count) => switch (locale) {
        AppLocale.fr => '$count joueurs',
        AppLocale.en => '$count players',
        AppLocale.es => '$count jugadores',
      };

  String get replayButton => switch (locale) {
        AppLocale.fr => 'REJOUER',
        AppLocale.en => 'PLAY AGAIN',
        AppLocale.es => 'REJUGAR',
      };

  String get hubButton => 'HUB';

  // --- VIPER : MODES & AMBIANCES ---

  String viperModeLabel(ViperBoardMode mode) => switch (mode) {
        ViperBoardMode.express => switch (locale) {
            AppLocale.fr => 'MODE EXPRESS',
            AppLocale.en => 'EXPRESS MODE',
            AppLocale.es => 'MODO EXPRÉS',
          },
        ViperBoardMode.normal => switch (locale) {
            AppLocale.fr => 'MODE NORMAL',
            AppLocale.en => 'NORMAL MODE',
            AppLocale.es => 'MODO NORMAL',
          },
        ViperBoardMode.spiral => switch (locale) {
            AppLocale.fr => 'MODE SPIRALE',
            AppLocale.en => 'SPIRAL MODE',
            AppLocale.es => 'MODO ESPIRAL',
          },
      };

  String viperModeSubtitle(ViperBoardMode mode) => switch (mode) {
        ViperBoardMode.express => switch (locale) {
            AppLocale.fr => 'Rapide & Intense',
            AppLocale.en => 'Fast & Intense',
            AppLocale.es => 'Rápido e Intenso',
          },
        ViperBoardMode.normal => switch (locale) {
            AppLocale.fr => 'Parcours Classique',
            AppLocale.en => 'Classic Course',
            AppLocale.es => 'Recorrido Clásico',
          },
        ViperBoardMode.spiral => switch (locale) {
            AppLocale.fr => '+ de Hasard !',
            AppLocale.en => 'More Chaos!',
            AppLocale.es => '¡Más Azar!',
          },
      };

  String viperMoodLabel(ViperDeckMood mood) => switch (mood) {
        ViperDeckMood.classic => switch (locale) {
            AppLocale.fr => 'CLASSIQUE',
            AppLocale.en => 'CLASSIC',
            AppLocale.es => 'CLÁSICO',
          },
        ViperDeckMood.hot => 'HOT 🌶️',
        ViperDeckMood.blackout => 'BLACK OUT',
      };

  String viperMoodSubtitle(ViperDeckMood mood) => switch (mood) {
        ViperDeckMood.classic => switch (locale) {
            AppLocale.fr => 'Mix équilibré',
            AppLocale.en => 'Balanced mix',
            AppLocale.es => 'Mezcla equilibrada',
          },
        ViperDeckMood.hot => switch (locale) {
            AppLocale.fr => 'Vérités & Défis osés',
            AppLocale.en => 'Bold truths & dares',
            AppLocale.es => 'Verdades y Retos atrevidos',
          },
        ViperDeckMood.blackout => switch (locale) {
            AppLocale.fr => 'Gorgées & Chaos',
            AppLocale.en => 'Sips & Chaos',
            AppLocale.es => 'Tragos y Caos',
          },
      };

  // --- VIPER : LOBBY ---

  String get viperHotPackTitle => switch (locale) {
        AppLocale.fr => 'Ambiance Hot & Spicy',
        AppLocale.en => 'Hot & Spicy Vibe',
        AppLocale.es => 'Ambiente Hot & Picante',
      };

  String get viperGameModeSection => switch (locale) {
        AppLocale.fr => 'MODE DE JEU',
        AppLocale.en => 'GAME MODE',
        AppLocale.es => 'MODO DE JUEGO',
      };

  String get viperDeckMoodSection => switch (locale) {
        AppLocale.fr => 'AMBIANCE DU DECK',
        AppLocale.en => 'DECK VIBE',
        AppLocale.es => 'AMBIENTE DEL MAZO',
      };

  String get viperStartGameButton => switch (locale) {
        AppLocale.fr => 'LANCER LA PARTIE',
        AppLocale.en => 'START GAME',
        AppLocale.es => 'EMPEZAR PARTIDA',
      };

  // --- VIPER : GAME ---

  String get viperErrorTitle => switch (locale) {
        AppLocale.fr => 'ERREUR',
        AppLocale.en => 'ERROR',
        AppLocale.es => 'ERROR',
      };

  String get viperErrorDescription => switch (locale) {
        AppLocale.fr => 'Vérifie viper_card.json',
        AppLocale.en => 'Check viper_card.json',
        AppLocale.es => 'Comprueba viper_card.json',
      };

  String get viperTileStart => switch (locale) {
        AppLocale.fr => 'START!',
        AppLocale.en => 'START!',
        AppLocale.es => 'INICIO',
      };

  String get viperTileVictory => switch (locale) {
        AppLocale.fr => 'VICTOIRE',
        AppLocale.en => 'VICTORY',
        AppLocale.es => 'VICTORIA',
      };

  String viperTileConnectorUp(bool isSpiral) => isSpiral
      ? switch (locale) {
          AppLocale.fr => 'PORTAIL +',
          AppLocale.en => 'PORTAL +',
          AppLocale.es => 'PORTAL +',
        }
      : switch (locale) {
          AppLocale.fr => 'LADDER',
          AppLocale.en => 'LADDER',
          AppLocale.es => 'ESCALERA',
        };

  String viperTileConnectorDown(bool isSpiral) => isSpiral
      ? switch (locale) {
          AppLocale.fr => 'PORTAIL -',
          AppLocale.en => 'PORTAL -',
          AppLocale.es => 'PORTAL -',
        }
      : switch (locale) {
          AppLocale.fr => 'SNAKE',
          AppLocale.en => 'SNAKE',
          AppLocale.es => 'SERPIENTE',
        };

  String get viperTileArrival => switch (locale) {
        AppLocale.fr => 'ARRIVÉE',
        AppLocale.en => 'LANDING',
        AppLocale.es => 'LLEGADA',
      };

  String get viperTileSpecial => 'GLITCH';

  String get viperTileSpicy => switch (locale) {
        AppLocale.fr => 'SPICY',
        AppLocale.en => 'SPICY',
        AppLocale.es => 'PICANTE',
      };

  String get viperTileDrink => switch (locale) {
        AppLocale.fr => 'DRINK',
        AppLocale.en => 'DRINK',
        AppLocale.es => 'TRAGO',
      };

  String get viperTileQuestion => switch (locale) {
        AppLocale.fr => 'TRUTH',
        AppLocale.en => 'TRUTH',
        AppLocale.es => 'VERDAD',
      };

  String get viperTileAction => switch (locale) {
        AppLocale.fr => 'DARE',
        AppLocale.en => 'DARE',
        AppLocale.es => 'RETO',
      };

  String viperUpCardTitle(bool isSpiral) => isSpiral
      ? switch (locale) {
          AppLocale.fr => 'PORTAIL UP !',
          AppLocale.en => 'PORTAL UP!',
          AppLocale.es => '¡PORTAL UP!',
        }
      : switch (locale) {
          AppLocale.fr => 'GIFT A SHOT & MOVE UP!',
          AppLocale.en => 'GIFT A SHOT & MOVE UP!',
          AppLocale.es => '¡REGALA UN TRAGO Y SUBE!',
        };

  String viperUpCardDesc(bool isSpiral) => isSpiral
      ? switch (locale) {
          AppLocale.fr =>
            "Offre 1 gorgée (ou donne un mini-gage) au joueur de ton choix et franchis le portail vers l'anneau intérieur !",
          AppLocale.en =>
            'Give 1 sip (or a mini-dare) to any player of your choice and step through the portal to the inner ring!',
          AppLocale.es =>
            '¡Regala 1 trago (o un mini-reto) al jugador que elijas y cruza el portal hacia el anillo interior!',
        }
      : switch (locale) {
          AppLocale.fr =>
            'Offre 1 gorgée (ou donne un mini-gage) au joueur de ton choix et grimpe vers le haut !',
          AppLocale.en =>
            'Give 1 sip (or a mini-dare) to any player of your choice and climb up!',
          AppLocale.es =>
            '¡Regala 1 trago (o un mini-reto) al jugador que elijas y sube por la escalera!',
        };

  String viperShieldBlockedBanner(bool isSpiral) => isSpiral
      ? switch (locale) {
          AppLocale.fr => '🌀 BOUCLIER : TÉLÉPORTATION ANNULÉE !',
          AppLocale.en => '🌀 SHIELD: TELEPORT CANCELLED!',
          AppLocale.es => '🌀 ESCUDO: ¡TELETRANSPORTE ANULADO!',
        }
      : switch (locale) {
          AppLocale.fr => '🧪 ANTI-VENIN : DESCENTE ANNULÉE !',
          AppLocale.en => '🧪 ANTI-VENOM: SLIDE CANCELLED!',
          AppLocale.es => '🧪 ANTIVENENO: ¡BAJADA ANULADA!',
        };

  String viperDownCardTitle(bool isSpiral) => isSpiral
      ? switch (locale) {
          AppLocale.fr => 'PORTAIL DOWN !',
          AppLocale.en => 'PORTAL DOWN!',
          AppLocale.es => '¡PORTAL DOWN!',
        }
      : switch (locale) {
          AppLocale.fr => 'TAKE A SHOT & SLIDE!',
          AppLocale.en => 'TAKE A SHOT & SLIDE!',
          AppLocale.es => '¡BEBE UN TRAGO Y BAJA!',
        };

  String viperDownCardDesc(bool isSpiral) => isSpiral
      ? switch (locale) {
          AppLocale.fr =>
            "Bois 1 gorgée (ou accomplis un gage choisi par la table) : aspiré par le vortex vers l'anneau extérieur !",
          AppLocale.en =>
            'Drink 1 sip (or complete a dare chosen by the table): sucked into the vortex to the outer ring!',
          AppLocale.es =>
            'Bebe 1 trago (o cumple un reto elegido por la mesa): ¡absorbido por el vórtice hacia el anillo exterior!',
        }
      : switch (locale) {
          AppLocale.fr =>
            'Bois 1 gorgée (ou accomplis un gage choisi par la table) et redescends dans les profondeurs !',
          AppLocale.en =>
            'Drink 1 sip (or complete a dare chosen by the table) and slide back down into the depths!',
          AppLocale.es =>
            '¡Bebe 1 trago (o cumple un reto elegido por la mesa) y deslízate hacia las profundidades!',
        };

  String get viperDoubleTurnBanner => switch (locale) {
        AppLocale.fr => '🎲 DOUBLE TOUR : RELANCE LE DÉ !',
        AppLocale.en => '🎲 DOUBLE TURN: ROLL AGAIN!',
        AppLocale.es => '🎲 DOBLE TURNO: ¡TIRA EL DADO DE NUEVO!',
      };

  String get viperAntiVenomActivatedBanner => switch (locale) {
        AppLocale.fr => '🧪 SÉRUM ANTI-VENIN ACTIVÉ !',
        AppLocale.en => '🧪 ANTI-VENOM SERUM ACTIVATED!',
        AppLocale.es => '🧪 ¡SUERO ANTIVENENO ACTIVADO!',
      };

  String get viperAddPlayersMessage => switch (locale) {
        AppLocale.fr => 'Ajoute des joueurs !',
        AppLocale.en => 'Add players!',
        AppLocale.es => '¡Añade jugadores!',
      };

  String viperTransitionBanner(String playerName) => switch (locale) {
        AppLocale.fr => 'À ${playerName.toUpperCase()} !',
        AppLocale.en => "${playerName.toUpperCase()}'S TURN!",
        AppLocale.es => '¡TURNO DE ${playerName.toUpperCase()}!',
      };

  String viperPlayerTurnLabel(String playerName) => switch (locale) {
        AppLocale.fr => 'Tour de $playerName',
        AppLocale.en => "$playerName's turn",
        AppLocale.es => 'Turno de $playerName',
      };

  String get viperRollingButton => switch (locale) {
        AppLocale.fr => 'EN COURS...',
        AppLocale.en => 'ROLLING...',
        AppLocale.es => 'EN CURSO...',
      };

  String get viperRollDiceButton => switch (locale) {
        AppLocale.fr => 'LANCER LE DÉ',
        AppLocale.en => 'ROLL THE DICE',
        AppLocale.es => 'TIRAR EL DADO',
      };

  // --- VIPER : SCOREBOARD ---

  String get viperGameOverTitle => switch (locale) {
        AppLocale.fr => 'FIN DE PARTIE',
        AppLocale.en => 'GAME OVER',
        AppLocale.es => 'FIN DE PARTIDA',
      };

  String get viperVictoryTitle => switch (locale) {
        AppLocale.fr => 'VICTOIRE !',
        AppLocale.en => 'VICTORY!',
        AppLocale.es => '¡VICTORIA!',
      };

  String viperTileNumber(int index) => switch (locale) {
        AppLocale.fr => 'Case $index',
        AppLocale.en => 'Tile $index',
        AppLocale.es => 'Casilla $index',
      };
}
