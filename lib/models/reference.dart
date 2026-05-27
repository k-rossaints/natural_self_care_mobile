/*
  Référence bibliographique associée à une plante spécifique.
  Le champ plantName est extrait de l'objet imbriqué plant retourné par l'API,
  et utilisé pour trier les références par plante dans l'écran Démarche scientifique
  et pour reconstituer le lien plante-référence depuis le cache local.
*/
class Reference {
  final int id;
  final String fullReference;
  final String? plantName;

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

  // plantName est resérialisé sous forme d'objet pour rester compatible
  // avec la structure attendue par fromJson lors de la relecture du cache.
  Map<String, dynamic> toJson() => {
    'id': id,
    'full_reference': fullReference,
    'plant': plantName != null ? {'name': plantName} : null,
  };
}