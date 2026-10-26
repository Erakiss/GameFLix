// lib/state/players_controller.dart
import 'dart:collection';
import 'dart:convert';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:gameflix/models/player.dart';

/// Résultat d'un ajout de joueur, pour que l'UI affiche le bon message.
enum AddPlayerResult { added, emptyName, duplicate }

/// Source de vérité unique pour la liste des joueurs et le matchmaking des gages.
///
/// - Seul ce contrôleur modifie le roster (ajout / suppression / cibles / persistance).
/// - Les écrans lisent via `context.watch<PlayersController>()`.
/// - Les jeux reçoivent des copies via [sessionPlayers] : aucune mutation
///   inter-écrans possible sur le roster global.
class PlayersController extends ChangeNotifier {
  static const String _prefsKey = 'saved_players';

  final List<Player> _players = [];
  bool _isLoaded = false;

  UnmodifiableListView<Player> get players => UnmodifiableListView(_players);
  int get count => _players.length;
  bool get isLoaded => _isLoaded;

  /// Copies fraîches (score = 0) à passer à un lobby / jeu.
  List<Player> sessionPlayers() => _players.map((p) => p.forSession()).toList();

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final String? saved = prefs.getString(_prefsKey);
    if (saved != null) {
      try {
        final List<dynamic> decoded = jsonDecode(saved);
        _players
          ..clear()
          ..addAll(
            decoded
                .map((p) => Player.fromJson(p as Map<String, dynamic>))
                .where((p) => p.name.isNotEmpty),
          );
      } catch (e) {
        debugPrint('PlayersController: sauvegarde illisible ($e)');
      }
    }
    _isLoaded = true;
    notifyListeners();
  }

  /// Ajoute un joueur avec son genre et ses cibles acceptées pour les gages rapprochés.
  AddPlayerResult add(String rawName, String gender, {Set<String>? attractedTo}) {
    // 1. Nettoyage et validation du nom
    final name = rawName.trim();
    if (name.isEmpty) return AddPlayerResult.emptyName;

    // 2. Vérification de l'unicité (insensible à la casse)
    final exists = _players.any((p) => p.name.toLowerCase() == name.toLowerCase());
    if (exists) return AddPlayerResult.duplicate;

    // 3. Ajout au roster et persistance
    _players.add(Player(name: name, gender: gender, attractedTo: attractedTo));
    _commit();
    return AddPlayerResult.added;
  }

  /// Modifie les cibles acceptées d'un joueur existant.
  void updatePlayerTargets(int index, Set<String> newTargets) {
    if (index < 0 || index >= _players.length || newTargets.isEmpty) return;
    _players[index] = _players[index].copyWith(attractedTo: newTargets);
    _commit();
  }

  /// Bascule rapidement les cibles d'un joueur dans la liste :
  /// `[♀ uniquement] -> [♂ uniquement] -> [♂ et ♀] -> [♀ uniquement]`.
  void cyclePlayerTargets(int index) {
    if (index < 0 || index >= _players.length) return;
    final current = _players[index].attractedTo;
    final bool hasM = current.contains('M');
    final bool hasF = current.contains('F');

    final Set<String> nextTargets;
    if (hasF && !hasM) {
      nextTargets = const {'M'};
    } else if (hasM && !hasF) {
      nextTargets = const {'M', 'F'};
    } else {
      nextTargets = const {'F'};
    }

    updatePlayerTargets(index, nextTargets);
  }

  void removeAt(int index) {
    if (index < 0 || index >= _players.length) return;
    _players.removeAt(index);
    _commit();
  }

  // --- MOTEUR DE MATCHMAKING DES GAGES À 2 JOUEURS ---

  /// Vérifie s'il existe au moins une paire mutuellement compatible dans [pool].
  static bool hasAnyCompatiblePair(List<Player> pool) {
    for (int i = 0; i < pool.length; i++) {
      for (int j = i + 1; j < pool.length; j++) {
        if (pool[i].isCompatibleWith(pool[j])) {
          return true;
        }
      }
    }
    return false;
  }

  /// Sélectionne un partenaire cible pour [currentPlayer] dans [pool] :
  /// - Si `requireCompatibility == false` (gage amical/normal) : n'importe quel autre joueur.
  /// - Si `requireCompatibility == true` (gage Hot/Spicy ou `isTactile: true`) :
  ///   uniquement un joueur mutuellement compatible avec [currentPlayer] (ou `null` si aucun).
  static Player? pickTargetFor(
    Player currentPlayer,
    List<Player> pool, {
    bool requireCompatibility = false,
    Random? rng,
  }) {
    final random = rng ?? Random();
    final others = pool
        .where((p) => p.name.toLowerCase() != currentPlayer.name.toLowerCase())
        .toList();
    if (others.isEmpty) return null;

    if (!requireCompatibility) {
      return others[random.nextInt(others.length)];
    }

    final compatible = others.where((p) => currentPlayer.isCompatibleWith(p)).toList();
    if (compatible.isEmpty) return null;
    return compatible[random.nextInt(compatible.length)];
  }

  /// Sélectionne un duo `(joueurActif, joueurCible)` avec Fallback en 2 étapes :
  /// 1. Tente de trouver un partenaire pour [primary] (compatible si [requireCompatibility]).
  /// 2. Fallback étape 1 : si [primary] n'a aucun partenaire compatible, cherche une autre
  ///    paire compatible `(A, B)` dans [pool].
  /// 3. Fallback étape 2 : si aucune paire compatible n'existe dans tout le groupe,
  ///    retourne `null` pour que le jeu pioche une carte solo ou non-tactile.
  static (Player, Player)? pickCompatiblePair(
    List<Player> pool, {
    Player? primary,
    bool requireCompatibility = false,
    Random? rng,
  }) {
    if (pool.length < 2) return null;
    final random = rng ?? Random();

    // 1. Recherche directe pour le joueur principal
    if (primary != null) {
      final partner = pickTargetFor(
        primary,
        pool,
        requireCompatibility: requireCompatibility,
        rng: random,
      );
      if (partner != null) {
        return (primary, partner);
      }
    }

    // 2. Si pas de filtre tactile, n'importe quelle paire distincte convient
    if (!requireCompatibility) {
      final first = primary ?? pool[random.nextInt(pool.length)];
      final second = pickTargetFor(first, pool, requireCompatibility: false, rng: random);
      return second != null ? (first, second) : null;
    }

    // 3. Fallback étape 1 : chercher toutes les paires compatibles dans le groupe
    final List<(Player, Player)> allCompatiblePairs = [];
    for (int i = 0; i < pool.length; i++) {
      for (int j = 0; j < pool.length; j++) {
        if (i != j && pool[i].isCompatibleWith(pool[j])) {
          allCompatiblePairs.add((pool[i], pool[j]));
        }
      }
    }

    if (allCompatiblePairs.isNotEmpty) {
      return allCompatiblePairs[random.nextInt(allCompatiblePairs.length)];
    }

    // 4. Fallback étape 2 : aucune paire compatible dans la session -> retourne null
    return null;
  }

  void _commit() {
    notifyListeners();
    _save();
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefsKey, jsonEncode(_players.map((p) => p.toJson()).toList()));
  }
}
