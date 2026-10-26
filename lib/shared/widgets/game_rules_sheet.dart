// lib/shared/widgets/game_rules_sheet.dart
import 'package:flutter/material.dart';

// --- MODÈLES DE DONNÉES DES RÈGLES ---

/// Étape ou règle spécifique du déroulement d'un jeu.
class GameRuleStep {
  final String title;
  final String description;
  final IconData? icon;

  const GameRuleStep({
    required this.title,
    required this.description,
    this.icon,
  });
}

/// Ensemble complet des règles associées à un mini-jeu.
class GameRules {
  /// Nom affiché du jeu
  final String gameTitle;

  /// Objectif principal de la partie
  final String objective;

  /// Étapes du déroulement du jeu
  final List<GameRuleStep> steps;

  /// Condition de victoire ou de fin de partie
  final String? endCondition;

  /// Couleur d'accentuation néon thématique
  final Color accentColor;

  const GameRules({
    required this.gameTitle,
    required this.objective,
    required this.steps,
    this.endCondition,
    this.accentColor = Colors.cyanAccent,
  });
}

// --- CATALOGUE DES RÈGLES PAR DÉFAUT ---

/// Fournisseur des règles préconfigurées pour les mini-jeux de GameFlix.
class DefaultGameRules {
  DefaultGameRules._();

