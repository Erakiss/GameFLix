// lib/l10n/strings_shared.dart
import 'package:gameflix/l10n/app_strings.dart';
import 'package:gameflix/l10n/locale_controller.dart';

/// Traductions FR / EN / ES pour les widgets partagés et les écrans du Hub.
extension SharedStrings on AppStrings {
  // --- UNLOCK PACK SHEET (PAYWALL) ---

  String unlockPackTitle(String packTitle) => switch (locale) {
        AppLocale.fr => 'DÉBLOQUER $packTitle'.toUpperCase(),
        AppLocale.en => 'UNLOCK $packTitle'.toUpperCase(),
        AppLocale.es => 'DESBLOQUEAR $packTitle'.toUpperCase(),
      };

  String get unlockPackSubtitle => switch (locale) {
        AppLocale.fr =>
          'Ce contenu Spicy est réservé aux membres VIP ou débloquable pour cette session de jeu !',
        AppLocale.en =>
          'This Spicy content is reserved for VIP members or unlockable for this game session!',
        AppLocale.es =>
          '¡Este contenido Spicy es exclusivo para miembros VIP o desbloqueable para esta sesión de juego!',
      };

  String get rewardedAdLoadingMessage => switch (locale) {
        AppLocale.fr => 'Chargement de la vidéo récompensée... 🎬',
        AppLocale.en => 'Loading rewarded video... 🎬',
        AppLocale.es => 'Cargando el vídeo con recompensa... 🎬',
      };

  String get pass1hActivatedMessage => switch (locale) {
        AppLocale.fr =>
          '🔥 Pass Soirée 1H activé ! Tout est débloqué pendant 60 minutes !',
        AppLocale.en =>
          '🔥 1H Party Pass activated! Everything is unlocked for 60 minutes!',
        AppLocale.es =>
          '🔥 ¡Pase Fiesta 1H activado! ¡Todo desbloqueado durante 60 minutos!',
      };

  String get rewardedAdFailedMessage => switch (locale) {
        AppLocale.fr =>
          'Vidéo indisponible ou appareil hors-ligne. Réessaie dans un instant !',
        AppLocale.en =>
          'Video unavailable or device offline. Try again in a moment!',
        AppLocale.es =>
          'Vídeo no disponible o dispositivo sin conexión. ¡Inténtalo de nuevo en un momento!',
      };

  String get vipWelcomeMessage => switch (locale) {
        AppLocale.fr =>
          '👑 Bienvenue VIP ! Tous les packs sont débloqués et zéro pub !',
        AppLocale.en =>
          '👑 Welcome VIP! All packs are unlocked and zero ads!',
        AppLocale.es =>
          '👑 ¡Bienvenido VIP! ¡Todos los packs desbloqueados y cero anuncios!',
      };

  String get purchaseUnavailableMessage => switch (locale) {
        AppLocale.fr => 'Achat annulé ou indisponible.',
        AppLocale.en => 'Purchase cancelled or unavailable.',
        AppLocale.es => 'Compra cancelada o no disponible.',
      };

  String get unlockRestoreSuccessMessage => switch (locale) {
        AppLocale.fr => '✨ Achats restaurés avec succès !',
        AppLocale.en => '✨ Purchases successfully restored!',
        AppLocale.es => '✨ ¡Compras restauradas con éxito!',
      };

  String get pass1hUsedTitle => switch (locale) {
        AppLocale.fr => 'ESSAI 1H DÉJÀ UTILISÉ',
        AppLocale.en => '1H TRIAL ALREADY USED',
        AppLocale.es => 'PRUEBA 1H YA USADA',
      };

  String get pass1hUsedSubtitle => switch (locale) {
        AppLocale.fr => 'Offre unique par téléphone déjà consommée',
        AppLocale.en => 'One-time offer per device already redeemed',
        AppLocale.es => 'Oferta única por dispositivo ya consumida',
      };

