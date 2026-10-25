// test/game_rules_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gameflix/shared/widgets/game_rules_sheet.dart';

void main() {
  group('GameRules & GameRulesSheet', () {
    test('les 6 jeux possèdent des règles prédéfinies et complètes', () {
      final gamesWithRules = ['tod', 'nhie', 'imp', 'wyr', 'code', 'board'];
      for (final gameId in gamesWithRules) {
        final rules = DefaultGameRules.getRules(gameId);
        expect(rules, isNotNull, reason: 'Règles manquantes pour $gameId');
        expect(rules.gameTitle.isNotEmpty, isTrue);
        expect(rules.objective.isNotEmpty, isTrue);
        expect(rules.steps.isNotEmpty, isTrue);
      }
    });

    testWidgets('affiche correctement les éléments des règles à l\'écran', (tester) async {
      const testRules = GameRules(
        gameTitle: 'Jeu Test',
        objective: 'Gagner la partie sans tricher.',
        steps: [
          GameRuleStep(title: 'Étape 1', description: 'Lancer les dés.'),
          GameRuleStep(title: 'Étape 2', description: 'Avancer le pion.'),
        ],
        endCondition: 'Arriver sur la case finale.',
        accentColor: Colors.pinkAccent,
      );

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: GameRulesSheet(rules: testRules),
          ),
        ),
      );

      expect(find.text('Jeu Test'), findsOneWidget);
      expect(find.text('Gagner la partie sans tricher.'), findsOneWidget);
      expect(find.text('Étape 1'), findsOneWidget);
      expect(find.text('Lancer les dés.'), findsOneWidget);
      expect(find.text('Étape 2'), findsOneWidget);
      expect(find.text('Avancer le pion.'), findsOneWidget);
      expect(find.text('Arriver sur la case finale.'), findsOneWidget);
    });
  });
}
