class GenericReference {
  final int id;
  final String name;

  GenericReference({required this.id, required this.name});

  factory GenericReference.fromJson(Map<String, dynamic> json) {
    return GenericReference(
      id: json['id'],
      name: json['name'] ?? '',
    );
  }
}