  String get pass1hExpiredBadge => switch (locale) {
        AppLocale.fr => 'EXPIRÉ',
        AppLocale.en => 'EXPIRED',
        AppLocale.es => 'CADUCADO',
      };

  String get pass1hActiveTitle => switch (locale) {
        AppLocale.fr => 'PASS 1H ACTIF',
        AppLocale.en => '1H PASS ACTIVE',
        AppLocale.es => 'PASE 1H ACTIVO',
      };

  String pass1hActiveRemaining(int minutes) => switch (locale) {
        AppLocale.fr =>
          'Encore ~$minutes min de déblocage total pour la soirée !',
        AppLocale.en => '~$minutes min left of full unlock for the party!',
        AppLocale.es =>
          '¡Quedan ~$minutes min de desbloqueo total para la fiesta!',
      };

  String get pass1hFreeTitle => switch (locale) {
        AppLocale.fr => 'PASS SOIRÉE 1H GRATUIT',
        AppLocale.en => 'FREE 1H PARTY PASS',
        AppLocale.es => 'PASE FIESTA 1H GRATIS',
      };

  String get pass1hFreeSubtitle => switch (locale) {
        AppLocale.fr =>
          'Regarde 1 vidéo pour TOUT débloquer (Essai unique)',
        AppLocale.en => 'Watch 1 video to unlock EVERYTHING (One-time trial)',
        AppLocale.es => 'Mira 1 vídeo para desbloquear TODO (Prueba única)',
      };

  String get freeBadge => switch (locale) {
        AppLocale.fr => 'GRATUIT',
        AppLocale.en => 'FREE',
        AppLocale.es => 'GRATIS',
      };

  String get annualClubPassTitle => switch (locale) {
        AppLocale.fr => 'PASS ANNUEL CLUB',
        AppLocale.en => 'ANNUAL CLUB PASS',
        AppLocale.es => 'PASE ANUAL CLUB',
      };

  String get annualClubPassSubtitle => switch (locale) {
        AppLocale.fr => "Tous les jeux illimités & sans pub à l'année",
        AppLocale.en => 'All games unlimited & ad-free all year',
        AppLocale.es => 'Todos los juegos ilimitados y sin anuncios todo el año',
      };

  String get perYearLabel => switch (locale) {
        AppLocale.fr => '/ an',
        AppLocale.en => '/ year',
        AppLocale.es => '/ año',
      };

  String get weeklyPassTitle => switch (locale) {
        AppLocale.fr => 'PASS HEBDOMADAIRE',
        AppLocale.en => 'WEEKLY PASS',
        AppLocale.es => 'PASE SEMANAL',
      };

  String get weeklyPassSubtitle => switch (locale) {
        AppLocale.fr => 'Idéal pour animer votre soirée ce soir',
        AppLocale.en => 'Ideal to spice up your party tonight',
        AppLocale.es => 'Ideal para animar tu fiesta esta noche',
      };

  String get perWeekLabel => switch (locale) {
        AppLocale.fr => '/ semaine',
        AppLocale.en => '/ week',
        AppLocale.es => '/ semana',
      };

  String get laterButton => switch (locale) {
        AppLocale.fr => 'Plus tard',
        AppLocale.en => 'Later',
        AppLocale.es => 'Más tarde',
      };

  // --- HUB IN-WHEEL AD CARD ---

  String get vipAdFreePackTitle => switch (locale) {
        AppLocale.fr => 'PASS VIP / SANS PUB',
        AppLocale.en => 'VIP / AD-FREE PASS',
        AppLocale.es => 'PASE VIP / SIN ANUNCIOS',
      };

  String get sponsorSpaceTitle => switch (locale) {
        AppLocale.fr => 'ESPACE SPONSOR',
        AppLocale.en => 'SPONSOR SPACE',
        AppLocale.es => 'ESPACIO PATROCINADO',
      };

  String get sponsorSpaceSubtitle => switch (locale) {
        AppLocale.fr => 'Passez en VIP pour supprimer toutes les pubs 👑',
        AppLocale.en => 'Upgrade to VIP to remove all ads 👑',
        AppLocale.es => 'Pásate a VIP para eliminar todos los anuncios 👑',
      };

