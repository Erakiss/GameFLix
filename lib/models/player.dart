class Player {
  /// Identité du joueur (roster global) : immuable.
  final String name;
  final String gender;

  /// Score de la partie en cours : propre à une session de jeu.
  int score;

  Player({required this.name, required this.gender, this.score = 0});

  /// Copie "session" : les jeux travaillent sur ces copies, jamais sur le
  /// roster global géré par PlayersController. Les scores d'une partie ne
  /// fuient donc ni dans le Hub ni dans la partie suivante.
  Player forSession() => Player(name: name, gender: gender);

  // Pour la sauvegarde JSON
  Map<String, dynamic> toJson() => {'name': name, 'gender': gender};
  factory Player.fromJson(Map<String, dynamic> json) => Player(
        name: json['name'] as String? ?? '',
        gender: json['gender'] as String? ?? 'M',
      );
}