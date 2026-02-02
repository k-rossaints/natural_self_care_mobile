import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/plant.dart';
import '../services/api_service.dart';
import '../theme.dart';
import 'plant_detail_screen.dart';

class ProblemsIndexScreen extends StatefulWidget {
  const ProblemsIndexScreen({super.key});

  @override
  State<ProblemsIndexScreen> createState() => _ProblemsIndexScreenState();
}

class _ProblemsIndexScreenState extends State<ProblemsIndexScreen> {
  final ApiService _api = ApiService();
  
  // Données complètes
  final Map<String, List<Plant>> _problemsMap = {};
  List<String> _allKeys = []; // Toutes les clés triées (A-Z)
  
  // Données filtrées (pour la recherche)
  List<String> _filteredKeys = [];
  String _searchQuery = '';
  
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _buildIndex();
  }

  Future<void> _buildIndex() async {
    try {
      final plants = await _api.getPlants();
      final Map<String, List<Plant>> tempMap = {};

      // Inversion : Mal -> Liste de plantes
      for (var plant in plants) {
        for (var ailment in plant.ailments) {
          final cleanAilment = ailment.trim();
          if (cleanAilment.isNotEmpty) {
            if (!tempMap.containsKey(cleanAilment)) {
              tempMap[cleanAilment] = [];
            }
            tempMap[cleanAilment]!.add(plant);
          }
        }
      }

      // Tri A-Z
      final keys = tempMap.keys.toList();
      keys.sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));

      if (mounted) {
        setState(() {
          _problemsMap.addAll(tempMap);
          _allKeys = keys;
          _filteredKeys = keys; // Au début, on affiche tout
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // Filtrage
  void _runFilter(String query) {
    setState(() {
      _searchQuery = query;
      if (query.isEmpty) {
        _filteredKeys = _allKeys;
      } else {
        final q = _removeDiacritics(query.toLowerCase());
        _filteredKeys = _allKeys.where((key) {
          return _removeDiacritics(key.toLowerCase()).contains(q);
        }).toList();
      }
    });
  }

  String _removeDiacritics(String str) {
    var withDia = 'ÀÁÂÃÄÅàáâãäåÒÓÔÕÕÖØòóôõöøÈÉÊËèéêëðÇçÐÌÍÎÏìíîïÙÚÛÜùúûüÑñŠšŸÿýŽž';
    var withoutDia = 'AAAAAAaaaaaaOOOOOOOooooooEEEEeeeeeCcDIIIIiiiiUUUUuuuuNnSsYyyZz';
    for (int i = 0; i < withDia.length; i++) {
      str = str.replaceAll(withDia[i], withoutDia[i]);
    }
    return str;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('Index des problèmes', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: AppTheme.textDark,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // BARRE DE RECHERCHE
                Container(
                  color: Colors.white,
                  padding: const EdgeInsets.all(16),
                  child: TextField(
                    onChanged: _runFilter,
                    decoration: InputDecoration(
                      hintText: "Rechercher (ex: Acné, Stress...)",
                      hintStyle: TextStyle(color: Colors.grey.shade400),
                      prefixIcon: const Icon(Icons.search, color: AppTheme.teal1),
                      filled: true,
                      fillColor: const Color(0xFFF1F5F9),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                  ),
                ),

                // LA LISTE AVEC TES SECTIONS
                Expanded(
                  child: _filteredKeys.isEmpty 
                  ? Center(child: Text("Aucun problème trouvé pour \"$_searchQuery\"", style: TextStyle(color: Colors.grey.shade500)))
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _filteredKeys.length,
                      itemBuilder: (context, index) {
                        final ailmentName = _filteredKeys[index];
                        final relatedPlants = _problemsMap[ailmentName]!;
                        
                        // Gestion des lettres A, B, C...
                        final letter = ailmentName[0].toUpperCase();
                        // On affiche la lettre seulement si c'est la première ou si la précédente était différente
                        final bool showHeader = index == 0 || _filteredKeys[index - 1][0].toUpperCase() != letter;

                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // En-tête de lettre (A, B, C...)
                            if (showHeader && _searchQuery.isEmpty) // On cache les lettres si on recherche (optionnel)
                              Padding(
                                padding: const EdgeInsets.only(top: 16, bottom: 8, left: 8),
                                child: Text(
                                  letter,
                                  style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: AppTheme.teal2),
                                ),
                              ),

                            // Carte dépliante
                            Card(
                              margin: const EdgeInsets.only(bottom: 8),
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                                side: BorderSide(color: Colors.grey.shade200),
                              ),
                              child: ExpansionTile(
                                shape: const Border(), // Retire les bordures auto de Flutter
                                title: Text(
                                  ailmentName,
                                  style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.textDark),
                                ),
                                // Badge compteur
                                trailing: Container(
                                  padding: const EdgeInsets.all(6),
                                  decoration: BoxDecoration(color: AppTheme.teal1.withOpacity(0.1), shape: BoxShape.circle),
                                  child: Text(
                                    relatedPlants.length.toString(),
                                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.teal1),
                                  ),
                                ),
                                children: [
                                  // Liste des plantes
                                  ...relatedPlants.map((plant) => ListTile(
                                    contentPadding: const EdgeInsets.only(left: 16, right: 16, bottom: 8),
                                    leading: Container(
                                      width: 40, height: 40,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: Colors.grey.shade100,
                                        image: plant.image != null 
                                          ? DecorationImage(
                                              image: CachedNetworkImageProvider(_api.getImageUrl(plant.image!)),
                                              fit: BoxFit.cover
                                            )
                                          : null,
                                      ),
                                      child: plant.image == null ? const Icon(Icons.local_florist, size: 20, color: Colors.grey) : null,
                                    ),
                                    title: Text(plant.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                                    subtitle: Text(plant.scientificName ?? '', style: const TextStyle(fontStyle: FontStyle.italic, fontSize: 12)),
                                    trailing: const Icon(Icons.chevron_right, size: 18, color: Colors.grey),
                                    onTap: () {
                                      Navigator.push(context, MaterialPageRoute(builder: (context) => PlantDetailScreen(plant: plant)));
                                    },
                                  )),
                                ],
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                ),
              ],
            ),
    );
  }
}