  String get adBadgeLabel => switch (locale) {
        AppLocale.fr => 'PUB',
        AppLocale.en => 'AD',
        AppLocale.es => 'ANUNCIO',
      };

  // --- PASS 1H COUNTDOWN BADGE ---

  String pass1hCountdownLabel(String minutes, String seconds) =>
      switch (locale) {
        AppLocale.fr => 'PASS 1H : $minutes:$seconds',
        AppLocale.en => '1H PASS: $minutes:$seconds',
        AppLocale.es => 'PASE 1H: $minutes:$seconds',
      };

  // --- HUB & SETTINGS REMAINING STRINGS ---

  String get proSpicyPackTitle => switch (locale) {
        AppLocale.fr => 'PASS PRO / SPICY',
        AppLocale.en => 'PRO / SPICY PASS',
        AppLocale.es => 'PASE PRO / SPICY',
      };

  String get gdprPrivacyPreferencesButton => switch (locale) {
        AppLocale.fr => 'Préférences de confidentialité (RGPD)',
        AppLocale.en => 'Privacy Preferences (GDPR)',
        AppLocale.es => 'Preferencias de privacidad (RGPD)',
      };

  // --- GAME RULES SHEET ---

  String get rulesObjectiveHeader => switch (locale) {
        AppLocale.fr => 'BUT DU JEU',
        AppLocale.en => 'GAME OBJECTIVE',
        AppLocale.es => 'OBJETIVO DEL JUEGO',
      };

  String get rulesHowToPlayHeader => switch (locale) {
        AppLocale.fr => 'COMMENT JOUER ?',
        AppLocale.en => 'HOW TO PLAY?',
        AppLocale.es => '¿CÓMO JUGAR?',
      };

  String get rulesEndConditionHeader => switch (locale) {
        AppLocale.fr => 'FIN DE PARTIE',
        AppLocale.en => 'END OF GAME',
        AppLocale.es => 'FIN DE LA PARTIDA',
      };

  // --- RÈGLES : ACTION OU VÉRITÉ (tod) ---

  String get todRulesObjective => switch (locale) {
        AppLocale.fr =>
          'Découvrir les secrets de tes potes ou relever des défis délirants sans te défiler.',
        AppLocale.en =>
          "Uncover your friends' secrets or take on wild dares without chickening out.",
        AppLocale.es =>
          'Descubre los secretos de tus amigos o supera retos locos sin echarte atrás.',
      };

  String get todStep1Title => switch (locale) {
        AppLocale.fr => '1. Choix du joueur',
        AppLocale.en => '1. Player Selection',
        AppLocale.es => '1. Elección del jugador',
      };

  String get todStep1Desc => switch (locale) {
        AppLocale.fr =>
          'Le jeu désigne le joueur actif. Choisis entre Vérité (honnêteté obligatoire) ou Action (gage à accomplir).',
        AppLocale.en =>
          'The game picks the active player. Choose between Truth (total honesty required) or Dare (challenge to complete).',
        AppLocale.es =>
          'El juego designa al jugador activo. Elige entre Verdad (honestidad obligatoria) o Reto (desafío a cumplir).',
      };

  String get todStep2Title => switch (locale) {
        AppLocale.fr => '2. Les catégories de cartes',
        AppLocale.en => '2. Card Categories',
        AppLocale.es => '2. Categorías de cartas',
      };

  String get todStep2Desc => switch (locale) {
        AppLocale.fr =>
          "SOFT pour démarrer tranquillement, FUN pour rigoler entre potes, et HOT pour chauffer l'ambiance.",
        AppLocale.en =>
          'SOFT to ease into it, FUN for laughs with friends, and HOT to turn up the heat.',
        AppLocale.es =>
          'SOFT para empezar tranquilo, FUN para reír con amigos y HOT para subir la temperatura.',
      };

