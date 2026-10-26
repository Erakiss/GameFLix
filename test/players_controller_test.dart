// test/players_controller_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:gameflix/models/game_card.dart';
import 'package:gameflix/models/player.dart';
import 'package:gameflix/state/players_controller.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('add: refuse vide et doublon (insensible à la casse) et applique les cibles par défaut', () async {
    final c = PlayersController();
    await c.load();
    expect(c.add('  ', 'M'), AddPlayerResult.emptyName);
    expect(c.add('Tom', 'M'), AddPlayerResult.added);
    expect(c.add('Léa', 'F'), AddPlayerResult.added);
    expect(c.add('léa', 'F'), AddPlayerResult.duplicate);
    expect(c.count, 2);

    // Par défaut : M -> {'F'}, F -> {'M'}
    expect(c.players[0].attractedTo, {'F'});
    expect(c.players[1].attractedTo, {'M'});
  });

  test('sessionPlayers: copies isolées du roster (score et cibles)', () async {
    final c = PlayersController();
    await c.load();
    c.add('Tom', 'M', attractedTo: {'M', 'F'});
    final session = c.sessionPlayers();
    session.first.score = 42;
    expect(c.players.first.score, 0);
    expect(session.first.attractedTo, {'M', 'F'});
  });

  test('persistance et rétrocompatibilité JSON sans attractedTo', () async {
    // 1. Rétrocompatibilité d'un ancien JSON sans clé attractedTo
    final legacyPlayer = Player.fromJson({'name': 'Alex', 'gender': 'M'});
    expect(legacyPlayer.attractedTo, {'F'});

    // 2. Sauvegarde et rechargement avec cyclePlayerTargets
    final c = PlayersController();
    await c.load();
    c.add('Tom', 'M'); // -> {'F'}
    c.cyclePlayerTargets(0); // -> {'M'}
    c.cyclePlayerTargets(0); // -> {'M', 'F'}
    await Future<void>.delayed(Duration.zero);

    final reloaded = PlayersController();
    await reloaded.load();
    expect(reloaded.players.first.name, 'Tom');
    expect(reloaded.players.first.attractedTo, {'M', 'F'});
  });

  test('matchmaking compatible mutuel et fallback en 2 étapes', () {
    final tom = Player(name: 'Tom', gender: 'M', attractedTo: {'F'});
    final max = Player(name: 'Max', gender: 'M', attractedTo: {'F'});
    final lea = Player(name: 'Léa', gender: 'F', attractedTo: {'M'});
    final chloe = Player(name: 'Chloé', gender: 'F', attractedTo: {'F'});

    // Compatibilité mutuelle
    expect(tom.isCompatibleWith(lea), isTrue);
    expect(tom.isCompatibleWith(max), isFalse);
    expect(tom.isCompatibleWith(chloe), isFalse, reason: 'Chloé n\'a coché que F');

    // Cas 1 : Tom cherche une cible compatible dans [Tom, Max, Léa] -> trouve Léa
    final target = PlayersController.pickTargetFor(
      tom,
      [tom, max, lea],
      requireCompatibility: true,
    );
    expect(target?.name, 'Léa');

    // Cas 2 (Fallback étape 1) : Chloé est active dans [Chloé, Tom, Léa], Chloé n'a pas de partenaire,
    // mais le groupe possède la paire compatible (Tom, Léa)
    final pair = PlayersController.pickCompatiblePair(
      [chloe, tom, lea],
      primary: chloe,
      requireCompatibility: true,
    );
    expect(pair, isNotNull);
    expect({pair!.$1.name, pair.$2.name}, {'Tom', 'Léa'});

    // Cas 3 (Fallback étape 2) : Groupe 100% mecs n'ayant coché que F -> retourne null
    final noPair = PlayersController.pickCompatiblePair(
      [tom, max],
      primary: tom,
      requireCompatibility: true,
    );
    expect(noPair, isNull);
  });

  test('GameCard: détection du mode HOT ou tag optionnel isTactile', () {
    final softNormal = GameCard.fromJson({
      'type': 'ACTION',
      'difficulty': 'SOFT',
      'content': 'Salut {TARGET}',
    });
    final funTactile = GameCard.fromJson({
      'type': 'ACTION',
      'difficulty': 'FUN',
      'content': 'Massage à {TARGET}',
      'isTactile': true,
    });
    final hotCard = GameCard.fromJson({
      'type': 'ACTION',
      'difficulty': 'HOT',
      'content': 'Embrasse {TARGET}',
    });

    expect(softNormal.isTactile, isFalse);
    expect(softNormal.requiresCompatibleTarget, isFalse);
    expect(funTactile.isTactile, isTrue);
    expect(funTactile.requiresCompatibleTarget, isTrue);
    expect(hotCard.requiresCompatibleTarget, isTrue);
  });
}
