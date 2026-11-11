// test/viper_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gameflix/games/viper/viper_game.dart';
import 'package:gameflix/games/viper/viper_lobby.dart';
import 'package:gameflix/games/viper/viper_scoreboard.dart';
import 'package:gameflix/models/player.dart';
import 'package:gameflix/shared/widgets/game_rules_sheet.dart';
import 'package:gameflix/shared/widgets/global_settings_button.dart';

void main() {
  group('Viper Mechanics & Trajectory Tests', () {
    test('Tailles exactes : Express = 47 cases, Normal = 63 cases, Spirale = 90 cases (12x13, 8x9, 4x5)', () {
      expect(ViperBoardMode.express.totalTiles, 47);
      expect(ViperBoardMode.normal.totalTiles, 63);
      expect(ViperBoardMode.spiral.totalTiles, 90);
      expect(ViperBoardMode.spiral.hasFlameBadge, isTrue);

      final spiralGrid = computeBoardGridPositions(ViperBoardMode.spiral);
      expect(spiralGrid.length, 90);
      // Départ en bas à gauche du grand cercle (12x13 : x=0..11, y=0..12)
      expect(spiralGrid.first, const Offset(0, 12));
      // Arrivée sur la case milieu à droite du petit cercle (4x5 : x=4..7, y=4..8 -> milieu droite = (7, 6))
      expect(spiralGrid.last, const Offset(7, 6));
    });

    test('en Lacets : avance normalement sans dépasser la case finale', () {
      final path = computeStepTrajectory(
        startTile: 10,
        steps: 4,
        lastTile: 46,
        mode: ViperBoardMode.express,
      );
      expect(path, [11, 12, 13, 14]);
    });

    test('en Lacets : rebondit en arrière si le lancer du dé dépasse la case finale', () {
      final path = computeStepTrajectory(
        startTile: 44,
        steps: 5,
        lastTile: 46,
        mode: ViperBoardMode.express,
      );
      // 44 + 5 avec lastTile=46 : 45 -> 46 -> 45 -> 44 -> 43
      expect(path, [45, 46, 45, 44, 43]);
      expect(path.last, 43);
    });

    test('en Spirale : boucle sur son anneau actuel sans AUCUN rebond', () {
      // Anneau 1 (12x13) : 46 cases (0..45).
      // Depuis la case 44 avec 4 pas : 45 -> 0 -> 1 -> 2
      final path = computeStepTrajectory(
        startTile: 44,
        steps: 4,
        lastTile: 89,
        mode: ViperBoardMode.spiral,
      );
      expect(path, [45, 0, 1, 2]);
      expect(path.last, 2);
    });

    test('en Spirale : sur l\'anneau 3, s\'arrête sur la case finale (89) pour la victoire sans rebond', () {
      // Anneau 3 (4x5) : 76..89.
      // Depuis la case 87 avec 5 pas : 88 -> 89 (victoire directe sur (7, 6) !)
      final path = computeStepTrajectory(
        startTile: 87,
        steps: 5,
        lastTile: 89,
        mode: ViperBoardMode.spiral,
      );
      expect(path, [88, 89]);
      expect(path.last, 89);
    });

    test('en Lacets : 5 Échelles et 5 Serpents en Express (7 en Normal) avec échelles au début et serpents vers la fin', () {
      for (final mode in [ViperBoardMode.express, ViperBoardMode.normal]) {
        final expectedCount = mode == ViperBoardMode.express ? 5 : 7;
        final ladders = getBoardLaddersForMode(mode);

        final upLadders = ladders.where((l) => l.isLadder).toList();
        final downSnakes = ladders.where((l) => !l.isLadder).toList();

        expect(upLadders.length, expectedCount);
        expect(downSnakes.length, expectedCount);

        final upStarts = upLadders.map((l) => l.fromTile).toList();
        for (int i = 0; i < upStarts.length; i++) {
          for (int j = i + 1; j < upStarts.length; j++) {
            expect((upStarts[i] - upStarts[j]).abs(), greaterThanOrEqualTo(3));
          }
        }

        final downStarts = downSnakes.map((l) => l.fromTile).toList();
        for (int i = 0; i < downStarts.length; i++) {
          for (int j = i + 1; j < downStarts.length; j++) {
            expect((downStarts[i] - downStarts[j]).abs(), greaterThanOrEqualTo(3));
          }
        }

        // Plus d'échelles au début et plus de serpents vers la fin
        final avgLadderStart = upStarts.reduce((a, b) => a + b) / upStarts.length;
        final avgSnakeStart = downStarts.reduce((a, b) => a + b) / downStarts.length;
        expect(avgLadderStart, lessThan(mode.totalTiles / 2));
        expect(avgSnakeStart, greaterThan(mode.totalTiles / 2));
      }
    });

    test('en Spirale : Portails néon UP et DOWN reliant les anneaux voisins avec espacement >= 3', () {
      final connectors = getBoardLaddersForMode(ViperBoardMode.spiral);

      final upPortals = connectors.where((l) => l.isLadder).toList();
      final downPortals = connectors.where((l) => !l.isLadder).toList();

      expect(upPortals.length, greaterThanOrEqualTo(4));
      expect(downPortals.length, greaterThanOrEqualTo(4));

      final upStarts = upPortals.map((l) => l.fromTile).toList();
      for (int i = 0; i < upStarts.length; i++) {
        for (int j = i + 1; j < upStarts.length; j++) {
          expect((upStarts[i] - upStarts[j]).abs(), greaterThanOrEqualTo(3));
        }
      }
    });

    test('TileAction.fromJson gère Sérum Anti-Venin, Rejouer et SPICY', () {
      final antiVeninCard = TileAction.fromJson({
        'title': 'GLITCH',
        'description': 'Sérum Anti-Venin activé ! Immunisé contre la prochaine descente.',
        'type': 'special',
        'movement': 0,
        'shield': true,
      });
      expect(antiVeninCard.shield, isTrue);

      final rerollCard = TileAction.fromJson({
        'title': 'GLITCH',
        'description': 'Double Tour ! Bois 1 gorgée et relance le dé !',
        'type': 'special',
        'movement': 0,
        'reroll': true,
      });
      expect(rerollCard.reroll, isTrue);
    });

    test('les cases SPICY n\'apparaissent que dans le mode Hot 🌶️', () {
      for (int i = 1; i < 46; i++) {
        expect(getTileTypeForIndex(i, ViperDeckMood.classic), isNot(TileType.spicy));
        expect(getTileTypeForIndex(i, ViperDeckMood.blackout), isNot(TileType.spicy));
      }
      final hotTypes = [for (int i = 1; i < 46; i++) getTileTypeForIndex(i, ViperDeckMood.hot)];
      expect(hotTypes.contains(TileType.spicy), isTrue);
    });
  });

  group('Viper Lobby & Scoreboard Widget Tests', () {
    testWidgets('ViperLobbyScreen : 3 Modes (Express, Normal, Spirale avec badge flamme), sans nombre de cases affiché', (tester) async {
      final players = [
        Player(name: 'Alice', gender: 'F'),
        Player(name: 'Bob', gender: 'M'),
      ];

      await tester.pumpWidget(
        MaterialApp(
          home: ViperLobbyScreen(players: players),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('LOBBY'), findsOneWidget);
      expect(find.byIcon(Icons.help_outline_rounded), findsOneWidget);
      expect(find.byType(GlobalSettingsButton), findsOneWidget);

      // Les 3 modes sont proposés directement sans sélecteur Lacets/Spirale séparé
      expect(find.text('LACETS'), findsNothing);
      expect(find.text('MODE EXPRESS'), findsOneWidget);
      expect(find.text('MODE NORMAL'), findsOneWidget);
      expect(find.text('MODE SPIRALE'), findsOneWidget);
      expect(find.byIcon(Icons.local_fire_department_rounded), findsOneWidget);

      // Le nombre de cases (47, 63) n'est pas écrit sur les choix
      expect(find.textContaining('47'), findsNothing);
      expect(find.textContaining('63'), findsNothing);

      expect(find.text('CLASSIQUE'), findsOneWidget);
      expect(find.text('HOT 🌶️'), findsOneWidget);
      expect(find.byIcon(Icons.lock_rounded), findsOneWidget);
      expect(find.text('BLACK OUT'), findsOneWidget);
      expect(find.text('LANCER LA PARTIE'), findsOneWidget);

      // Ouvre la feuille de règles via le bouton d'aide ?
      await tester.tap(find.byIcon(Icons.help_outline_rounded));
      await tester.pumpAndSettle();
      expect(find.byType(GameRulesSheet), findsOneWidget);
      expect(find.textContaining('Rebond'), findsOneWidget);
      expect(find.textContaining('LADDER'), findsOneWidget);
      expect(find.textContaining('SNAKE'), findsOneWidget);
      expect(find.textContaining('Anti-Venin'), findsWidgets);
    });

    testWidgets('ViperScoreboardScreen affiche le vainqueur, les stats et le bouton de paramètres', (tester) async {
      final p1 = Player(name: 'Alice', gender: 'F');
      final p2 = Player(name: 'Bob', gender: 'M');
      final bp1 = BoardPlayer(player: p1, color: Colors.pinkAccent, currentTileIndex: 46)
        ..sipsCount = 6
        ..laddersClimbed = 2
        ..snakesSlid = 1;
      final bp2 = BoardPlayer(player: p2, color: Colors.blueAccent, currentTileIndex: 30)
        ..sipsCount = 3;

      await tester.pumpWidget(
        MaterialApp(
          home: ViperScoreboardScreen(
            boardPlayers: [bp2, bp1],
            players: [p1, p2],
          ),
        ),
      );
      await tester.pump();

      expect(find.text('VICTOIRE !'), findsOneWidget);
      expect(find.text('ALICE'), findsOneWidget);
      expect(find.byType(GlobalSettingsButton), findsOneWidget);
      expect(find.text('REJOUER'), findsOneWidget);
      expect(find.text('HUB'), findsOneWidget);
    });
  });
}