  String get todStep3Title => switch (locale) {
        AppLocale.fr => '3. En cas de refus',
        AppLocale.en => '3. If You Refuse',
        AppLocale.es => '3. En caso de rechazo',
      };

  String get todStep3Desc => switch (locale) {
        AppLocale.fr =>
          "Si un joueur refuse catégoriquement d'accomplir son gage ou d'avouer la vérité, il prend une gorgée de pénalité !",
        AppLocale.en =>
          'If a player flat-out refuses to complete the dare or tell the truth, they take a penalty sip!',
        AppLocale.es =>
          'Si un jugador se niega rotundamente a cumplir el reto o decir la verdad, ¡toma un trago de penalización!',
      };

  String get todRulesEndCondition => switch (locale) {
        AppLocale.fr =>
          "Jouez autant de tours que vous voulez. La partie s'arrête quand la table n'a plus de secrets !",
        AppLocale.en =>
          'Play as many rounds as you want. The game ends when the table has no secrets left!',
        AppLocale.es =>
          'Juega tantas rondas como quieras. ¡La partida termina cuando la mesa ya no tenga secretos!',
      };

  // --- RÈGLES : JE N'AI JAMAIS (nhie) ---

  String get nhieRulesObjective => switch (locale) {
        AppLocale.fr =>
          "Être le premier joueur à franchir la ligne d'arrivée en ayant déjà fait ce qui est annoncé !",
        AppLocale.en =>
          'Be the first player to cross the finish line by having already done what is announced!',
        AppLocale.es =>
          '¡Ser el primer jugador en cruzar la meta por haber hecho ya lo que se anuncia!',
      };

  String get nhieStep1Title => switch (locale) {
        AppLocale.fr => '1. Annonce de la phrase',
        AppLocale.en => '1. Read the Statement',
        AppLocale.es => '1. Lectura de la frase',
      };

  String get nhieStep1Desc => switch (locale) {
        AppLocale.fr =>
          'Une affirmation commence toujours par "Je n\'ai jamais...". Lis-la à voix haute pour tout le monde.',
        AppLocale.en =>
          'Each prompt starts with "Never have I ever...". Read it out loud for everyone.',
        AppLocale.es =>
          'Cada frase empieza con "Yo nunca...". Léela en voz alta para todo el grupo.',
      };

  String get nhieStep2Title => switch (locale) {
        AppLocale.fr => '2. Avance ou reste sur place',
        AppLocale.en => '2. Move Forward or Stay',
        AppLocale.es => '2. Avanza o quédate quieto',
      };

  String get nhieStep2Desc => switch (locale) {
        AppLocale.fr =>
          "Tous les joueurs qui ont DÉJÀ fait l'action annoncée avancent d'une case dans leur couloir de course.",
        AppLocale.en =>
          'Every player who HAS already done the stated action moves forward one space in their race lane.',
        AppLocale.es =>
          'Todos los jugadores que YA hayan hecho la acción anunciada avanzan una casilla en su carril.',
      };

  String get nhieStep3Title => switch (locale) {
        AppLocale.fr => '3. Solidarité & Gorgée',
        AppLocale.en => '3. Solidarity & Sip',
        AppLocale.es => '3. Solidaridad y trago',
      };

  String get nhieStep3Desc => switch (locale) {
        AppLocale.fr =>
          'Ceux qui avancent assument leurs bêtises et trinquent tous ensemble !',
        AppLocale.en =>
          'Those who move forward own up to their deeds and drink together!',
        AppLocale.es =>
          '¡Los que avanzan asumen sus travesuras y brindan juntos!',
      };

  String get nhieRulesEndCondition => switch (locale) {
        AppLocale.fr =>
          'Le premier joueur qui atteint la dernière case de son couloir remporte la course !',
        AppLocale.en =>
          'The first player to reach the final space of their lane wins the race!',
        AppLocale.es =>
          '¡El primer jugador en llegar a la última casilla de su carril gana la carrera!',
      };

  // --- RÈGLES : L'IMPOSTEUR (imp) ---

