// lib/models/game_pack.dart

/// Métadonnées d'un pack de questions ou cartes pour un mini-jeu.
class GamePack {
  /// Identifiant technique unique du pack (ex: 'tod_classic', 'nhie_spicy')
  final String id;

  /// Identifiant du mini-jeu auquel appartient ce pack (ex: 'tod', 'nhie', etc.)
  final String gameId;

  /// Nom d'affichage du pack (ex: 'Pack Classique', 'Pack Spicy')
  final String title;

  /// Description courte du contenu du pack
  final String description;

  /// Vrai si le pack est verrouillé (requiert abonnement ou pub récompensée)
  final bool isPremium;

  /// Chemin relatif vers le fichier de données JSON dans les assets
  final String filePath;

  const GamePack({
    required this.id,
    required this.gameId,
    required this.title,
    this.description = '',
    this.isPremium = false,
    required this.filePath,
  });

  // --- SÉRIALISATION JSON ---

  factory GamePack.fromJson(Map<String, dynamic> json) => GamePack(
        id: json['id'] as String? ?? '',
        gameId: json['gameId'] as String? ?? '',
        title: json['title'] as String? ?? '',
        description: json['description'] as String? ?? '',
        isPremium: json['isPremium'] as bool? ?? false,
        filePath: json['filePath'] as String? ?? '',
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'gameId': gameId,
        'title': title,
        'description': description,
        'isPremium': isPremium,
        'filePath': filePath,
      };
}
