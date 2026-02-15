import 'package:flutter/material.dart';
import 'dart:math'; 
import 'dart:async';
import '../models/plant.dart';
import '../services/api_service.dart';
import '../widgets/plant_card.dart';
import 'plant_detail_screen.dart';
import '../theme.dart';

class RemediesListScreen extends StatefulWidget {
  const RemediesListScreen({super.key});

  @override
  State<RemediesListScreen> createState() => _RemediesListScreenState();
}

class _RemediesListScreenState extends State<RemediesListScreen> {
  final ApiService _api = ApiService();
  
  List<Plant> _allPlants = [];
  List<Plant> _filteredPlants = [];
  
  List<String> _availableAilments = [];
  List<String> _availableHabitats = []; 
  
  bool _isLoading = true;
  
  String _searchQuery = '';
  String? _selectedAilment;
  String? _selectedHabitat;

  Timer? _debounce;
  final FocusNode _searchFocus = FocusNode();

  @override
  void initState() {
    super.initState();
    _loadPlants();
  }

  Future<void> _loadPlants() async {
    try {
      final plants = await _api.getPlants();
      
      final Set<String> ailmentsSet = {};
      final Set<String> habitatsSet = {};
      
      for (var p in plants) {
        ailmentsSet.addAll(p.ailments);
        if (p.habitat != null) {
          final cleanHabitat = p.habitat!.trim();
          if (cleanHabitat.isNotEmpty) {
            habitatsSet.add(cleanHabitat);
          }
        }
      }

      if (mounted) {
        setState(() {
          _allPlants = plants;
          _filteredPlants = plants;
          _availableAilments = ailmentsSet.toList()..sort();
          _availableHabitats = habitatsSet.toList()..sort();
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // --- ALGORITHME DE RECHERCHE FLOUE ---
  bool _fuzzyMatch(String source, String query) {
    if (query.isEmpty) return true;
    final s = removeDiacritics(source.toLowerCase());
    final q = removeDiacritics(query.toLowerCase());
    
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

    for (int i = 0; i < t.length + 1; i++) {
      v0[i] = i;
    }

    for (int i = 0; i < s.length; i++) {
      v1[0] = i + 1;
      for (int j = 0; j < t.length; j++) {
        int cost = (s[i] == t[j]) ? 0 : 1;
        v1[j + 1] = min(v1[j] + 1, min(v0[j + 1] + 1, v0[j] + cost));
      }
      for (int j = 0; j < t.length + 1; j++) {
        v0[j] = v1[j];
      }
    }
    return v1[t.length];
  }

  void _runFilter() {
    setState(() {
      _filteredPlants = _allPlants.where((plant) {
        // 1. Filtre Habitat
        bool matchHabitat = true;
        if (_selectedHabitat != null) {
          matchHabitat = (plant.habitat?.trim() == _selectedHabitat);
        }

        // 2. Filtre Symptôme
        bool matchAilment = _selectedAilment == null || plant.ailments.contains(_selectedAilment);

        if (!matchAilment || !matchHabitat) return false;

        // 3. Recherche Texte
        if (_searchQuery.isEmpty) return true;

        return _fuzzyMatch(plant.name, _searchQuery) ||
               _fuzzyMatch(plant.scientificName ?? '', _searchQuery) ||
               (plant.habitat != null && _fuzzyMatch(plant.habitat!, _searchQuery)) ||
               plant.ailments.any((a) => _fuzzyMatch(a, _searchQuery));
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : CustomScrollView(
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              slivers: [
                // EN-TÊTE
                SliverAppBar(
                  expandedHeight: 80.0,
                  floating: false,
                  pinned: false,
                  backgroundColor: const Color(0xFFF8FAFC),
                  flexibleSpace: FlexibleSpaceBar(
                    titlePadding: const EdgeInsets.only(left: 20, bottom: 16),
                    centerTitle: false,
                    title: Text(
                      "Explorer les remèdes",
                      style: TextStyle(
                        color: AppTheme.textDark,
                        fontWeight: FontWeight.w800,
                        fontSize: 24,
                      ),
                    ),
                  ),
                ),

                // FILTRES COLLANTS
                SliverPersistentHeader(
                  pinned: true,
                  delegate: _StickyFilterHeaderDelegate(
                    child: Container(
                      color: const Color(0xFFF8FAFC),
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // RECHERCHE
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 5)],
                            ),
                            child: TextField(
                              focusNode: _searchFocus, //Liaison focus
                              onChanged: (val) {
                                _searchQuery = val;
                                // Logique de Debounce pour éviter de lancer la recherche à chaque frappe
                                if (_debounce?.isActive ?? false) _debounce!.cancel();
                                _debounce = Timer(const Duration(milliseconds: 300), () {
                                  _runFilter();
                                });
                              },
                              decoration: InputDecoration(
                                hintText: "Plante, symptôme, habitat...",
                                hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
                                prefixIcon: const Icon(Icons.search, color: AppTheme.teal1),
                                border: InputBorder.none,
                                contentPadding: const EdgeInsets.symmetric(vertical: 12),
                              ),
                            ),
                          ),
                          
                          const SizedBox(height: 10),

                          // DROPDOWNS
                          Row(
                            children: [
                              Expanded(
                                child: _buildDropdown(
                                  hint: "Symptôme",
                                  value: _selectedAilment,
                                  items: _availableAilments,
                                  icon: Icons.medical_services_outlined,
                                  onChanged: (val) {
                                    setState(() {
                                      _selectedAilment = val;
                                      _runFilter();
                                    });
                                  },
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: _buildDropdown(
                                  hint: "Zone géo",
                                  value: _selectedHabitat,
                                  items: _availableHabitats,
                                  icon: Icons.public,
                                  onChanged: (val) {
                                    setState(() {
                                      _selectedHabitat = val;
                                      _runFilter();
                                    });
                                  },
                                ),
                              ),
                            ],
                          ),
                          
                          const SizedBox(height: 8),
                          
                          Text(
                            "${_filteredPlants.length} plante${_filteredPlants.length > 1 ? 's' : ''} trouvée${_filteredPlants.length > 1 ? 's' : ''}",
                            style: const TextStyle(color: Colors.grey, fontSize: 12, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                    maxHeight: 160,
                    minHeight: 160,
                  ),
                ),

                // RÉSULTATS
                _filteredPlants.isEmpty
                    ? SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.only(top: 50),
                          child: Column(
                            children: [
                              Icon(Icons.search_off, size: 50, color: Colors.grey.shade300),
                              const SizedBox(height: 10),
                              Text("Aucun résultat", style: TextStyle(color: Colors.grey.shade500)),
                            ],
                          ),
                        ),
                      )
                    : SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (context, index) {
                            return PlantCard(
                              plant: _filteredPlants[index],
                              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => PlantDetailScreen(plant: _filteredPlants[index]))),
                            );
                          },
                          childCount: _filteredPlants.length,
                        ),
                      ),
                
                const SliverToBoxAdapter(child: SizedBox(height: 80)),
              ],
            ),
    );
  }

  Widget _buildDropdown({
    required String hint,
    required String? value,
    required List<String> items,
    required IconData icon,
    required Function(String?) onChanged,
  }) {
    final bool isEmpty = items.isEmpty;

    return Container(
      height: 45,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: value != null ? AppTheme.teal1.withOpacity(0.1) : (isEmpty ? Colors.grey.shade100 : Colors.white),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: value != null ? AppTheme.teal1 : Colors.grey.shade200),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          hint: Row(
            children: [
              Icon(icon, size: 16, color: isEmpty ? Colors.grey.shade300 : Colors.grey),
              const SizedBox(width: 8),
              Text(
                isEmpty ? "(Vide)" : hint, 
                style: TextStyle(fontSize: 13, color: isEmpty ? Colors.grey.shade400 : Colors.grey)
              ),
            ],
          ),
          icon: value != null 
              ? GestureDetector(
                  onTap: () => onChanged(null),
                  child: const Icon(Icons.close, size: 18, color: AppTheme.teal1)
                ) 
              : Icon(Icons.arrow_drop_down, color: isEmpty ? Colors.grey.shade300 : Colors.grey),
          isExpanded: true,
          style: TextStyle(color: value != null ? AppTheme.teal1 : Colors.black87, fontWeight: FontWeight.w600, fontSize: 13),
          items: isEmpty ? null : items.map((String item) {
            return DropdownMenuItem<String>(
              value: item,
              child: Text(item, maxLines: 1, overflow: TextOverflow.ellipsis),
            );
          }).toList(),
          onChanged: isEmpty ? null : onChanged,
        ),
      ),
    );
  }
}

// === C'EST ICI QUE J'AI REMIS LE COMPORTEMENT STANDARD ===
class _StickyFilterHeaderDelegate extends SliverPersistentHeaderDelegate {
  final Widget child;
  final double maxHeight;
  final double minHeight;

  _StickyFilterHeaderDelegate({required this.child, required this.maxHeight, required this.minHeight});

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) => SizedBox.expand(child: child);

  @override
  double get maxExtent => maxHeight;

  @override
  double get minExtent => minHeight;

  @override
  bool shouldRebuild(_StickyFilterHeaderDelegate oldDelegate) {
    // Version standard sans forçage
    return maxHeight != oldDelegate.maxExtent ||
           minHeight != oldDelegate.minExtent ||
           child != oldDelegate.child;
  }
}