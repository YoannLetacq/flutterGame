class CardModel {
  final String id;
  final String name;
  final String type; // "complement", "definition", "graphique", "trou"
  final String definition;
  final List<String> options;
  final List<String> hints;
  final String answer;
  final String imageUrl;
  final String explanation;

  CardModel({
    required this.id,
    required this.name,
    required this.type,
    required this.definition,
    required this.options,
    required this.hints,
    required this.answer,
    required this.imageUrl,
    required this.explanation,
  });

  factory CardModel.fromJson(Map<String, dynamic> json) {
    return CardModel(
      id: json['id'] as String,
      name: json['name'] as String,
      type: json['type'] as String,
      definition: json['definition'] as String? ?? '',
      options: List<String>.from(json['options'] ?? []),
      hints: List<String>.from(json['hints'] ?? []),
      answer: json['answer'] as String? ?? '',
      imageUrl: json['imageUrl'] as String? ?? '',
      explanation: json['explanation'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'type': type,
      'definition': definition,
      'options': options,
      'hints': hints,
      'answer': answer,
      'imageUrl': imageUrl,
      'explanation': explanation,
    };
  }
}