  String get impRulesObjective => switch (locale) {
        AppLocale.fr =>
          "Pour les civils : démasquer l'imposteur. Pour l'imposteur : se fondre dans la masse sans se faire griller.",
        AppLocale.en =>
          'For civilians: unmask the imposter. For the imposter: blend in without getting caught.',
        AppLocale.es =>
          'Para los civiles: desenmascarar al impostor. Para el impostor: pasar desapercibido sin que lo descubran.',
      };

  String get impStep1Title => switch (locale) {
        AppLocale.fr => '1. Découverte secrète',
        AppLocale.en => '1. Secret Reveal',
        AppLocale.es => '1. Descubrimiento secreto',
      };

  String get impStep1Desc => switch (locale) {
        AppLocale.fr =>
          "Passez-vous le téléphone. Chaque civil découvre le mot secret. L'imposteur reçoit une consigne floue (ou rien en mode Mister White).",
        AppLocale.en =>
          'Pass the phone around. Each civilian sees the secret word. The imposter gets a vague hint (or nothing in Mister White mode).',
        AppLocale.es =>
          'Pasaos el teléfono. Cada civil descubre la palabra secreta. El impostor recibe una pista vaga (o nada en modo Mister White).',
      };

  String get impStep2Title => switch (locale) {
        AppLocale.fr => "2. Tour d'indices",
        AppLocale.en => '2. Clue Round',
        AppLocale.es => '2. Ronda de pistas',
      };

  String get impStep2Desc => switch (locale) {
        AppLocale.fr =>
          "Dans l'ordre, chaque joueur donne UN SEUL mot comme indice en lien avec le mot secret.",
        AppLocale.en =>
          'In turn order, each player gives ONE SINGLE word as a clue related to the secret word.',
        AppLocale.es =>
          'Por orden, cada jugador dice UNA SOLA palabra como pista relacionada con la palabra secreta.',
      };

  String get impStep3Title => switch (locale) {
        AppLocale.fr => '3. Débat & Vote',
        AppLocale.en => '3. Debate & Vote',
        AppLocale.es => '3. Debate y votación',
      };

  String get impStep3Desc => switch (locale) {
        AppLocale.fr =>
          "À la fin du tour, débattez ensemble et votez tous en même temps pour désigner l'imposteur présumé.",
        AppLocale.en =>
          'At the end of the round, debate together and all vote at the same time to point out the suspected imposter.',
        AppLocale.es =>
          'Al final de la ronda, debatid juntos y votad todos a la vez para señalar al presunto impostor.',
      };

  String get impRulesEndCondition => switch (locale) {
        AppLocale.fr =>
          "Les civils gagnent s'ils votent contre l'imposteur. L'imposteur gagne s'il survit au vote ou s'il devine le mot secret.",
        AppLocale.en =>
          'Civilians win if they vote out the imposter. The imposter wins if they survive the vote or guess the secret word.',
        AppLocale.es =>
          'Los civiles ganan si votan al impostor. El impostor gana si sobrevive a la votación o adivina la palabra secreta.',
      };

  // --- RÈGLES : TU PRÉFÈRES (wyr) ---

  String get wyrRulesObjective => switch (locale) {
        AppLocale.fr =>
          'Trancher entre deux dilemmes impossibles, absurdes ou cruels sans langue de bois.',
        AppLocale.en =>
          'Pick between two impossible, absurd, or ruthless dilemmas with zero filter.',
        AppLocale.es =>
          'Decidir entre dos dilemas imposibles, absurdos o crueles sin filtros.',
      };

  String get wyrStep1Title => switch (locale) {
        AppLocale.fr => '1. Les deux options',
        AppLocale.en => '1. The Two Options',
        AppLocale.es => '1. Las dos opciones',
      };

  String get wyrStep1Desc => switch (locale) {
        AppLocale.fr =>
          "Deux choix s'affichent à l'écran : l'Option Rose vs l'Option Cyan.",
        AppLocale.en =>
          'Two choices appear on screen: the Pink Option vs. the Cyan Option.',
        AppLocale.es =>
          'Aparecen dos opciones en pantalla: la Opción Rosa frente a la Opción Cian.',
      };