  static GameRules getRules(String gameId) {
    switch (gameId) {
      case 'tod':
        return const GameRules(
          gameTitle: 'Action ou Vérité',
          objective: 'Découvrir les secrets de tes potes ou relever des défis délirants sans te défiler.',
          accentColor: Colors.purpleAccent,
          steps: [
            GameRuleStep(
              title: '1. Choix du joueur',
              description: 'Le jeu désigne le joueur actif. Choisis entre Vérité (honnêteté obligatoire) ou Action (gage à accomplir).',
              icon: Icons.touch_app,
            ),
            GameRuleStep(
              title: '2. Les catégories de cartes',
              description: 'SOFT pour démarrer tranquillement, FUN pour rigoler entre potes, et HOT pour chauffer l\'ambiance.',
              icon: Icons.layers,
            ),
            GameRuleStep(
              title: '3. En cas de refus',
              description: 'Si un joueur refuse catégoriquement d\'accomplir son gage ou d\'avouer la vérité, il prend une gorgée de pénalité !',
              icon: Icons.warning_amber_rounded,
            ),
          ],
          endCondition: 'Jouez autant de tours que vous voulez. La partie s\'arrête quand la table n\'a plus de secrets !',
        );

      case 'nhie':
        return const GameRules(
          gameTitle: "Je n'ai jamais",
          objective: 'Être le premier joueur à franchir la ligne d\'arrivée en ayant déjà fait ce qui est annoncé !',
          accentColor: Colors.cyanAccent,
          steps: [
            GameRuleStep(
              title: '1. Annonce de la phrase',
              description: 'Une affirmation commence toujours par "Je n\'ai jamais...". Lis-la à voix haute pour tout le monde.',
              icon: Icons.record_voice_over,
            ),
            GameRuleStep(
              title: '2. Avance ou reste sur place',
              description: 'Tous les joueurs qui ont DÉJÀ fait l\'action annoncée avancent d\'une case dans leur couloir de course.',
              icon: Icons.directions_run,
            ),
            GameRuleStep(
              title: '3. Solidarité & Gorgée',
              description: 'Ceux qui avancent assument leurs bêtises et trinquent tous ensemble !',
              icon: Icons.local_bar,
            ),
          ],
          endCondition: 'Le premier joueur qui atteint la dernière case de son couloir remporte la course !',
        );

      case 'imp':
        return const GameRules(
          gameTitle: "L'Imposteur",
          objective: 'Pour les civils : démasquer l\'imposteur. Pour l\'imposteur : se fondre dans la masse sans se faire griller.',
          accentColor: Colors.orangeAccent,
          steps: [
            GameRuleStep(
              title: '1. Découverte secrète',
              description: 'Passez-vous le téléphone. Chaque civil découvre le mot secret. L\'imposteur reçoit une consigne floue (ou rien en mode Mister White).',
              icon: Icons.visibility_off,
            ),
            GameRuleStep(
              title: '2. Tour d\'indices',
              description: 'Dans l\'ordre, chaque joueur donne UN SEUL mot comme indice en lien avec le mot secret.',
              icon: Icons.chat_bubble_outline,
            ),
            GameRuleStep(
              title: '3. Débat & Vote',
              description: 'À la fin du tour, débattez ensemble et votez tous en même temps pour désigner l\'imposteur présumé.',
              icon: Icons.how_to_vote,
            ),
          ],
          endCondition: 'Les civils gagnent s\'ils votent contre l\'imposteur. L\'imposteur gagne s\'il survit au vote ou s\'il devine le mot secret.',
        );

      case 'wyr':
        return const GameRules(
          gameTitle: 'Tu préfères',
          objective: 'Trancher entre deux dilemmes impossibles, absurdes ou cruels sans langue de bois.',
          accentColor: Colors.blueAccent,
          steps: [
            GameRuleStep(
              title: '1. Les deux options',
              description: 'Deux choix s\'affichent à l\'écran : l\'Option Rose vs l\'Option Cyan.',
              icon: Icons.compare_arrows,
            ),
            GameRuleStep(
              title: '2. Débat & Vote du groupe',
              description: 'Au signal, chaque joueur vote à main levée pour l\'option qu\'il préfère.',
              icon: Icons.thumb_up_alt_outlined,
            ),
            GameRuleStep(
              title: '3. Révélation & Pénalités',
              description: 'Appuyez pour révéler les pourcentages mondiaux. La minorité de la table prend +2 pts (+1 pt si choix impopulaire <35%).',
              icon: Icons.pie_chart_outline_rounded,
            ),
            GameRuleStep(
              title: '4. Hall of Shame & Shots',
              description: 'En fin de partie, le joueur avec le plus de points boit 1 shot + 1 shot bonus par tranche de 5 pts d\'écart !',
              icon: Icons.local_bar_rounded,
            ),
          ],
          endCondition: 'Cumulez le moins de points possible pour échapper aux shots du Hall of Shame !',
        );

      case 'code':
        return const GameRules(
          gameTitle: 'Codenames',
          objective: 'Faire deviner tous les mots de son équipe avant les adversaires, tout en évitant l\'Assassin.',
          accentColor: Colors.cyanAccent,
          steps: [
            GameRuleStep(
              title: '1. Composition des équipes',
              description: 'Deux équipes (Rouge et Bleu). Dans chaque équipe, un Maître-Espion fait deviner les mots à ses Agents de terrain.',
              icon: Icons.groups,
            ),
            GameRuleStep(
              title: '2. L\'indice codé',
              description: 'Le Maître-Espion donne un indice composé d\'UN mot et d\'UN chiffre (ex: "Plage 2" pour relier deux mots).',
              icon: Icons.lightbulb_outline,
            ),
            GameRuleStep(
              title: '3. Révélation des cartes',
              description: 'Les agents cliquent sur les cartes correspondantes. Si la carte est de leur couleur, ils continuent.',
              icon: Icons.style,
            ),
          ],
          endCondition: 'La première équipe qui découvre toutes ses cartes gagne. Toucher la carte Assassin provoque une défaite immédiate !',
        );

      case 'board':
        return const GameRules(
          gameTitle: 'Jeu de Plateau',
          objective: 'Avancer son pion sur le plateau et survivre aux cases pièges jusqu\'à la ligne d\'arrivée.',
          accentColor: Colors.amberAccent,
          steps: [
            GameRuleStep(
              title: '1. Lancer de dé',
              description: 'Chaque joueur lance le dé à son tour pour faire progresser son pion.',
              icon: Icons.casino_outlined,
            ),
            GameRuleStep(
              title: '2. Les cases spéciales',
              description: 'Cases gages, cartes bonus, défis collectifs ou pénalités de gorgées selon la couleur de la case.',
              icon: Icons.alt_route_rounded,
            ),
            GameRuleStep(
              title: '3. Les duels',
              description: 'Si deux pions se croisent, défiez votre adversaire pour l\'obliger à reculer !',
              icon: Icons.sports_mma_outlined,
            ),
          ],
          endCondition: 'Le premier joueur qui atteint exactement la dernière case du plateau remporte la partie.',
        );

      default:
        return GameRules(
          gameTitle: 'Règles du jeu',
          objective: 'Amusez-vous entre amis !',
          accentColor: Colors.cyanAccent,
          steps: const [
            GameRuleStep(
              title: 'Déroulement',
              description: 'Suivez les instructions affichées à l\'écran à chaque tour.',
            ),
          ],
        );
    }
  }
}

