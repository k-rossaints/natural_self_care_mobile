import 'package:flutter/foundation.dart';
import 'plant.dart';

class DecisionStep {
  final int id;
  final String type; // 'question' ou 'result'
  final String content;
  final int? nextStepYes;
  final int? nextStepNo;
  final bool isEmergency;
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

  /*
    Désérialisation depuis deux sources possibles :
    - API Directus : structure imbriquée recommended_remedies[{plants_id: {...}}]
    - Cache local : structure aplatie saved_plants[{id, name, ...}]
    Les deux chemins alimentent la même liste extractedPlants.
  */
  factory DecisionStep.fromJson(Map<String, dynamic> json) {
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

  /*
    Les plantes sont sérialisées dans les deux formats simultanément :
    - recommended_remedies : format API, permet à fromJson de les relire directement
    - saved_plants : format aplati, maintenu pour la compatibilité avec les anciens caches
  */
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type,
      'content': content,
      'next_step_yes': nextStepYes,
      'next_step_no': nextStepNo,
      'is_emergency': isEmergency,
      'recommended_remedies': recommendedPlants.map((p) => {'plants_id': p.toJson()}).toList(),
      'saved_plants': recommendedPlants.map((p) => p.toJson()).toList(),
    };
  }
}