  String get wyrStep2Title => switch (locale) {
        AppLocale.fr => '2. Débat & Vote du groupe',
        AppLocale.en => '2. Group Debate & Vote',
        AppLocale.es => '2. Debate y voto del grupo',
      };

  String get wyrStep2Desc => switch (locale) {
        AppLocale.fr =>
          "Au signal, chaque joueur vote à main levée pour l'option qu'il préfère.",
        AppLocale.en =>
          'On the cue, each player raises their hand to vote for their preferred option.',
        AppLocale.es =>
          'A la señal, cada jugador vota levantando la mano por la opción que prefiere.',
      };

  String get wyrStep3Title => switch (locale) {
        AppLocale.fr => '3. Révélation & Pénalités',
        AppLocale.en => '3. Reveal & Penalties',
        AppLocale.es => '3. Revelación y penalizaciones',
      };

  String get wyrStep3Desc => switch (locale) {
        AppLocale.fr =>
          'Appuyez pour révéler les pourcentages mondiaux. La minorité de la table prend +2 pts (+1 pt si choix impopulaire <35%).',
        AppLocale.en =>
          'Tap to reveal global percentages. The table minority gets +2 pts (+1 pt for an unpopular pick <35%).',
        AppLocale.es =>
          'Toca para revelar los porcentajes globales. La minoría de la mesa suma +2 pts (+1 pt si la opción es impopular <35%).',
      };

  String get wyrStep4Title => switch (locale) {
        AppLocale.fr => '4. Hall of Shame & Shots',
        AppLocale.en => '4. Hall of Shame & Shots',
        AppLocale.es => '4. Hall of Shame y chupitos',
      };

  String get wyrStep4Desc => switch (locale) {
        AppLocale.fr =>
          "En fin de partie, le joueur avec le plus de points boit 1 shot + 1 shot bonus par tranche de 5 pts d'écart !",
        AppLocale.en =>
          'At the end of the game, the player with the most points drinks 1 shot + 1 bonus shot per 5-point lead!',
        AppLocale.es =>
          'Al final de la partida, ¡el jugador con más puntos bebe 1 chupito + 1 chupito extra por cada 5 pts de diferencia!',
      };

  String get wyrRulesEndCondition => switch (locale) {
        AppLocale.fr =>
          'Cumulez le moins de points possible pour échapper aux shots du Hall of Shame !',
        AppLocale.en =>
          'Collect as few points as possible to escape the Hall of Shame shots!',
        AppLocale.es =>
          '¡Acumula la menor cantidad de puntos posible para librarte de los chupitos del Hall of Shame!',
      };

  // --- RÈGLES : CODENAMES (code) ---

  String get codeRulesObjective => switch (locale) {
        AppLocale.fr =>
          "Faire deviner tous les mots de son équipe avant les adversaires, tout en évitant l'Assassin.",
        AppLocale.en =>
          "Have your team guess all their words before the opponents, while avoiding the Assassin.",
        AppLocale.es =>
          'Hacer adivinar todas las palabras de tu equipo antes que el rival, evitando al Asesino.',
      };

  String get codeStep1Title => switch (locale) {
        AppLocale.fr => '1. Composition des équipes',
        AppLocale.en => '1. Team Setup',
        AppLocale.es => '1. Formación de equipos',
      };

  String get codeStep1Desc => switch (locale) {
        AppLocale.fr =>
          'Deux équipes (Rouge et Bleu). Dans chaque équipe, un Maître-Espion fait deviner les mots à ses Agents de terrain.',
        AppLocale.en =>
          'Two teams (Red and Blue). In each team, a Spymaster gives clues to their Field Operatives.',
        AppLocale.es =>
          'Dos equipos (Rojo y Azul). En cada equipo, un Jefe de Espías da pistas a sus Agentes de campo.',
      };

