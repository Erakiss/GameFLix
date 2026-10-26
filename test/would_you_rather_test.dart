// test/would_you_rather_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gameflix/models/player.dart';
import 'package:gameflix/games/would_you_rather/wyr_lobby.dart';
import 'package:gameflix/games/would_you_rather/wyr_game.dart';
import 'package:gameflix/games/would_you_rather/wyr_scoreboard.dart';
import 'package:gameflix/shared/widgets/neon_volume_control.dart';

void main() {
  group('WyrCard Model Tests', () {
    test('parse correctement les pourcentages explicites et mini-gage', () {
      final json = {
        'category': 'Soft',
        'choice1': 'Option A',
        'choice2': 'Option B',
        'percentage1': 72,
        'mini_gage': 'Chanter une chanson',
      };

      final card = WyrCard.fromJson(json);
      expect(card.category, 'Soft');
      expect(card.choice1, 'Option A');
      expect(card.choice2, 'Option B');
      expect(card.percentage1, 72);
      expect(card.percentage2, 28);
      expect(card.miniGage, 'Chanter une chanson');
    });

    test('génère des pourcentages réalistes et stables en cas d\'absence de stats dans le JSON', () {
      final json = {
        'category': 'Geek',
        'choice1': 'Voyager dans le futur',
        'choice2': 'Voyager dans le passé',
      };

      final card = WyrCard.fromJson(json);
      expect(card.percentage1, greaterThanOrEqualTo(25));
      expect(card.percentage1, lessThanOrEqualTo(75));
      expect(card.percentage1 + card.percentage2, 100);
      expect(card.miniGage, isNull);

      // Vérifie le caractère déterministe
      final card2 = WyrCard.fromJson(json);
      expect(card.percentage1, equals(card2.percentage1));
      expect(card.percentage2, equals(card2.percentage2));
    });
  });

  group('WyrScoreboardScreen Tests', () {
    testWidgets('calcule correctement les shots et affiche le Hall of Shame', (tester) async {
      final players = [
        Player(name: 'Alice', gender: 'F', score: 2),
        Player(name: 'Bob', gender: 'M', score: 12),
        Player(name: 'Charlie', gender: 'M', score: 4),
      ];

      // Bob a 12 pts, Alice a 2 pts -> diff = 10 -> shots = 1 + (10 ~/ 5) = 3 shots
      await tester.pumpWidget(
        MaterialApp(
          home: WyrScoreboardScreen(
            players: players,
            onRestart: () {},
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('💀 HALL OF SHAME 💀'), findsOneWidget);
      expect(find.text('BOB'), findsOneWidget);
      expect(find.textContaining('3 SHOTS'), findsOneWidget);
      expect(find.byType(NeonVolumeControl), findsOneWidget);
      expect(find.text('REJOUER'), findsOneWidget);
      expect(find.text('HUB'), findsOneWidget);
    });
  });

  group('WyrGameScreen Widget Tests', () {
    testWidgets('affiche les dilemmes, révèle les résultats et permet d\'assigner des pénalités', (tester) async {
      final players = [
        Player(name: 'Alice', gender: 'F'),
        Player(name: 'Bob', gender: 'M'),
      ];

      final deck = [
        WyrCard(
          category: 'Soft',
          choice1: 'Pouvoir voler',
          choice2: 'Être invisible',
          percentage1: 70,
          percentage2: 30, // Choix de la honte (<35%)
          miniGage: 'Danser la macarena',
        ),
        WyrCard(
          category: 'Geek',
          choice1: 'Option X',
          choice2: 'Option Y',
          percentage1: 50,
          percentage2: 50,
        ),
      ];

      await tester.pumpWidget(
        MaterialApp(
          home: WyrGameScreen(
            players: players,
            deck: deck,
            totalRounds: 2,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Vérifie l'affichage initial du dilemme
      expect(find.text('Pouvoir voler'), findsOneWidget);
      expect(find.text('Être invisible'), findsOneWidget);
      expect(find.text('RÉVÉLER LES POURCENTAGES'), findsOneWidget);
      expect(find.byType(NeonVolumeControl), findsOneWidget);

      // Tap pour révéler
      await tester.tap(find.text('RÉVÉLER LES POURCENTAGES'));
      await tester.pumpAndSettle();

      // Vérifie la révélation des stats et badges
      expect(find.text('70%'), findsOneWidget);
      expect(find.text('30%'), findsOneWidget);
      expect(find.textContaining('CHOIX DE LA HONTE'), findsOneWidget);
      expect(find.textContaining('Danser la macarena'), findsOneWidget);

      // Puces de joueurs
      expect(find.text('Alice'), findsOneWidget);
      expect(find.text('Bob'), findsOneWidget);

      // Clic sur Alice pour lui mettre une pénalité (+2 pts)
      await tester.tap(find.text('Alice'));
      await tester.pumpAndSettle();
      expect(find.text('+2 pts'), findsOneWidget);

      // Deuxième clic sur Alice : choix honteux présent -> passe à +3 pts
      await tester.tap(find.text('Alice'));
      await tester.pumpAndSettle();
      expect(find.text('+3 pts'), findsOneWidget);

      // Clic sur "DILEMME SUIVANT ➔"
      await tester.tap(find.text('DILEMME SUIVANT ➔'));
      await tester.pumpAndSettle();

      // Alice doit avoir accumulé ses 3 points
      expect(players.firstWhere((p) => p.name == 'Alice').score, 3);

      // 2e carte : bouton de fin "VOIR LE HALL OF SHAME 💀"
      await tester.tap(find.text('RÉVÉLER LES POURCENTAGES'));
      await tester.pumpAndSettle();
      expect(find.text('VOIR LE HALL OF SHAME 💀'), findsOneWidget);
    });
  });

  group('WyrLobbyScreen Widget Tests', () {
    testWidgets('affiche le contrôle de son, le sélecteur de durée et les catégories', (tester) async {
      final players = [
        Player(name: 'Alice', gender: 'F'),
        Player(name: 'Bob', gender: 'M'),
      ];

      await tester.pumpWidget(
        MaterialApp(
          home: WyrLobbyScreen(players: players),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('TU PRÉFÈRES ?'), findsOneWidget);
      expect(find.byType(NeonVolumeControl), findsOneWidget);
      expect(find.text('DURÉE DE LA PARTIE'), findsOneWidget);
      expect(find.text('15'), findsOneWidget);
      expect(find.text('LANCER LE JEU'), findsOneWidget);

      // Changement de durée vers Express (10)
      await tester.tap(find.text('10'));
      await tester.pumpAndSettle();
    });
  });
}
