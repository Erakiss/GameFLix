// lib/state/players_controller.dart
import 'dart:collection';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:gameflix/models/player.dart';

/// Résultat d'un ajout de joueur, pour que l'UI affiche le bon message.
enum AddPlayerResult { added, emptyName, duplicate }

/// Source de vérité unique pour la liste des joueurs.
///
/// - Seul ce contrôleur modifie le roster (ajout / suppression / persistance).
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
          ..addAll(decoded.map((p) => Player.fromJson(p as Map<String, dynamic>)).where((p) => p.name.isNotEmpty));
      } catch (e) {
        debugPrint('PlayersController: sauvegarde illisible ($e)');
      }
    }
    _isLoaded = true;
    notifyListeners();
  }

  AddPlayerResult add(String rawName, String gender) {
    final name = rawName.trim();
    if (name.isEmpty) return AddPlayerResult.emptyName;
    final exists = _players.any((p) => p.name.toLowerCase() == name.toLowerCase());
    if (exists) return AddPlayerResult.duplicate;

    _players.add(Player(name: name, gender: gender));
    _commit();
    return AddPlayerResult.added;
  }

  void removeAt(int index) {
    if (index < 0 || index >= _players.length) return;
    _players.removeAt(index);
    _commit();
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
