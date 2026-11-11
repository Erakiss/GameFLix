// test/nhie_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:gameflix/models/player.dart';
import 'package:gameflix/games/never_have_i_ever/nhie_lobby.dart';
import 'package:gameflix/games/never_have_i_ever/nhie_game.dart';
import 'package:gameflix/games/never_have_i_ever/nhie_scoreboard.dart';
import 'package:gameflix/state/access_control_provider.dart';

void main() {
  group('NHIE Lobby, Race & Scoreboard Widget Tests', () {
    testWidgets('NhieLobbyScreen affiche le sélecteur Classique (10 pts) / Modulable', (tester) async {
      final players = [
        Player(name: 'Alice', gender: 'F'),
        Player(name: 'Bob', gender: 'M'),
      ];

      await tester.pumpWidget(
        ChangeNotifierProvider<AccessControlProvider>.value(
          value: AccessControlProvider.instance,
          child: MaterialApp(
            home: NhieLobbyScreen(players: players),
          ),
        ),
      );

      expect(find.text('CLASSIQUE'), findsOneWidget);
      expect(find.text('MODULABLE'), findsOneWidget);
      expect(find.text('LANCER LA COURSE (10 PTS)'), findsOneWidget);

      await tester.ensureVisible(find.text('MODULABLE'));
      await tester.pump();
      await tester.tap(find.text('MODULABLE'));
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('15 PTS'), findsOneWidget);
      expect(find.text('LANCER LA COURSE (15 PTS)'), findsOneWidget);
    });

    testWidgets('NhieRaceScreen permet de sélectionner un joueur, valider et annuler (Undo)', (tester) async {
      final players = [
        Player(name: 'Alice', gender: 'F'),
        Player(name: 'Bob', gender: 'M'),
      ];
      final deck = [
        NhieCard(difficulty: 'SOFT', content: 'Je n\'ai jamais dormi au cinéma'),
        NhieCard(difficulty: 'FUN', content: 'Je n\'ai jamais chanté sous la douche'),
      ];

      await tester.pumpWidget(
        MaterialApp(
          home: NhieRaceScreen(
            players: players,
            deck: deck,
            targetScore: 5,
          ),
        ),
      );

      expect(find.text('ARRIVÉE • 5 PTS'), findsOneWidget);
      expect(find.text('PASSER LA CARTE 😇 →'), findsOneWidget);

      // Tap sur le couloir d'Alice
      await tester.tap(find.text('Alice'));
      await tester.pump();

      expect(find.text('+1 🍺'), findsOneWidget);
      expect(find.text('TRINQUER & AVANCER (1) 🍻'), findsOneWidget);

      // Valider le tour
      await tester.tap(find.text('TRINQUER & AVANCER (1) 🍻'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 350));
      await tester.pump();

      expect(players[0].score, 1);
      expect(players[1].score, 0);
      expect(find.text('Je n\'ai jamais chanté sous la douche'), findsOneWidget);

      // Annuler le tour via le bouton Undo
      await tester.tap(find.byIcon(Icons.undo_rounded));
      await tester.pump();

      expect(players[0].score, 0);
      expect(find.text('Je n\'ai jamais dormi au cinéma'), findsOneWidget);
    });

    testWidgets('NhieScoreboardScreen gère le vainqueur unique sans overflow sur écran mobile étroit', (tester) async {
      tester.view.physicalSize = const Size(340, 760);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      final players = [
        Player(name: 'Vetriope', gender: 'M', score: 10),
        Player(name: 'Lucassette', gender: 'F', score: 2),
        Player(name: 'Victor', gender: 'M', score: 1),
        Player(name: 'Julie', gender: 'F', score: 1),
      ];

      await tester.pumpWidget(
        MaterialApp(
          home: NhieScoreboardScreen(
            players: players,
            targetScore: 10,
          ),
        ),
      );

      expect(find.text('ARRIVÉE FRANCHIE !'), findsOneWidget);
      expect(find.text('GRAND VAINQUEUR DE LA SOIRÉE'), findsOneWidget);
      expect(find.text('VETRIOPE'), findsOneWidget);
      expect(find.text('1 pt'), findsNWidgets(2));
      expect(find.text('MENU'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('NhieScoreboardScreen gère le Photo-Finish ex-aequo', (tester) async {
      final players = [
        Player(name: 'Alice', gender: 'F', score: 10),
        Player(name: 'Bob', gender: 'M', score: 10),
        Player(name: 'Charlie', gender: 'M', score: 2),
      ];

      await tester.pumpWidget(
        MaterialApp(
          home: NhieScoreboardScreen(
            players: players,
            targetScore: 10,
          ),
        ),
      );

      expect(find.text('PHOTO-FINISH !'), findsOneWidget);
      expect(find.text('ALICE & BOB'), findsOneWidget);
      expect(find.text('Légende Vivante 🏆'), findsNWidgets(2));
      expect(find.text('Ange Gardien 😇'), findsOneWidget);
    });
  });
}
