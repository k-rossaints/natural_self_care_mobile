class Reference {
  final int id;
  final String fullReference;
  final String? plantName; // Nouveau champ pour le tri

  Reference({
    required this.id, 
    required this.fullReference,
    this.plantName,
  });

  factory Reference.fromJson(Map<String, dynamic> json) {
    String? pName;
    if (json['plant'] != null && json['plant'] is Map) {
      pName = json['plant']['name'];
    }
    return Reference(
      id: json['id'],
      fullReference: json['full_reference'] ?? '',
      plantName: pName,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'full_reference': fullReference,
    'plant': plantName != null ? {'name': plantName} : null,
  };
}