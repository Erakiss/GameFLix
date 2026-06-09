class Player {
  String name;
  String gender;
  int score;
  Player({required this.name, required this.gender, this.score = 0});

  // Pour la sauvegarde JSON
  Map<String, dynamic> toJson() => {'name': name, 'gender': gender};
  factory Player.fromJson(Map<String, dynamic> json) => Player(name: json['name'], gender: json['gender']);
}