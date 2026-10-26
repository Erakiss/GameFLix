// test/pack_loader_test.dart
import 'dart:convert';
import 'dart:io';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:gameflix/l10n/locale_controller.dart';
import 'package:gameflix/models/game_pack.dart';
import 'package:gameflix/services/pack_loader_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    LocaleController.instance.resetForTest();
  });

  group('GamePack Model', () {
    test('sérialisation et désérialisation JSON', () {
      final jsonMap = {
        'id': 'tod_spicy',
        'gameId': 'tod',
        'title': 'Pack Spicy',
        'description': 'Questions très osées',
        'isPremium': true,
        'filePath': 'assets/data/tod_spicy.json',
      };

      final pack = GamePack.fromJson(jsonMap);
      expect(pack.id, 'tod_spicy');
      expect(pack.gameId, 'tod');
      expect(pack.title, 'Pack Spicy');
      expect(pack.description, 'Questions très osées');
      expect(pack.isPremium, isTrue);
      expect(pack.filePath, 'assets/data/tod_spicy.json');

      final serialized = pack.toJson();
      expect(serialized, jsonMap);
    });
  });

  group('Manifest JSON File Integrity & Localized Samples', () {
    test('le fichier packs_manifest.json est valide et les échantillons FR/EN/ES existent', () {
      final file = File('assets/data/packs_manifest.json');
      expect(file.existsSync(), isTrue, reason: 'Le manifeste doit exister sur le disque');

      final content = file.readAsStringSync();
      final List<dynamic> list = jsonDecode(content);
      expect(list.length, greaterThanOrEqualTo(6));

      final gameIds = list.map((item) => item['gameId']).toSet();
      expect(gameIds.containsAll(['tod', 'nhie', 'imp', 'wyr', 'code', 'board']), isTrue);

      for (final item in list) {
        final filePath = item['filePath'] as String;
        expect(File(filePath).existsSync(), isTrue, reason: 'Le fichier $filePath doit exister');
      }

      // Vérifie la présence des sous-dossiers FR / EN / ES et des échantillons
      expect(File('assets/data/fr/cards.json').existsSync(), isTrue);
      expect(File('assets/data/en/cards.json').existsSync(), isTrue);
      expect(File('assets/data/es/cards.json').existsSync(), isTrue);
    });
  });

  group('PackLoaderService & i18n Fallback', () {
    test('charge le manifeste et filtre par gameId avec bundle personnalisé', () async {
      final mockManifestJson = jsonEncode([
        {'id': 'tod_1', 'gameId': 'tod', 'title': 'T1', 'filePath': 'path1'},
        {'id': 'tod_2', 'gameId': 'tod', 'title': 'T2', 'isPremium': true, 'filePath': 'path2'},
        {'id': 'nhie_1', 'gameId': 'nhie', 'title': 'N1', 'filePath': 'path3'},
      ]);

      final mockBundle = _MockAssetBundle({'assets/data/packs_manifest.json': mockManifestJson});
      final service = PackLoaderService(bundle: mockBundle);

      final allPacks = await service.loadManifest();
      expect(allPacks.length, 3);

      final todPacks = await service.getPacksForGame('tod');
      expect(todPacks.length, 2);
      expect(todPacks.map((p) => p.id), containsAll(['tod_1', 'tod_2']));

      final nhiePacks = await service.getPacksForGame('nhie');
      expect(nhiePacks.length, 1);
      expect(nhiePacks.first.id, 'nhie_1');
    });

    test('loadCards charge la langue demandée (en/es) et fait un fallback automatique sur fr/', () async {
      final frCardsJson = jsonEncode([
        {'word': 'FR_MOT'},
      ]);
      final enCardsJson = jsonEncode([
        {'word': 'EN_WORD'},
      ]);

      final mockBundle = _MockAssetBundle({
        'assets/data/fr/test_cards.json': frCardsJson,
        'assets/data/en/test_cards.json': enCardsJson,
      });
      final service = PackLoaderService(bundle: mockBundle);

      const testPack = GamePack(
        id: 'test',
        gameId: 'test_game',
        title: 'Test',
        filePath: 'assets/data/test_cards.json',
      );

      // 1. Chargement en anglais (fichier existant dans assets/data/en/)
      final enCards = await service.loadCards<String>(
        testPack,
        (json) => json['word'] as String,
        languageCode: 'en',
      );
      expect(enCards, ['EN_WORD']);

      // 2. Chargement en espagnol (fichier absent dans assets/data/es/ -> fallback sur assets/data/fr/)
      final esFallbackCards = await service.loadCards<String>(
        testPack,
        (json) => json['word'] as String,
        languageCode: 'es',
      );
      expect(esFallbackCards, ['FR_MOT']);
    });

    test('LocaleController persiste la langue choisie dans SharedPreferences', () async {
      final ctrl = LocaleController.instance;
      await ctrl.load();
      expect(ctrl.currentLocale, AppLocale.fr);

      await ctrl.setLocale(AppLocale.es);
      expect(ctrl.currentLocale, AppLocale.es);
      expect(ctrl.flag, '🇪🇸');

      ctrl.resetForTest();
      await ctrl.load();
      expect(ctrl.currentLocale, AppLocale.es);
    });
  });
}

class _MockAssetBundle extends CachingAssetBundle {
  final Map<String, String> files;

  _MockAssetBundle(this.files);

  @override
  Future<String> loadString(String key, {bool cache = true}) async {
    if (files.containsKey(key)) {
      return files[key]!;
    }
    throw Exception('Asset introuvable : $key');
  }

  @override
  Future<ByteData> load(String key) async {
    final str = await loadString(key);
    final bytes = utf8.encode(str);
    return ByteData.view(Uint8List.fromList(bytes).buffer);
  }
}
