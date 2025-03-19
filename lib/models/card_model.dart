class CardModel {
  final String id;
  final String name;
  final String definition;
  final String answer;
  final String explanation;
  final List<String> hints;
  final String imageUrl;
  final List<String> options;
  final String type;

  CardModel({
    required this.id,
    required this.name,
    required this.definition,
    required this.answer,
    required this.explanation,
    required this.hints,
    required this.imageUrl,
    required this.options,
    required this.type,
  });

  factory CardModel.fromJson(Map<String, dynamic> json) {
    return CardModel(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      definition: json['definition'] as String? ?? '',
      answer: json['answer'] as String? ?? '',
      explanation: json['explanation'] as String? ?? '',
      hints: json['hints'] is List
          ? List<String>.from(json['hints'])
          : [],
      imageUrl: json['imageUrl'] as String? ?? '',
      options: json['options'] is List
          ? List<String>.from(json['options'])
          : (json['options'] is String ? [json['options'] as String] : []),
      type: json['type'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'definition': definition,
      'answer': answer,
      'explanation': explanation,
      'hints': hints,
      'imageUrl': imageUrl,
      'options': options,
      'type': type,
    };
  }
}
