// test/l10n_games_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:gameflix/games/codenames/code_lobby.dart';
import 'package:gameflix/games/imposter/imp_lobby.dart';
import 'package:gameflix/games/never_have_i_ever/nhie_game.dart';
import 'package:gameflix/games/never_have_i_ever/nhie_lobby.dart';
import 'package:gameflix/games/truth_or_dare/tod_game.dart';
import 'package:gameflix/games/viper/viper_lobby.dart';
import 'package:gameflix/games/would_you_rather/wyr_lobby.dart';
import 'package:gameflix/l10n/locale_controller.dart';
import 'package:gameflix/models/game_card.dart';
import 'package:gameflix/models/player.dart';
import 'package:gameflix/services/audio_service.dart';
import 'package:gameflix/shared/widgets/unlock_pack_sheet.dart';
import 'package:gameflix/state/access_control_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final testPlayers = [
    Player(name: 'Alice', gender: 'F'),
    Player(name: 'Bob', gender: 'M'),
    Player(name: 'Charlie', gender: 'M'),
    Player(name: 'Dana', gender: 'F'),
  ];

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    LocaleController.instance.resetForTest();
    AccessControlProvider.instance.clearForTest();
    AudioService.instance.resetForTest();
  });

  tearDown(() {
    LocaleController.instance.resetForTest();
    AudioService.instance.resetForTest();
  });

  Widget wrapWithProviders(Widget child) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<LocaleController>.value(value: LocaleController.instance),
        ChangeNotifierProvider<AccessControlProvider>.value(value: AccessControlProvider.instance),
      ],
      child: MaterialApp(home: child),
    );
  }

  testWidgets('NhieRaceScreen affiche tous les libellés traduits en anglais et espagnol', (tester) async {
    await LocaleController.instance.setLocale(AppLocale.en);
    final deck = [
      NhieCard(difficulty: 'GEEK', content: 'Never have I ever debated Goku vs Superman.'),
    ];

    await tester.pumpWidget(
      wrapWithProviders(
        NhieRaceScreen(
          players: testPlayers.sublist(0, 2),
          deck: deck,
          targetScore: 10,
        ),
      ),
    );

    expect(find.text('NEON RACECOURSE'), findsOneWidget);
    expect(find.text('NEVER HAVE I EVER...'), findsOneWidget);
    expect(find.text('FINISH • 10 PTS'), findsOneWidget);
    expect(find.text('SKIP CARD 😇 →'), findsOneWidget);

    await tester.tap(find.text('Alice'));
    await tester.pump();
    expect(find.text('CHEERS & ADVANCE (1) 🍻'), findsOneWidget);

    // Bascule à chaud en espagnol
    await LocaleController.instance.setLocale(AppLocale.es);
    await tester.pump();
    expect(find.text('HIPÓDROMO NEÓN'), findsOneWidget);
    expect(find.text('YO NUNCA...'), findsOneWidget);
    expect(find.text('META • 10 PTS'), findsOneWidget);
    expect(find.text('BRINDAR Y AVANZAR (1) 🍻'), findsOneWidget);
  });

  testWidgets('TodGameScreen traduit DARE / TRUTH et DONE / REFUSED en anglais', (tester) async {
    await LocaleController.instance.setLocale(AppLocale.en);
    final deck = [
      GameCard(type: 'ACTION', difficulty: 'SOFT', content: 'Do 10 pushups!'),
      GameCard(type: 'VERITE', difficulty: 'FUN', content: 'Tell a secret.'),
    ];

    await tester.pumpWidget(
      wrapWithProviders(
        TodGameScreen(
          players: testPlayers.sublist(0, 2),
          deck: deck,
          maxTurns: 5,
        ),
      ),
    );

    // Fin du mélange initial
    await tester.pump(const Duration(milliseconds: 2000));
    await tester.pumpAndSettle();

    expect(find.text('DARE'), findsOneWidget);
    expect(find.text('TRUTH'), findsOneWidget);
    expect(find.text('Take the challenge'), findsOneWidget);
    expect(find.text('Confess unfiltered'), findsOneWidget);

    await tester.tap(find.text('DARE'));
    await tester.pumpAndSettle();

    expect(find.text('DONE'), findsOneWidget);
    expect(find.text('REFUSED'), findsOneWidget);
  });

  testWidgets('Lobbies (WYR, Viper, Imposter, Codenames) et UnlockPackSheet s\'affichent en anglais', (tester) async {
    await LocaleController.instance.setLocale(AppLocale.en);

    // 1. WYR Lobby
    await tester.pumpWidget(wrapWithProviders(WyrLobbyScreen(players: testPlayers.sublist(0, 2))));
    await tester.pumpAndSettle();
    expect(find.text('GAME LENGTH'), findsOneWidget);
    expect(find.text('START GAME'), findsOneWidget);

    // 2. Viper Lobby
    await tester.pumpWidget(wrapWithProviders(ViperLobbyScreen(players: testPlayers.sublist(0, 2))));
    await tester.pumpAndSettle();
    expect(find.text('EXPRESS MODE'), findsOneWidget);
    expect(find.text('SPIRAL MODE'), findsOneWidget);
    expect(find.text('START GAME'), findsOneWidget);

    // 3. Imposter Lobby
    await tester.pumpWidget(wrapWithProviders(ImpLobbyScreen(players: testPlayers.sublist(0, 3))));
    await tester.pumpAndSettle();
    expect(find.text('Mister White Mode'), findsOneWidget);
    expect(find.text('DEAL ROLES'), findsOneWidget);

    // 4. Codenames Lobby
    await tester.pumpWidget(wrapWithProviders(CodeLobbyScreen(players: testPlayers)));
    await tester.pumpAndSettle();
    expect(find.text('Enable Express Mode'), findsOneWidget);
    expect(find.text('GENERATE GRID'), findsOneWidget);

    // 5. UnlockPackSheet
    await tester.pumpWidget(
      wrapWithProviders(
        Scaffold(
          body: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () {
                UnlockPackSheet.show(
                  context,
                  packId: 'wyr_hot',
                  packTitle: 'Hot Pack',
                  onUnlocked: () {},
                );
              },
              child: const Text('Open'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();

    expect(find.text('FREE 1H PARTY PASS'), findsOneWidget);
    expect(find.text('ANNUAL CLUB PASS'), findsOneWidget);
    expect(find.text('WEEKLY PASS'), findsOneWidget);
    expect(find.text('Restore Purchases'), findsOneWidget);
  });
}
