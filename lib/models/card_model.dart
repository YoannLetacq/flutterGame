class CardModel {
  final String id;
  final String name;         // Intitulé de la carte
  final String definition;   // Définition ou complément
  final int answer;          // Index de la réponse attendue
  final String explanation;  //  explanation est le champ explicatif pour le learning screen
  final String imageUrl;     // imageUrl est le champ d'image pour le learning screen
  final List<String> options; // Tableau de réponses proposées
  final String type;         // "definition" ou "complement"

  CardModel({
    required this.id,
    required this.name,
    required this.definition,
    required this.answer,
    required this.options,
    required this.type,
    required this.explanation,
    required this.imageUrl,
  });

  factory CardModel.fromJson(Map<String, dynamic> json) {
    return CardModel(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      definition: json['definition'] as String? ?? '',
      answer: int.tryParse(json['answer'].toString()) ?? 0,
      options: json['options'] is List
          ? List<String>.from(json['options'])
          : (json['options'] is String ? [json['options'] as String] : []),
      type: json['type'] as String? ?? '',
      explanation: json['explaination'] as String? ?? '',
      imageUrl: json['imageUrl'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'definition': definition,
      'answer': answer,
      'options': options,
      'type': type,
      'explaination': explanation,
      'imageUrl': imageUrl,
    };
  }
}
