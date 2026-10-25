// test/pack_loader_test.dart
import 'dart:convert';
import 'dart:io';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gameflix/models/game_pack.dart';
import 'package:gameflix/services/pack_loader_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

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

  group('Manifest JSON File Integrity', () {
    test('le fichier packs_manifest.json est valide et recense les 6 jeux', () {
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
    });
  });

  group('PackLoaderService', () {
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

    test('loadCards parse le contenu JSON vers des objets typés', () async {
      final mockCardsJson = jsonEncode([
        {'word': 'TEST1'},
        {'word': 'TEST2'},
      ]);

      final mockBundle = _MockAssetBundle({'assets/data/test_cards.json': mockCardsJson});
      final service = PackLoaderService(bundle: mockBundle);

      const testPack = GamePack(
        id: 'test',
        gameId: 'test_game',
        title: 'Test',
        filePath: 'assets/data/test_cards.json',
      );

      final cards = await service.loadCards<String>(
        testPack,
        (json) => json['word'] as String,
      );

      expect(cards, ['TEST1', 'TEST2']);
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
