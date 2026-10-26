// lib/models/player.dart

/// Modèle représentant un joueur dans GameFlix.
class Player {
  /// Identité du joueur (roster global) : immuable.
  final String name;
  final String gender;

  /// Genres acceptés par ce joueur pour les gages rapprochés / tactiles ('M', 'F' ou les deux).
  final Set<String> attractedTo;

  /// Score de la partie en cours : propre à une session de jeu.
  int score;

  Player({
    required this.name,
    required this.gender,
    Set<String>? attractedTo,
    this.score = 0,
  }) : attractedTo = (attractedTo != null && attractedTo.isNotEmpty)
            ? Set<String>.unmodifiable(attractedTo)
            : Set<String>.unmodifiable(defaultTargetsForGender(gender));

  /// Retourne la cible par défaut (genre opposé) selon le genre du joueur.
  static Set<String> defaultTargetsForGender(String gender) {
    return gender == 'M' ? const {'F'} : const {'M'};
  }

  /// Vérifie la compatibilité mutuelle entre deux joueurs pour un gage rapproché / tactile :
  /// `this` accepte le genre de [other] ET [other] accepte le genre de `this`.
  bool isCompatibleWith(Player other) {
    if (identical(this, other) || name.toLowerCase() == other.name.toLowerCase()) {
      return false;
    }
    return attractedTo.contains(other.gender) && other.attractedTo.contains(gender);
  }

  /// Libellé visuel compact des cibles acceptées (ex: '→ ♀', '→ ♂', '→ ♂♀').
  String get targetBadgeLabel {
    final bool hasM = attractedTo.contains('M');
    final bool hasF = attractedTo.contains('F');
    if (hasM && hasF) return '→ ♂♀';
    if (hasM) return '→ ♂';
    return '→ ♀';
  }

  /// Copie "session" : les jeux travaillent sur ces copies, jamais sur le
  /// roster global géré par PlayersController. Les scores d'une partie ne
  /// fuient donc ni dans le Hub ni dans la partie suivante.
  Player forSession() => Player(
        name: name,
        gender: gender,
        attractedTo: Set<String>.from(attractedTo),
      );

  /// Crée une copie modifiée du joueur.
  Player copyWith({
    String? name,
    String? gender,
    Set<String>? attractedTo,
    int? score,
  }) {
    return Player(
      name: name ?? this.name,
      gender: gender ?? this.gender,
      attractedTo: attractedTo ?? this.attractedTo,
      score: score ?? this.score,
    );
  }

  // Pour la sauvegarde JSON (avec rétrocompatibilité des profils existants)
  Map<String, dynamic> toJson() => {
        'name': name,
        'gender': gender,
        'attractedTo': attractedTo.toList(),
      };

  factory Player.fromJson(Map<String, dynamic> json) {
    final String parsedGender = json['gender'] as String? ?? 'M';
    final dynamic rawTargets = json['attractedTo'];
    Set<String>? parsedTargets;
    if (rawTargets is List) {
      final filtered = rawTargets
          .whereType<String>()
          .where((g) => g == 'M' || g == 'F')
          .toSet();
      if (filtered.isNotEmpty) {
        parsedTargets = filtered;
      }
    }

    return Player(
      name: json['name'] as String? ?? '',
      gender: parsedGender,
      attractedTo: parsedTargets ?? defaultTargetsForGender(parsedGender),
    );
  }
}
