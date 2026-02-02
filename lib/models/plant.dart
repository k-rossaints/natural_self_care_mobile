class Plant {
  final int id;
  final String name;
  final String? slug;
  final String? scientificName;
  final String? commonNames; // Nouveau
  final String? habitat;
  final String? image;
  final String? descriptionShort;
  final String? plantType;
  final bool isClinicallyValidated;
  final String? safetyPrecautions;
  final String? sideEffects; // Nouveau
  final String? usagePreparation;
  final String? usageDuration; // Nouveau
  final String? descriptionVisual;
  // Nouveaux champs pour l'identification
  final String? procurementPicking;
  final String? procurementBuying;
  final String? procurementCulture;
  final String? confusionRisks;
  
  final List<String> ailments;

  Plant({
    required this.id,
    required this.name,
    this.slug,
    this.scientificName,
    this.commonNames,
    this.habitat,
    this.image,
    this.descriptionShort,
    this.plantType,
    this.isClinicallyValidated = false,
    this.safetyPrecautions,
    this.sideEffects,
    this.usagePreparation,
    this.usageDuration,
    this.descriptionVisual,
    this.procurementPicking,
    this.procurementBuying,
    this.procurementCulture,
    this.confusionRisks,
    this.ailments = const [],
  });

  factory Plant.fromJson(Map<String, dynamic> json) {
    List<String> extractedAilments = [];
    if (json['linked_ailments'] != null) {
      for (var item in json['linked_ailments']) {
        if (item['ailments_id'] != null && item['ailments_id']['name'] != null) {
          extractedAilments.add(item['ailments_id']['name']);
        }
      }
    }

    return Plant(
      id: json['id'],
      name: json['name'],
      slug: json['slug'],
      scientificName: json['scientific_name'],
      commonNames: json['common_names'],
      habitat: json['habitat'],
      image: json['image'] is Map ? json['image']['id'] : json['image'],
      descriptionShort: json['description_short'],
      plantType: json['plant_type'],
      isClinicallyValidated: json['is_clinically_validated'] ?? false,
      safetyPrecautions: json['safety_precautions'],
      sideEffects: json['side_effects'],
      usagePreparation: json['usage_preparation'],
      usageDuration: json['usage_duration'],
      descriptionVisual: json['description_visual'],
      procurementPicking: json['procurement_picking'],
      procurementBuying: json['procurement_buying'],
      procurementCulture: json['procurement_culture'],
      confusionRisks: json['confusion_risks'],
      ailments: extractedAilments,
    );
  }
}

// Fonction utilitaire pour retirer les accents
String removeDiacritics(String str) {
  var withDia = 'ÀÁÂÃÄÅàáâãäåÒÓÔÕÕÖØòóôõöøÈÉÊËèéêëðÇçÐÌÍÎÏìíîïÙÚÛÜùúûüÑñŠšŸÿýŽž';
  var withoutDia = 'AAAAAAaaaaaaOOOOOOOooooooEEEEeeeeeCcDIIIIiiiiUUUUuuuuNnSsYyyZz';

  for (int i = 0; i < withDia.length; i++) {
    str = str.replaceAll(withDia[i], withoutDia[i]);
  }
  return str;
}