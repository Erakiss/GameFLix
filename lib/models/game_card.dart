// lib/models/game_card.dart

/// Modèle représentant une carte de jeu (Action ou Vérité, Custom, etc.).
class GameCard {
  final String type;
  final String difficulty;
  final String content;
  final String? targetGender;

  /// Tag optionnel indiquant qu'une carte implique un gage rapproché / tactile.
  /// S'il est absent du JSON (`null`), vaut `false` par défaut.
  final bool isTactile;

  GameCard({
    required this.type,
    required this.difficulty,
    required this.content,
    this.targetGender,
    bool? isTactile,
  }) : isTactile = isTactile ?? false;

  /// Indique si cette carte requiert un matchmaking compatible entre 2 joueurs :
  /// vrai pour toute carte de catégorie HOT / SPICY ou taggée `isTactile: true`.
  bool get requiresCompatibleTarget =>
      difficulty.toUpperCase() == 'HOT' ||
      difficulty.toUpperCase() == 'SPICY' ||
      isTactile;

  /// Indique si le texte de la carte cible un second joueur via `{TARGET}`.
  bool get hasTargetPlaceholder => content.contains('{TARGET}');

  int get shots {
    switch (difficulty) {
      case 'SOFT':
        return 1;
      case 'FUN':
        return 2;
      case 'HOT':
        return 3;
      default:
        return 1;
    }
  }

  Map<String, dynamic> toJson() => {
        'type': type,
        'difficulty': difficulty,
        'content': content,
        'targetGender': targetGender,
        if (isTactile) 'isTactile': isTactile,
      };

  factory GameCard.fromJson(Map<String, dynamic> json) => GameCard(
        type: json['type'] as String? ?? 'ACTION',
        difficulty: json['difficulty'] as String? ?? 'SOFT',
        content: json['content'] as String? ?? '',
        targetGender: json['targetGender'] as String?,
        isTactile: json['isTactile'] as bool? ?? false,
      );
}
