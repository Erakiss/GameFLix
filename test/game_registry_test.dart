// test/game_registry_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:gameflix/models/game_config.dart';
import 'package:gameflix/models/player.dart';

void main() {
  group('GameRegistry & GameConfig', () {
    test('recense l\'ensemble des 6 jeux actuels plus la carte en préparation', () {
      final games = GameRegistry.games;
      expect(games.length, 7);

      final ids = games.map((g) => g.id).toSet();
      expect(ids.length, 7, reason: 'Chaque jeu doit posséder un identifiant unique');
      expect(ids.containsAll(['tod', 'nhie', 'imp', 'wyr', 'board', 'code', 'coming_soon']), isTrue);
    });

    test('respecte les contraintes de joueurs pour chaque jeu', () {
      final tod = GameRegistry.games.firstWhere((g) => g.id == 'tod');
      expect(tod.minPlayers, 2);
      expect(tod.maxPlayers, isNull);

      final nhie = GameRegistry.games.firstWhere((g) => g.id == 'nhie');
      expect(nhie.minPlayers, 2);
      expect(nhie.maxPlayers, 5);

      final imp = GameRegistry.games.firstWhere((g) => g.id == 'imp');
      expect(imp.minPlayers, 3);
      expect(imp.maxPlayers, isNull);

      final wyr = GameRegistry.games.firstWhere((g) => g.id == 'wyr');
      expect(wyr.minPlayers, 2);
      expect(wyr.maxPlayers, isNull);

      final board = GameRegistry.games.firstWhere((g) => g.id == 'board');
      expect(board.minPlayers, 2);
      expect(board.maxPlayers, 6);

      final code = GameRegistry.games.firstWhere((g) => g.id == 'code');
      expect(code.minPlayers, 4);
      expect(code.maxPlayers, isNull);

      final comingSoon = GameRegistry.games.firstWhere((g) => g.id == 'coming_soon');
      expect(comingSoon.isLocked, isTrue);
    });

    test('chaque builder génère un widget valide avec des sessionPlayers', () {
      final players = [
        Player(name: 'Alice', gender: 'F'),
        Player(name: 'Bob', gender: 'M'),
      ];

      for (final game in GameRegistry.games) {
        final widget = game.builder(players);
        expect(widget, isNotNull);
      }
    });
  });
}