  String get codeStep2Title => switch (locale) {
        AppLocale.fr => "2. L'indice codé",
        AppLocale.en => '2. The Coded Clue',
        AppLocale.es => '2. La pista en clave',
      };

  String get codeStep2Desc => switch (locale) {
        AppLocale.fr =>
          'Le Maître-Espion donne un indice composé d\'UN mot et d\'UN chiffre (ex: "Plage 2" pour relier deux mots).',
        AppLocale.en =>
          'The Spymaster gives a clue made of ONE word and ONE number (e.g. "Beach 2" to link two words).',
        AppLocale.es =>
          'El Jefe de Espías da una pista compuesta por UNA palabra y UN número (ej: "Playa 2" para conectar dos palabras).',
      };

  String get codeStep3Title => switch (locale) {
        AppLocale.fr => '3. Révélation des cartes',
        AppLocale.en => '3. Card Reveal',
        AppLocale.es => '3. Revelación de cartas',
      };

  String get codeStep3Desc => switch (locale) {
        AppLocale.fr =>
          'Les agents cliquent sur les cartes correspondantes. Si la carte est de leur couleur, ils continuent.',
        AppLocale.en =>
          'Operatives tap the matching cards. If the card is their team color, they keep guessing.',
        AppLocale.es =>
          'Los agentes tocan las cartas correspondientes. Si la carta es de su color, continúan.',
      };

  String get codeRulesEndCondition => switch (locale) {
        AppLocale.fr =>
          'La première équipe qui découvre toutes ses cartes gagne. Toucher la carte Assassin provoque une défaite immédiate !',
        AppLocale.en =>
          'The first team to uncover all their cards wins. Touching the Assassin card causes an instant loss!',
        AppLocale.es =>
          'El primer equipo en descubrir todas sus cartas gana. ¡Tocar la carta del Asesino provoca una derrota inmediata!',
      };

  // --- RÈGLES : VIPER (viper / board) ---

  String get viperRulesObjective => switch (locale) {
        AppLocale.fr =>
          'Lancer le dé à tour de rôle et franchir le premier la case finale du plateau.',
        AppLocale.en =>
          'Take turns rolling the die and be the first to cross the final space on the board.',
        AppLocale.es =>
          'Tirar el dado por turnos y ser el primero en cruzar la casilla final del tablero.',
      };

  String get viperStep1Title => switch (locale) {
        AppLocale.fr => '1. Déplacement & Rebond (Lacets)',
        AppLocale.en => '1. Movement & Bounce (Zigzag)',
        AppLocale.es => '1. Movimiento y rebote (Zigzag)',
      };

  String get viperStep1Desc => switch (locale) {
        AppLocale.fr =>
          "En Mode Express et Normal, tu avances en serpentin avec rebond si tu dépasses la fin. En Mode Spirale (3 anneaux), tu tournes en boucle sur ton anneau jusqu'à atteindre le centre sans rebond !",
        AppLocale.en =>
          'In Express and Normal modes, you snake across the board and bounce back if you overshoot the finish. In Spiral mode (3 rings), you loop around your ring until you reach the center with no bounce!',
        AppLocale.es =>
          'En modo Express y Normal avanzas en zigzag y rebotas si te pasas del final. ¡En modo Espiral (3 anillos), das vueltas en tu anillo hasta llegar al centro sin rebote!',
      };

  String get viperStep2Title => switch (locale) {
        AppLocale.fr => '2. Échelles (LADDER), Serpents (SNAKE) & Portails',
        AppLocale.en => '2. Ladders, Snakes & Portals',
        AppLocale.es => '2. Escaleras (LADDER), Serpientes (SNAKE) y Portales',
      };

