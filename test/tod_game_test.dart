import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:gameflix/games/truth_or_dare/tod_game.dart';
import 'package:gameflix/models/game_card.dart';
import 'package:gameflix/models/player.dart';
import 'package:gameflix/services/audio_service.dart';
import 'package:gameflix/shared/widgets/neon_table_mat.dart';
import 'package:gameflix/shared/widgets/procedural_neon_background.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    AudioService.instance.resetForTest();
  });

  tearDown(() {
    AudioService.instance.resetForTest();
  });

  final testPlayers = [
    Player(name: 'Alice', gender: 'F'),
    Player(name: 'Bob', gender: 'M'),
  ];

  final testDeck = [
    GameCard(
      type: 'ACTION',
      difficulty: 'SOFT',
      content: 'Fais 10 pompes !',
    ),
    GameCard(
      type: 'VERITE',
      difficulty: 'FUN',
      content: 'Révèle ton plus grand secret.',
    ),
  ];

  testWidgets('TodGameScreen affiche le tapis vectoriel et les panneaux duel ACTION / VÉRITÉ après mélange', (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: TodGameScreen(
          players: testPlayers,
          deck: testDeck,
          maxTurns: 5,
        ),
      ),
    );

    // Initialement en phase de mélange
    expect(find.byType(ProceduralNeonBackground), findsOneWidget);
    expect(find.byType(NeonTableMat), findsOneWidget);
    expect(find.text("C'est au tour de"), findsOneWidget);
    expect(find.text('Alice'), findsOneWidget);

    // On avance dans le temps pour dépasser l'animation de mélange initial (1700ms + reverse doors)
    await tester.pump(const Duration(milliseconds: 2000));
    await tester.pumpAndSettle();

    // Vérifie la présence des 2 panneaux duel sans badge OU gênant
    expect(find.text('ACTION'), findsOneWidget);
    expect(find.text('VÉRITÉ'), findsOneWidget);
    expect(find.text('Relève le défi'), findsOneWidget);
    expect(find.text('Avoue sans filtre'), findsOneWidget);
    expect(find.text('OU'), findsNothing);

    // Tap sur le panneau ACTION
    await tester.tap(find.text('ACTION'));
    await tester.pump();
    await tester.pumpAndSettle();

    // La carte ACTION doit maintenant être tirée et visible
    expect(find.text('Fais 10 pompes !'), findsOneWidget);
    expect(find.text('FAIT'), findsOneWidget);
    expect(find.text('REFUSÉ'), findsOneWidget);

    // Tap sur FAIT pour enregistrer et passer au tour suivant
    await tester.tap(find.text('FAIT'));
    await tester.pump();
    // Transition vers le joueur Bob
    await tester.pump(const Duration(milliseconds: 1600));
    await tester.pumpAndSettle();

    expect(find.text('Bob'), findsOneWidget);
    expect(find.text('VÉRITÉ'), findsOneWidget);
  });
}
