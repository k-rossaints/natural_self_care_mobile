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
}