// --- WIDGET FEUILLE MODALE DES RÈGLES ---

/// Modal Bottom Sheet stylisée affichant les règles d'un jeu.
class GameRulesSheet extends StatelessWidget {
  final GameRules rules;

  const GameRulesSheet({super.key, required this.rules});

  /// Méthode d'ouverture rapide du modal
  static void show(BuildContext context, GameRules rules) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => GameRulesSheet(rules: rules),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFF16162A),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(25)),
        border: Border.all(color: rules.accentColor.withValues(alpha: 0.5), width: 2),
        boxShadow: [
          BoxShadow(
            color: rules.accentColor.withValues(alpha: 0.25),
            blurRadius: 20,
            spreadRadius: 2,
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 1. Barre supérieure de fermeture
            _buildHeader(context),

            // 2. Contenu scrollable des règles
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // --- SECTION : OBJECTIF DU JEU ---
                    _buildObjectiveCard(),
                    const SizedBox(height: 20),

                    // --- SECTION : ÉTAPES DU JEU ---
                    Text(
                      'COMMENT JOUER ?',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                        color: rules.accentColor,
                        letterSpacing: 1.5,
                      ),
                    ),
                    const SizedBox(height: 12),
                    ...rules.steps.map((step) => _buildStepCard(step)),

                    // --- SECTION : CONDITION DE FIN ---
                    if (rules.endCondition != null) ...[
                      const SizedBox(height: 15),
                      _buildEndConditionCard(),
                    ],
                    const SizedBox(height: 15),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// En-tête de la feuille avec titre et bouton de fermeture
  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(Icons.help_outline_rounded, color: rules.accentColor, size: 24),
              const SizedBox(width: 10),
              Text(
                rules.gameTitle,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  letterSpacing: 1,
                ),
              ),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.close, color: Colors.white70),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }

  /// Bloc résumant l'objectif principal du jeu
  Widget _buildObjectiveCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: rules.accentColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: rules.accentColor.withValues(alpha: 0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.flag_rounded, color: rules.accentColor, size: 18),
              const SizedBox(width: 8),
              Text(
                'BUT DU JEU',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: rules.accentColor,
                  letterSpacing: 1,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            rules.objective,
            style: const TextStyle(
              fontSize: 14,
              color: Colors.white,
              height: 1.3,
            ),
          ),
        ],
      ),
    );
  }

  /// Carte individuelle pour une étape du jeu
  Widget _buildStepCard(GameRuleStep step) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.black38,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (step.icon != null) ...[
            Icon(step.icon, color: rules.accentColor, size: 22),
            const SizedBox(width: 12),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  step.title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  step.description,
                  style: const TextStyle(
                    fontSize: 13,
                    color: Colors.white70,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Bloc signalant la condition de fin ou victoire
  Widget _buildEndConditionCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.amberAccent.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.amberAccent.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.emoji_events_rounded, color: Colors.amberAccent, size: 20),
              SizedBox(width: 8),
              Text(
                'FIN DE PARTIE',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: Colors.amberAccent,
                  letterSpacing: 1,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            rules.endCondition!,
            style: const TextStyle(
              fontSize: 13,
              color: Colors.white,
              height: 1.3,
            ),
          ),
        ],
      ),
    );
  }
}
