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

  testWidgets('Hub AppBar : affiche Drapeau, Joueurs, Logo/Titre responsive, Icône Couronne PRO minimaliste et ouvre Settings Overlay plein écran', (tester) async {
    final playersCtrl = PlayersController();
    await playersCtrl.load();
    await LocaleController.instance.load();

    // 1. Test sur grand écran (>= 600px, défaut 800x600 dans flutter_test) -> affiche le titre textuel "gameflix"
    await tester.pumpWidget(buildTestApp(playersCtrl));
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.byKey(const Key('hub_language_selector')), findsOneWidget);
    expect(find.byKey(const Key('hub_players_button')), findsOneWidget);
    expect(find.byKey(const Key('hub_header_title_text')), findsOneWidget);
    expect(find.text('game'), findsOneWidget);
    expect(find.text('flix'), findsOneWidget);
    expect(find.byKey(const Key('hub_header_logo')), findsNothing);
    expect(find.byKey(const Key('hub_pro_badge')), findsOneWidget);
    expect(find.byType(ProCrownIcon), findsOneWidget);
    expect(tester.widget<ProCrownIcon>(find.byType(ProCrownIcon)).isSubscribed, isFalse);
    expect(find.byKey(const Key('hub_settings_button')), findsOneWidget);

    // 2. Passage en abonné VIP -> l'icône ProCrownIcon passe en état actif (sans texte)
    AccessControlProvider.instance.setSubscribedForTest(true);
    await tester.pump();
    expect(tester.widget<ProCrownIcon>(find.byType(ProCrownIcon)).isSubscribed, isTrue);

    // 3. Test responsive sur petit écran mobile (< 600px) -> affiche uniquement le nouveau logo "G"
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
    await tester.pump();
    expect(find.byKey(const Key('hub_header_logo')), findsOneWidget);
    expect(find.byKey(const Key('hub_header_title_text')), findsNothing);

    // 4. Ouverture de l'Overlay Réglages plein écran et fermeture via la croix ✕
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

  testWidgets('Hub Wheel : affiche HubInWheelAdCard pour utilisateur gratuit et la masque pour VIP / Pass 1H', (tester) async {
    final playersCtrl = PlayersController();
    await playersCtrl.load();
    await LocaleController.instance.load();
    final access = AccessControlProvider.instance;

    // 1. Utilisateur gratuit -> Carte sponsorisée présente dans la roue (faire défiler vers le bas)
    access.clearForTest();
    await tester.pumpWidget(buildTestApp(playersCtrl));
    await tester.pump(const Duration(milliseconds: 100));

    await tester.drag(find.byType(ListWheelScrollView), const Offset(0, -500));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('hub_in_wheel_ad_card')), findsOneWidget);
    expect(find.text('ESPACE SPONSOR'), findsOneWidget);

    // 2. Utilisateur abonné VIP -> Carte sponsorisée absente même après défilement
    access.setSubscribedForTest(true);
    await tester.pumpWidget(buildTestApp(playersCtrl));
    await tester.pump(const Duration(milliseconds: 100));

    await tester.drag(find.byType(ListWheelScrollView), const Offset(0, -500));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('hub_in_wheel_ad_card')), findsNothing);

    // 3. Utilisateur sous Pass Soirée 1H -> Carte sponsorisée absente
    access.clearForTest();
    access.setPass1hForTest(
      expiresAt: DateTime.now().add(const Duration(minutes: 50)),
      hasUsed: true,
    );
    await tester.pumpWidget(buildTestApp(playersCtrl));
    await tester.pump(const Duration(milliseconds: 100));

    await tester.drag(find.byType(ListWheelScrollView), const Offset(0, -500));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('hub_in_wheel_ad_card')), findsNothing);
  });
}
