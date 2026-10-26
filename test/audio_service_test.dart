// test/audio_service_test.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:gameflix/services/audio_service.dart';
import 'package:gameflix/shared/widgets/neon_volume_control.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
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
        expect(path.endsWith('.ogg') || path.endsWith('.wav') || path.endsWith('.mp3'), isTrue);
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
      expect(service.isMuted, isFalse, reason: 'Changer le volume doit réactiver le son');
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

  group('NeonVolumeControl Widget Tests', () {
    testWidgets('affiche le bouton néon et ouvre le mini-popover avec Slider et toggles BGM/SFX', (tester) async {
      final service = AudioService.instance;
      await service.init();
      await service.setVolumeLevel(3);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            appBar: AppBar(
              actions: const [
                NeonVolumeControl(),
              ],
            ),
          ),
        ),
      );

      // 1. Vérification du bouton NeonVolumeControl dans l'AppBar
      expect(find.byType(NeonVolumeControl), findsOneWidget);
      expect(find.byIcon(Icons.volume_up_rounded), findsOneWidget);

      // 2. Clic sur NeonVolumeControl pour ouvrir le mini-popover
      await tester.tap(find.byType(NeonVolumeControl));
      await tester.pumpAndSettle();

      expect(find.byType(NeonVolumePopoverDialog), findsOneWidget);
      expect(find.byType(Slider), findsOneWidget);
      expect(find.byType(SwitchListTile), findsNWidgets(2));
    });
  });
}
