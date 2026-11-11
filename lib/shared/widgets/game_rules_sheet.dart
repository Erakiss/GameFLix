// lib/shared/widgets/game_rules_sheet.dart
import 'package:flutter/material.dart';
import 'package:gameflix/l10n/app_strings.dart';
import 'package:gameflix/l10n/locale_controller.dart';
import 'package:gameflix/l10n/strings_shared.dart';

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

  static GameRules getRules(String gameId, [AppStrings? strings]) {
    final s = strings ?? AppStrings(LocaleController.instance.currentLocale);

    switch (gameId) {
      case 'tod':
        return GameRules(
          gameTitle: s.gameTitle('tod', 'Action ou Vérité'),
          objective: s.todRulesObjective,
          accentColor: Colors.purpleAccent,
          steps: [
            GameRuleStep(
              title: s.todStep1Title,
              description: s.todStep1Desc,
              icon: Icons.touch_app,
            ),
            GameRuleStep(
              title: s.todStep2Title,
              description: s.todStep2Desc,
              icon: Icons.layers,
            ),
            GameRuleStep(
              title: s.todStep3Title,
              description: s.todStep3Desc,
              icon: Icons.warning_amber_rounded,
            ),
          ],
          endCondition: s.todRulesEndCondition,
        );

      case 'nhie':
        return GameRules(
          gameTitle: s.gameTitle('nhie', "Je n'ai jamais"),
          objective: s.nhieRulesObjective,
          accentColor: Colors.cyanAccent,
          steps: [
            GameRuleStep(
              title: s.nhieStep1Title,
              description: s.nhieStep1Desc,
              icon: Icons.record_voice_over,
            ),
            GameRuleStep(
              title: s.nhieStep2Title,
              description: s.nhieStep2Desc,
              icon: Icons.directions_run,
            ),
            GameRuleStep(
              title: s.nhieStep3Title,
              description: s.nhieStep3Desc,
              icon: Icons.local_bar,
            ),
          ],
          endCondition: s.nhieRulesEndCondition,
        );

      case 'imp':
        return GameRules(
          gameTitle: s.gameTitle('imp', "L'Imposteur"),
          objective: s.impRulesObjective,
          accentColor: Colors.orangeAccent,
          steps: [
            GameRuleStep(
              title: s.impStep1Title,
              description: s.impStep1Desc,
              icon: Icons.visibility_off,
            ),
            GameRuleStep(
              title: s.impStep2Title,
              description: s.impStep2Desc,
              icon: Icons.chat_bubble_outline,
            ),
            GameRuleStep(
              title: s.impStep3Title,
              description: s.impStep3Desc,
              icon: Icons.how_to_vote,
            ),
          ],
          endCondition: s.impRulesEndCondition,
        );

      case 'wyr':
        return GameRules(
          gameTitle: s.gameTitle('wyr', 'Tu préfères'),
          objective: s.wyrRulesObjective,
          accentColor: Colors.blueAccent,
          steps: [
            GameRuleStep(
              title: s.wyrStep1Title,
              description: s.wyrStep1Desc,
              icon: Icons.compare_arrows,
            ),
            GameRuleStep(
              title: s.wyrStep2Title,
              description: s.wyrStep2Desc,
              icon: Icons.thumb_up_alt_outlined,
            ),
            GameRuleStep(
              title: s.wyrStep3Title,
              description: s.wyrStep3Desc,
              icon: Icons.pie_chart_outline_rounded,
            ),
            GameRuleStep(
              title: s.wyrStep4Title,
              description: s.wyrStep4Desc,
              icon: Icons.local_bar_rounded,
            ),
          ],
          endCondition: s.wyrRulesEndCondition,
        );

      case 'code':
        return GameRules(
          gameTitle: s.gameTitle('code', 'Codenames'),
          objective: s.codeRulesObjective,
          accentColor: Colors.cyanAccent,
          steps: [
            GameRuleStep(
              title: s.codeStep1Title,
              description: s.codeStep1Desc,
              icon: Icons.groups,
            ),
            GameRuleStep(
              title: s.codeStep2Title,
              description: s.codeStep2Desc,
              icon: Icons.lightbulb_outline,
            ),
            GameRuleStep(
              title: s.codeStep3Title,
              description: s.codeStep3Desc,
              icon: Icons.style,
            ),
          ],
          endCondition: s.codeRulesEndCondition,
        );

      case 'viper':
      case 'board':
        return GameRules(
          gameTitle: s.gameTitle('viper', 'Viper'),
          objective: s.viperRulesObjective,
          accentColor: Colors.amberAccent,
          steps: [
            GameRuleStep(
              title: s.viperStep1Title,
              description: s.viperStep1Desc,
              icon: Icons.casino_outlined,
            ),
            GameRuleStep(
              title: s.viperStep2Title,
              description: s.viperStep2Desc,
              icon: Icons.swap_vert_rounded,
            ),
            GameRuleStep(
              title: s.viperStep3Title,
              description: s.viperStep3Desc,
              icon: Icons.local_bar_rounded,
            ),
            GameRuleStep(
              title: s.viperStep4Title,
              description: s.viperStep4Desc,
              icon: Icons.bolt_rounded,
            ),
          ],
          endCondition: s.viperRulesEndCondition,
        );

      default:
        return GameRules(
          gameTitle: s.defaultRulesTitle,
          objective: s.defaultRulesObjective,
          accentColor: Colors.cyanAccent,
          steps: [
            GameRuleStep(
              title: s.defaultRulesStepTitle,
              description: s.defaultRulesStepDesc,
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
    final strings = AppStrings.of(context);

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
                    _buildObjectiveCard(strings),
                    const SizedBox(height: 20),

                    // --- SECTION : ÉTAPES DU JEU ---
                    Text(
                      strings.rulesHowToPlayHeader,
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
                      _buildEndConditionCard(strings),
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
  Widget _buildObjectiveCard(AppStrings strings) {
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
                strings.rulesObjectiveHeader,
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
  Widget _buildEndConditionCard(AppStrings strings) {
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
          Row(
            children: [
              const Icon(Icons.emoji_events_rounded, color: Colors.amberAccent, size: 20),
              const SizedBox(width: 8),
              Text(
                strings.rulesEndConditionHeader,
                style: const TextStyle(
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
