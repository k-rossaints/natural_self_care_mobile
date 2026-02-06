import 'package:dio/dio.dart';
import '../models/plant.dart';
import '../models/symptom.dart';
import '../models/decision_step.dart';
import '../models/reference.dart';
import '../models/generic_reference.dart';

class ApiService {
  static const String baseUrl = 'http://directus-rk4w4cskcos4kwwoc84s88ss.46.224.187.154.sslip.io';

  final Dio _dio = Dio(BaseOptions(
    baseUrl: baseUrl,
    connectTimeout: const Duration(seconds: 10),
    receiveTimeout: const Duration(seconds: 10),
  ));

  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  ApiService._internal();

  Future<List<Plant>> getPlants() async {
    try {
      final response = await _dio.get('/items/plants', queryParameters: {
        'fields': 'id,name,slug,scientific_name,common_names,habitat,image,plant_type,description_short,is_clinically_validated,safety_precautions,side_effects,usage_preparation,usage_duration,description_visual,procurement_picking,procurement_buying,procurement_culture,confusion_risks,linked_ailments.ailments_id.name',
        'sort': 'name',
        'limit': -1,
      });
      return (response.data['data'] as List).map((json) => Plant.fromJson(json)).toList();
    } catch (e) {
      print('Erreur Plants: $e');
      rethrow;
    }
  }

  // Pour la fiche plante (références spécifiques d'une plante)
  Future<List<Reference>> getReferences(int plantId) async {
    try {
      final response = await _dio.get('/items/references', queryParameters: {
        'filter[plant][_eq]': plantId,
        'fields': 'id,full_reference',
      });
      return (response.data['data'] as List).map((json) => Reference.fromJson(json)).toList();
    } catch (e) {
      return [];
    }
  }

  // Pour la page Démarche (Toutes les références + nom de la plante)
  Future<List<Reference>> getAllReferences() async {
    try {
      final response = await _dio.get('/items/references', queryParameters: {
        'fields': 'id,full_reference,plant.name', // On récupère le nom de la plante liée
        'sort': 'plant.name',
        'limit': -1,
      });
      return (response.data['data'] as List).map((json) => Reference.fromJson(json)).toList();
    } catch (e) {
      print('Erreur All Refs: $e');
      return [];
    }
  }

  // Ouvrages généraux
  Future<List<GenericReference>> getGenericReferences() async {
    try {
      final response = await _dio.get('/items/generic_references', queryParameters: {
        'fields': 'id,name',
        'sort': 'name',
        'limit': -1,
      });
      return (response.data['data'] as List).map((json) => GenericReference.fromJson(json)).toList();
    } catch (e) {
      print('Erreur Generic Refs: $e');
      return [];
    }
  }

  Future<List<Symptom>> getSymptoms() async {
    try {
      final response = await _dio.get('/items/symptoms', queryParameters: {
        'fields': 'id,name,description,additional_info,start_step',
        'sort': 'name',
      });
      return (response.data['data'] as List).map((json) => Symptom.fromJson(json)).toList();
    } catch (e) {
      rethrow;
    }
  }

  Future<List<DecisionStep>> getDecisionSteps() async {
    try {
      final response = await _dio.get('/items/decision_steps', queryParameters: {
        // On demande la structure exacte vue dans ton code VueJS
        'fields': 'id,type,content,next_step_yes,next_step_no,is_emergency,recommended_remedies.plants_id.id,recommended_remedies.plants_id.name,recommended_remedies.plants_id.slug,recommended_remedies.plants_id.image,recommended_remedies.plants_id.is_clinically_validated',
        'limit': -1,
      });
      return (response.data['data'] as List).map((json) => DecisionStep.fromJson(json)).toList();
    } catch (e) {
      print('Erreur Steps: $e');
      rethrow;
    }
  }

  /// Récupère TOUS les détails d'une plante spécifique par son ID
  Future<Plant> getPlantDetails(int id) async {
    try {
      final response = await _dio.get('/items/plants/$id', queryParameters: {
        // MODIFICATION ICI : Ajout de 'scientific_references'
        'fields': 'id,name,slug,scientific_name,common_names,habitat,image,plant_type,description_short,is_clinically_validated,safety_precautions,side_effects,usage_preparation,usage_duration,description_visual,procurement_picking,procurement_buying,procurement_culture,confusion_risks,scientific_references,linked_ailments.ailments_id.name',
      });
      return Plant.fromJson(response.data['data']);
    } catch (e) {
      print('Erreur GetPlantDetails: $e');
      rethrow;
    }
  }

  String getImageUrl(String imageId) {
    return '$baseUrl/assets/$imageId?width=600&quality=80&fit=cover';
  }
}