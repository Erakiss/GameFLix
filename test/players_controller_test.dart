import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:gameflix/state/players_controller.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('add: refuse vide et doublon (insensible à la casse)', () async {
    final c = PlayersController();
    await c.load();
    expect(c.add('  ', 'M'), AddPlayerResult.emptyName);
    expect(c.add('Léa', 'F'), AddPlayerResult.added);
    expect(c.add('léa', 'F'), AddPlayerResult.duplicate);
    expect(c.count, 1);
  });

  test('sessionPlayers: copies isolées du roster', () async {
    final c = PlayersController();
    await c.load();
    c.add('Tom', 'M');
    final session = c.sessionPlayers();
    session.first.score = 42;
    expect(c.players.first.score, 0);
    expect(c.sessionPlayers().first.score, 0);
  });

  test('persistance: rechargement depuis SharedPreferences', () async {
    final c = PlayersController();
    await c.load();
    c.add('Tom', 'M');
    c.add('Léa', 'F');
    c.removeAt(0);
    await Future<void>.delayed(Duration.zero);

    final reloaded = PlayersController();
    await reloaded.load();
    expect(reloaded.players.map((p) => p.name), ['Léa']);
  });
}
