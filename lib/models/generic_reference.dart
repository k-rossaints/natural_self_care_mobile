// Référence bibliographique générique, non associée à une plante spécifique.
// Utilisée dans l'écran Démarche scientifique.
class GenericReference {
  final int id;
  final String name;

  GenericReference({required this.id, required this.name});

  factory GenericReference.fromJson(Map<String, dynamic> json) {
    return GenericReference(id: json['id'], name: json['name'] ?? '');
  }

  Map<String, dynamic> toJson() => {'id': id, 'name': name};
}