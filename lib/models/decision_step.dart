import 'package:flutter/foundation.dart';
import 'plant.dart';

class DecisionStep {
  final int id;
  final String type; // 'question' ou 'result'
  final String content;
  final int? nextStepYes;
  final int? nextStepNo;
  final bool isEmergency;
  // On change ici : c'est une liste de plantes
  final List<Plant> recommendedPlants;

  DecisionStep({
    required this.id,
    required this.type,
    required this.content,
    this.nextStepYes,
    this.nextStepNo,
    this.isEmergency = false,
    this.recommendedPlants = const [],
  });

  factory DecisionStep.fromJson(Map<String, dynamic> json) {
    // Extraction de la liste des plantes depuis la structure imbriquée de Directus
    // structure API : recommended_remedies[ { plants_id: { ... } }, ... ]
    // structure cache : saved_plants[ { id, name, ... }, ... ]
    List<Plant> extractedPlants = [];

    if (json['recommended_remedies'] != null && json['recommended_remedies'] is List) {
      for (var item in json['recommended_remedies']) {
        if (item['plants_id'] != null && item['plants_id'] is Map) {
          try {
            extractedPlants.add(Plant.fromJson(item['plants_id']));
          } catch (e) {
            debugPrint("Erreur parsing plante dans step: $e");
          }
        }
      }
    } else if (json['saved_plants'] != null && json['saved_plants'] is List) {
      // Chargement depuis le cache offline (toJson sauvegarde sous 'saved_plants')
      for (var item in json['saved_plants']) {
        if (item is Map<String, dynamic>) {
          try {
            extractedPlants.add(Plant.fromJson(item));
          } catch (e) {
            debugPrint("Erreur parsing plante depuis cache: $e");
          }
        }
      }
    }

    return DecisionStep(
      id: json['id'],
      type: json['type'] ?? 'question',
      content: json['content'] ?? '',
      nextStepYes: json['next_step_yes'],
      nextStepNo: json['next_step_no'],
      isEmergency: json['is_emergency'] ?? false,
      recommendedPlants: extractedPlants,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type,
      'content': content,
      'next_step_yes': nextStepYes,
      'next_step_no': nextStepNo,
      'is_emergency': isEmergency,
      // Sauvegarde au format API (recommended_remedies) pour que fromJson les relise directement
      'recommended_remedies': recommendedPlants.map((p) => {'plants_id': p.toJson()}).toList(),
      // Garde aussi saved_plants pour compatibilite avec anciens caches
      'saved_plants': recommendedPlants.map((p) => p.toJson()).toList(),
    };
  }
}