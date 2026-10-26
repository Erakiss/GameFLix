// test/hub_and_settings_test.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:gameflix/hub/gameflix_hub.dart';
import 'package:gameflix/hub/widgets/settings_overlay_dialog.dart';
import 'package:gameflix/l10n/locale_controller.dart';
import 'package:gameflix/services/audio_service.dart';
import 'package:gameflix/state/access_control_provider.dart';
import 'package:gameflix/state/players_controller.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    LocaleController.instance.resetForTest();
    AccessControlProvider.instance.clearForTest();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('xyz.luan/audioplayers.global'),
      (call) async => 1,
    );
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('xyz.luan/audioplayers'),
      (call) async => 1,
    );
  });

  tearDown(() {
    AudioService.instance.resetForTest();
  });

  Widget buildTestApp(PlayersController playersCtrl) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<PlayersController>.value(value: playersCtrl),
        ChangeNotifierProvider<LocaleController>.value(value: LocaleController.instance),
        ChangeNotifierProvider<AccessControlProvider>.value(value: AccessControlProvider.instance),
      ],
      child: const MaterialApp(
        home: GameFlixHub(),
      ),
    );
  }

  testWidgets('Hub AppBar : affiche Drapeau, Joueurs, Logo compact, Badge PRO et ouvre Settings Overlay plein écran', (tester) async {
    final playersCtrl = PlayersController();
    await playersCtrl.load();
    await LocaleController.instance.load();

    await tester.pumpWidget(buildTestApp(playersCtrl));
    await tester.pump(const Duration(milliseconds: 100));

    // 1. Vérification des éléments de l'AppBar
    expect(find.byKey(const Key('hub_language_selector')), findsOneWidget);
    expect(find.byKey(const Key('hub_players_button')), findsOneWidget);
    expect(find.text('GAMEFLIX'), findsOneWidget);
    expect(find.byKey(const Key('hub_pro_badge')), findsOneWidget);
    expect(find.text('🔥 PRO'), findsOneWidget);
    expect(find.byKey(const Key('hub_settings_button')), findsOneWidget);

    // 2. Passage en abonné VIP -> le badge devient 👑 PRO ACTIF
    AccessControlProvider.instance.setSubscribedForTest(true);
    await tester.pump();
    expect(find.text('👑 PRO ACTIF'), findsOneWidget);

    // 3. Ouverture de l'Overlay Réglages plein écran et fermeture via la croix ✕
    await tester.tap(find.byKey(const Key('hub_settings_button')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 350));

    expect(find.byType(SettingsOverlayDialog), findsOneWidget);
    expect(find.text('RÉGLAGES'), findsOneWidget);
    expect(find.byKey(const Key('settings_close_button')), findsOneWidget);

    // Changement de langue en Anglais depuis l'Overlay Réglages
    await tester.tap(find.text('English'));
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.text('SETTINGS'), findsOneWidget);

    // Fermeture via le bouton croix (✕) en haut à gauche
    await tester.tap(find.byKey(const Key('settings_close_button')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 350));
    expect(find.byType(SettingsOverlayDialog), findsNothing);
    expect(find.text('SELECT A GAME'), findsOneWidget);
  });

  testWidgets('PlayerManagerSheet : pré-coche la cible opposée et permet de basculer le badge en liste', (tester) async {
    final playersCtrl = PlayersController();
    await playersCtrl.load();
    await LocaleController.instance.load();

    await tester.pumpWidget(buildTestApp(playersCtrl));
    await tester.pump(const Duration(milliseconds: 100));

    // 1. Ouverture de PlayerManagerSheet
    await tester.tap(find.byKey(const Key('hub_players_button')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.byType(PlayerManagerSheet), findsOneWidget);

    // 2. Ajout d'un garçon (par défaut cible -> ♀)
    await tester.enterText(find.byType(TextField), 'Lucas');
    await tester.tap(find.byIcon(Icons.add_circle));
    await tester.pump(const Duration(milliseconds: 100));

    expect(playersCtrl.count, 1);
    expect(playersCtrl.players.first.attractedTo, {'F'});
    expect(find.text('→ ♀'), findsOneWidget);

    // 3. Tap sur le badge de cible dans la liste pour basculer à la volée (♀ -> ♂ -> ♂♀)
    await tester.tap(find.byKey(const Key('player_target_badge_0')));
    await tester.pump(const Duration(milliseconds: 100));
    expect(playersCtrl.players.first.attractedTo, {'M'});
    expect(find.text('→ ♂'), findsOneWidget);

    await tester.tap(find.byKey(const Key('player_target_badge_0')));
    await tester.pump(const Duration(milliseconds: 100));
    expect(playersCtrl.players.first.attractedTo, {'M', 'F'});
    expect(find.text('→ ♂♀'), findsOneWidget);
  });
}
