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

    test('gestion du Mute et du volume', () async {
      final service = AudioService.instance;
      await service.init();

      expect(service.volume, greaterThan(0.0));
      expect(service.isMuted, isFalse);

      // 1. Toggle Mute
      await service.toggleMute();
      expect(service.isMuted, isTrue);

      // 2. Réglage du volume par palier (1 à 5)
      await service.setVolumeLevel(4);
      expect(service.isMuted, isFalse, reason: 'Changer le volume doit réactiver le son');
      expect(service.volumeLevel, 4);
      expect(service.volume, closeTo(0.8, 0.01));

      // 3. Toggle Mute à nouveau
      await service.toggleMute();
      expect(service.isMuted, isTrue);

      await service.toggleMute();
      expect(service.isMuted, isFalse);
    });
  });

  group('NeonVolumeControl Widget Tests', () {
    testWidgets('affiche l\'icône de son et les 5 barres verticales de volume', (tester) async {
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

      // 1. Vérification de l'icône de volume
      expect(find.byIcon(Icons.volume_up), findsOneWidget);

      // 2. Vérification des 5 barres (détectées par clé ou layout)
      expect(find.byType(NeonVolumeControl), findsOneWidget);

      // 3. Clic sur le bouton de volume pour muter
      await tester.tap(find.byIcon(Icons.volume_up));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.volume_off), findsOneWidget);
      expect(service.isMuted, isTrue);
    });
  });
}