  String get viperStep2Desc => switch (locale) {
        AppLocale.fr =>
          "Pour monter (Échelles ou Portails UP), offre 1 gorgée ou donne un gage ! Pour descendre (Serpents ou Portails DOWN), bois 1 gorgée et glisse (la case d'atterrissage est neutre, évitant toute double peine).",
        AppLocale.en =>
          'To climb (Ladders or UP Portals), hand out 1 sip or give a dare! To slide down (Snakes or DOWN Portals), drink 1 sip and slide (the landing tile is neutral, preventing any double penalty).',
        AppLocale.es =>
          'Para subir (Escaleras o Portales UP), ¡reparte 1 trago o manda un reto! Para bajar (Serpientes o Portales DOWN), bebe 1 trago y deslízate (la casilla de aterrizaje es neutra, evitando doble castigo).',
      };

  String get viperStep3Title => switch (locale) {
        AppLocale.fr => '3. Gages DARE 😈, Vérités & Mode Hot 🌶️',
        AppLocale.en => '3. Dares 😈, Truths & Hot Mode 🌶️',
        AppLocale.es => '3. Retos DARE 😈, Verdades y Modo Hot 🌶️',
      };

  String get viperStep3Desc => switch (locale) {
        AppLocale.fr =>
          "Les cases Truth, Dare (démon 😈) et Drink rythment la partie. Les cartes Spicy n'apparaissent que si le mode Hot 🌶️ est activé !",
        AppLocale.en =>
          'Truth, Dare (devil 😈), and Drink tiles set the pace of the game. Spicy cards only appear if Hot Mode 🌶️ is enabled!',
        AppLocale.es =>
          'Las casillas Truth, Dare (demonio 😈) y Drink marcan el ritmo de la partida. ¡Las cartas Spicy solo aparecen si el Modo Hot 🌶️ está activado!',
      };

  String get viperStep4Title => switch (locale) {
        AppLocale.fr => '4. Cases GLITCH (Double Tour & Anti-Venin)',
        AppLocale.en => '4. GLITCH Tiles (Double Turn & Anti-Venom)',
        AppLocale.es => '4. Casillas GLITCH (Doble Turno y Antídoto)',
      };

  String get viperStep4Desc => switch (locale) {
        AppLocale.fr =>
          'Ces cases piratent le jeu : relance immédiatement le dé (Double Tour), avance, recule, échange ta place ou active un sérum Anti-Venin qui annule ta prochaine descente !',
        AppLocale.en =>
          'These tiles hack the game: roll again right away (Double Turn), jump ahead, move back, swap spots, or activate an Anti-Venom serum that blocks your next slide down!',
        AppLocale.es =>
          'Estas casillas hackean el juego: ¡vuelve a tirar al instante (Doble Turno), avanza, retrocede, intercambia tu puesto o activa un suero Antídoto que anula tu próxima caída!',
      };

  String get viperRulesEndCondition => switch (locale) {
        AppLocale.fr =>
          'Le premier joueur qui atteint la case finale remporte la partie !',
        AppLocale.en =>
          'The first player to reach the final space wins the game!',
        AppLocale.es =>
          '¡El primer jugador en llegar a la casilla final gana la partida!',
      };

  // --- RÈGLES PAR DÉFAUT ---

  String get defaultRulesTitle => switch (locale) {
        AppLocale.fr => 'Règles du jeu',
        AppLocale.en => 'Game Rules',
        AppLocale.es => 'Reglas del juego',
      };

  String get defaultRulesObjective => switch (locale) {
        AppLocale.fr => 'Amusez-vous entre amis !',
        AppLocale.en => 'Have fun with friends!',
        AppLocale.es => '¡Diviértete con tus amigos!',
      };

  String get defaultRulesStepTitle => switch (locale) {
        AppLocale.fr => 'Déroulement',
        AppLocale.en => 'Gameplay',
        AppLocale.es => 'Desarrollo',
      };

  String get defaultRulesStepDesc => switch (locale) {
        AppLocale.fr =>
          "Suivez les instructions affichées à l'écran à chaque tour.",
        AppLocale.en => 'Follow the instructions shown on screen each turn.',
        AppLocale.es =>
          'Sigue las instrucciones mostradas en pantalla en cada turno.',
      };
}
