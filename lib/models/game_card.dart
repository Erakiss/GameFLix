class GameCard {
  final String type;
  final String difficulty;
  final String content;
  final String? targetGender;

  GameCard({required this.type, required this.difficulty, required this.content, this.targetGender});

  int get shots {
    switch (difficulty) {
      case 'SOFT': return 1;
      case 'FUN': return 2;
      case 'HOT': return 3;
      default: return 1;
    }
  }

  Map<String, dynamic> toJson() => {
    'type': type,
    'difficulty': difficulty,
    'content': content,
    'targetGender': targetGender,
  };

  factory GameCard.fromJson(Map<String, dynamic> json) => GameCard(
    type: json['type'],
    difficulty: json['difficulty'],
    content: json['content'],
    targetGender: json['targetGender'],
  );
}