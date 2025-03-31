class CardModel {
  final String id;
  final String name;         // Intitulé de la carte
  final String definition;   // Définition ou complément
  final int answer;          // Index de la réponse attendue
  /*
  final String explanation;  // Explication
  final List<String> hints;  // Indices (non utilisés ici)
  final String imageUrl;     // URL d'image (non utilisé ici)
   */
  final List<String> options; // Tableau de réponses proposées
  final String type;         // "definition" ou "complement"

  CardModel({
    required this.id,
    required this.name,
    required this.definition,
    required this.answer,
    required this.options,
    required this.type,
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
    };
  }
}
