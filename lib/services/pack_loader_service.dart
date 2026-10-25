// lib/services/pack_loader_service.dart
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:gameflix/models/game_pack.dart';

/// Service centralisé de chargement et gestion des packs de données JSON.
class PackLoaderService {
  /// Instance singleton par défaut pour l'application
  static final PackLoaderService instance = PackLoaderService();

  final AssetBundle _bundle;
  List<GamePack>? _cachedManifest;

  PackLoaderService({AssetBundle? bundle}) : _bundle = bundle ?? rootBundle;

  // --- CHARGEMENT DU MANIFESTE CENTRAL ---

  /// Charge et parse le manifeste `assets/data/packs_manifest.json`.
  /// Met en cache le résultat pour éviter les lectures disques répétées.
  Future<List<GamePack>> loadManifest({bool reload = false}) async {
    if (_cachedManifest != null && !reload) {
      return _cachedManifest!;
    }

    try {
      // 1. Lecture du fichier JSON dans les assets
      final String jsonString = await _bundle.loadString('assets/data/packs_manifest.json');

      // 2. Décodage de la liste
      final List<dynamic> jsonList = jsonDecode(jsonString) as List<dynamic>;

      // 3. Transformation en liste de GamePack
      _cachedManifest = jsonList
          .map((item) => GamePack.fromJson(item as Map<String, dynamic>))
          .toList();

      return _cachedManifest!;
    } catch (e) {
      debugPrint('Erreur lors du chargement du manifeste de packs: $e');
      return [];
    }
  }

  /// Retourne tous les packs associés à un mini-jeu spécifique.
  Future<List<GamePack>> getPacksForGame(String gameId) async {
    final manifest = await loadManifest();
    return manifest.where((pack) => pack.gameId == gameId).toList();
  }

  /// Recherche un pack par son identifiant unique.
  Future<GamePack?> getPackById(String packId) async {
    final manifest = await loadManifest();
    try {
      return manifest.firstWhere((pack) => pack.id == packId);
    } catch (_) {
      return null;
    }
  }

  // --- CHARGEMENT DU CONTENU DES CARTES ---

  /// Charge et désérialise les cartes d'un pack spécifique.
  Future<List<T>> loadCards<T>(
    GamePack pack,
    T Function(Map<String, dynamic> json) fromJson,
  ) async {
    try {
      // 1. Lecture du fichier de données
      final String rawJson = await _bundle.loadString(pack.filePath);

      // 2. Décodage du tableau d'éléments
      final List<dynamic> data = jsonDecode(rawJson) as List<dynamic>;

      // 3. Conversion typée de chaque carte
      return data
          .map((item) => fromJson(item as Map<String, dynamic>))
          .toList();
    } catch (e) {
      debugPrint('Erreur lors du chargement des cartes (${pack.filePath}): $e');
      return [];
    }
  }

  /// Charge l'ensemble des cartes d'un jeu (tous ses packs gratuits par défaut).
  Future<List<T>> loadCardsForGame<T>(
    String gameId,
    T Function(Map<String, dynamic> json) fromJson, {
    bool includePremium = false,
  }) async {
    // 1. Récupération des packs enregistrés pour ce jeu
    final packs = await getPacksForGame(gameId);
    final List<T> allCards = [];

    // 2. Chargement séquentiel de chaque pack éligible
    for (final pack in packs) {
      if (!includePremium && pack.isPremium) continue;
      final cards = await loadCards(pack, fromJson);
      allCards.addAll(cards);
    }

    // 3. Retour de la collection assemblée
    return allCards;
  }
}
