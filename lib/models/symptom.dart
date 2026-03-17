class Symptom {
  final int id;
  final String name;
  final String? description;
  final String? additionalInfo; // L'encadré bleu "Bon à savoir"
  final int? startStepId; // L'ID de la première question

  Symptom({
    required this.id,
    required this.name,
    this.description,
    this.additionalInfo,
    this.startStepId,
  });

  factory Symptom.fromJson(Map<String, dynamic> json) {
    return Symptom(
      id: json['id'],
      name: json['name'],
      description: json['description'],
      additionalInfo: json['additional_info'],
      startStepId: json['start_step'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'additional_info': additionalInfo,
      'start_step': startStepId,
    };
  }
}