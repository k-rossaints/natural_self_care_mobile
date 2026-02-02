import 'package:flutter/material.dart';
import 'dart:math';
import '../models/plant.dart';
import '../models/symptom.dart';
import '../screens/plant_detail_screen.dart';
import '../screens/decision_session_screen.dart';
import '../theme.dart';
import '../services/api_service.dart';

class GlobalSearchDelegate extends SearchDelegate {
  final List<Plant> plants;
  final List<Symptom> symptoms;
  final ApiService _api = ApiService();

  GlobalSearchDelegate({required this.plants, required this.symptoms});

  @override
  String get searchFieldLabel => 'Plante, symptôme, maladie...';

  @override
  ThemeData appBarTheme(BuildContext context) {
    return Theme.of(context).copyWith(
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: IconThemeData(color: AppTheme.textDark),
        titleTextStyle: TextStyle(color: AppTheme.textGrey, fontSize: 18),
      ),
      inputDecorationTheme: const InputDecorationTheme(
        border: InputBorder.none,
        hintStyle: TextStyle(color: Colors.grey),
      ),
    );
  }

  @override
  List<Widget>? buildActions(BuildContext context) {
    return [
      if (query.isNotEmpty)
        IconButton(
          icon: const Icon(Icons.clear, color: AppTheme.teal1),
          onPressed: () => query = '',
        ),
    ];
  }

  @override
  Widget? buildLeading(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.arrow_back, color: AppTheme.textDark),
      onPressed: () => close(context, null),
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    return _buildSearchResults(context);
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    return _buildSearchResults(context);
  }

  Widget _buildSearchResults(BuildContext context) {
    if (query.trim().isEmpty) {
      return _buildEmptyState();
    }

    final q = _removeDiacritics(query.toLowerCase());

    // 1. Filtrer les Plantes
    final matchingPlants = plants.where((p) {
      return _fuzzyMatch(p.name, q) ||
             _fuzzyMatch(p.scientificName ?? '', q) ||
             p.ailments.any((a) => _fuzzyMatch(a, q));
    }).toList();

    // 2. Filtrer les Symptômes (Chemins)
    // --- CORRECTION ICI : on ajoute ?? '' pour gérer le null ---
    final matchingSymptoms = symptoms.where((s) {
      return _fuzzyMatch(s.name, q) || _fuzzyMatch(s.description ?? '', q);
    }).toList();

    if (matchingPlants.isEmpty && matchingSymptoms.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off, size: 60, color: Colors.grey.shade300),
            const SizedBox(height: 10),
            Text("Aucun résultat pour \"$query\"", style: TextStyle(color: Colors.grey.shade500)),
          ],
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // SECTION SYMPTÔMES (CHEMINS)
        if (matchingSymptoms.isNotEmpty) ...[
          const Padding(
            padding: EdgeInsets.only(bottom: 8, left: 4),
            child: Text("DIAGNOSTICS & GUIDES", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey, letterSpacing: 1)),
          ),
          ...matchingSymptoms.map((s) => Card(
            margin: const EdgeInsets.only(bottom: 12),
            elevation: 0,
            color: const Color(0xFFF0F9FF),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: Colors.blue.withOpacity(0.2))),
            child: ListTile(
              leading: const CircleAvatar(backgroundColor: Colors.white, child: Icon(Icons.alt_route, color: Colors.blue)),
              title: Text(s.name, style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.textDark)),
              subtitle: Text("Lancer le diagnostic", style: TextStyle(color: Colors.blue.shade700, fontSize: 12)),
              onTap: () {
                Navigator.push(context, MaterialPageRoute(builder: (context) => DecisionSessionScreen(symptom: s)));
              },
            ),
          )),
          const SizedBox(height: 20),
        ],

        // SECTION PLANTES
        if (matchingPlants.isNotEmpty) ...[
          const Padding(
            padding: EdgeInsets.only(bottom: 8, left: 4),
            child: Text("PLANTES & REMÈDES", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey, letterSpacing: 1)),
          ),
          ...matchingPlants.map((p) => Card(
            margin: const EdgeInsets.only(bottom: 12),
            elevation: 2,
            shadowColor: Colors.black.withOpacity(0.1),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: ListTile(
              contentPadding: const EdgeInsets.all(8),
              leading: Container(
                width: 50, height: 50,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  color: Colors.grey.shade100,
                  image: p.image != null 
                      ? DecorationImage(image: NetworkImage(_api.getImageUrl(p.image!)), fit: BoxFit.cover)
                      : null,
                ),
                child: p.image == null ? const Icon(Icons.local_florist, color: Colors.grey) : null,
              ),
              title: Text(p.name, style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text(p.scientificName ?? '', style: const TextStyle(fontStyle: FontStyle.italic, fontSize: 12)),
              onTap: () {
                Navigator.push(context, MaterialPageRoute(builder: (context) => PlantDetailScreen(plant: p)));
              },
            ),
          )),
        ]
      ],
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.search, size: 80, color: Color(0xFFE0F2F1)),
          const SizedBox(height: 16),
          Text(
            "Recherchez un problème ou une plante",
            style: TextStyle(color: Colors.grey.shade400, fontSize: 16),
          ),
        ],
      ),
    );
  }

  bool _fuzzyMatch(String source, String query) {
    if (query.isEmpty) return true;
    final s = _removeDiacritics(source.toLowerCase());
    final q = query; 
    
    if (s.contains(q)) return true;
    final sourceWords = s.split(' ');
    for (var word in sourceWords) {
      if (_levenshtein(word, q) <= 2) return true; 
    }
    return false;
  }

  int _levenshtein(String s, String t) {
    if (s == t) return 0;
    if (s.isEmpty) return t.length;
    if (t.isEmpty) return s.length;
    List<int> v0 = List<int>.filled(t.length + 1, 0);
    List<int> v1 = List<int>.filled(t.length + 1, 0);
    for (int i = 0; i < t.length + 1; i++) v0[i] = i;
    for (int i = 0; i < s.length; i++) {
      v1[0] = i + 1;
      for (int j = 0; j < t.length; j++) {
        int cost = (s[i] == t[j]) ? 0 : 1;
        v1[j + 1] = min(v1[j] + 1, min(v0[j + 1] + 1, v0[j] + cost));
      }
      for (int j = 0; j < t.length + 1; j++) v0[j] = v1[j];
    }
    return v1[t.length];
  }

  String _removeDiacritics(String str) {
    var withDia = 'ÀÁÂÃÄÅàáâãäåÒÓÔÕÕÖØòóôõöøÈÉÊËèéêëðÇçÐÌÍÎÏìíîïÙÚÛÜùúûüÑñŠšŸÿýŽž';
    var withoutDia = 'AAAAAAaaaaaaOOOOOOOooooooEEEEeeeeeCcDIIIIiiiiUUUUuuuuNnSsYyyZz';
    for (int i = 0; i < withDia.length; i++) {
      str = str.replaceAll(withDia[i], withoutDia[i]);
    }
    return str;
  }
}