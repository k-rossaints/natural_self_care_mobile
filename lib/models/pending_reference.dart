// Référence en cours de validation scientifique.
// Regroupe une affirmation (claim) et les données disponibles à ce jour,
// affichées dans l'écran Démarche scientifique pour indiquer les limites actuelles des preuves.
class PendingReference {
  final int id;
  final String topic;
  final String claim;
  final String scientificData;

  PendingReference({
    required this.id,
    required this.topic,
    required this.claim,
    required this.scientificData,
  });

  factory PendingReference.fromJson(Map<String, dynamic> json) {
    return PendingReference(
      id: json['id'],
      topic: json['topic'] ?? 'Sujet inconnu',
      claim: json['claim'] ?? '',
      scientificData: json['scientific_data'] ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'topic': topic,
    'claim': claim,
    'scientific_data': scientificData,
  };
}