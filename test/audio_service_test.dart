// test/audio_service_test.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:gameflix/hub/widgets/settings_overlay_dialog.dart';
import 'package:gameflix/l10n/locale_controller.dart';
import 'package:gameflix/services/audio_service.dart';
import 'package:gameflix/shared/widgets/global_settings_button.dart';
import 'package:gameflix/state/access_control_provider.dart';

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

  group('AudioService Unit Tests', () {
    test('tous les SoundEffect possèdent un chemin d\'asset valide', () {
      final service = AudioService.instance;
      for (final effect in SoundEffect.values) {
        final path = service.getSfxAssetPath(effect);
        expect(path.isNotEmpty, isTrue);
        expect(path.startsWith('audio/sfx_'), isTrue);
        expect(
          path.endsWith('.ogg') ||
              path.endsWith('.wav') ||
              path.endsWith('.mp3'),
          isTrue,
        );
      }
    });

    test('gestion du Volume maître et des 2 toggles indépendants BGM / SFX', () async {
      final service = AudioService.instance;
      await service.init();

      expect(service.volume, greaterThan(0.0));
      expect(service.isMuted, isFalse);
      expect(service.isBgmMuted, isFalse);
      expect(service.isSfxMuted, isFalse);

      // 1. Toggle BGM seul
      await service.toggleBgmMute();
      expect(service.isBgmMuted, isTrue);
      expect(service.isSfxMuted, isFalse);
      expect(service.isMuted, isFalse, reason: 'SFX est encore actif');

      // 2. Toggle SFX seul -> les deux sont coupés donc isMuted devient true
      await service.toggleSfxMute();
      expect(service.isBgmMuted, isTrue);
      expect(service.isSfxMuted, isTrue);
      expect(service.isMuted, isTrue);

      // 3. Réglage du volume maître par palier (1 à 5) réactive le son
      await service.setVolumeLevel(4);
      expect(
        service.isMuted,
        isFalse,
        reason: 'Changer le volume doit réactiver le son',
      );
      expect(service.volumeLevel, 4);
      expect(service.volume, closeTo(0.8, 0.01));
    });

    test('cycle de vie WidgetsBindingObserver : pause auto en arrière-plan et reprise au retour', () async {
      final service = AudioService.instance;
      await service.init();
      await service.playBgm();
      expect(service.isBgmPlaying, isTrue);

      // 1. Passage en arrière-plan (paused)
      service.didChangeAppLifecycleState(AppLifecycleState.paused);
      await Future<void>.delayed(Duration.zero);
      expect(service.isBgmPlaying, isFalse);
      expect(service.wasBgmPlayingBeforePause, isTrue);

      // 2. Retour au premier plan (resumed) -> relance automatiquement le BGM
      service.didChangeAppLifecycleState(AppLifecycleState.resumed);
      await Future<void>.delayed(Duration.zero);
      expect(service.isBgmPlaying, isTrue);
      expect(service.wasBgmPlayingBeforePause, isFalse);
    });
  });

  group('GlobalSettingsButton & Audio Settings Widget Tests', () {
    testWidgets('affiche la roue crantée globale et ouvre SettingsOverlayDialog avec le Slider de volume', (tester) async {
      final service = AudioService.instance;
      await service.init();
      await service.setVolumeLevel(3);

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<LocaleController>.value(
              value: LocaleController.instance,
            ),
            ChangeNotifierProvider<AccessControlProvider>.value(
              value: AccessControlProvider.instance,
            ),
          ],
          child: MaterialApp(
            home: Scaffold(
              appBar: AppBar(
                actions: const [
                  GlobalSettingsButton(),
                ],
              ),
            ),
          ),
        ),
      );

      expect(find.byType(GlobalSettingsButton), findsOneWidget);
      expect(find.byIcon(Icons.settings_outlined), findsOneWidget);

      await tester.tap(find.byType(GlobalSettingsButton));
      await tester.pumpAndSettle();

      expect(find.byType(SettingsOverlayDialog), findsOneWidget);
      expect(find.byType(Slider), findsOneWidget);
    });
  });
}
