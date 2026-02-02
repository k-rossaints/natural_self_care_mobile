import 'package:flutter/material.dart';
import 'dart:async';
import '../theme.dart';
import '../services/api_service.dart';
import '../models/plant.dart';
import '../models/symptom.dart';
import 'plant_detail_screen.dart';
import 'decision_session_screen.dart';

class HomeScreen extends StatefulWidget {
  final Function(int) onTabChange;

  const HomeScreen({super.key, required this.onTabChange});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final ApiService _api = ApiService();
  
  List<Plant> _allPlants = [];
  List<Symptom> _allSymptoms = [];
  
  List<dynamic> _searchResults = [];
  bool _isSearching = false;
  bool _dataLoaded = false;
  
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocus = FocusNode();
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocus.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  Future<void> _loadData() async {
    try {
      final plants = await _api.getPlants();
      final symptoms = await _api.getSymptoms();
      if (mounted) {
        setState(() {
          _allPlants = plants;
          _allSymptoms = symptoms;
          _dataLoaded = true;
        });
      }
    } catch (e) {
      print("Erreur chargement background: $e");
    }
  }

  void _onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();

    if (query.trim().length < 3) {
      setState(() {
        _searchResults = [];
        _isSearching = false;
      });
      return;
    }

    _debounce = Timer(const Duration(milliseconds: 500), () {
      _performSearch(query);
    });
  }

  void _performSearch(String query) {
    if (!_dataLoaded) return;

    final q = _removeDiacritics(query.toLowerCase());

    // Recherche simple (contient le texte)
    final matchingPlants = _allPlants.where((p) {
      final name = _removeDiacritics(p.name.toLowerCase());
      final sci = _removeDiacritics((p.scientificName ?? '').toLowerCase());
      bool match = name.contains(q) || sci.contains(q);
      if (!match) {
        match = p.ailments.any((a) => _removeDiacritics(a.toLowerCase()).contains(q));
      }
      return match;
    }).toList();

    final matchingSymptoms = _allSymptoms.where((s) {
      final name = _removeDiacritics(s.name.toLowerCase());
      final desc = _removeDiacritics((s.description ?? '').toLowerCase());
      return name.contains(q) || desc.contains(q);
    }).toList();

    setState(() {
      _searchResults = [...matchingSymptoms, ...matchingPlants];
      _isSearching = true;
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
      body: GestureDetector(
        onTap: () {
          _searchFocus.unfocus();
          setState(() => _isSearching = false);
        },
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // --- HEADER VERT COMPLET (Texte + Barre incluse) ---
              Container(
                // Plus de hauteur fixe, il s'adapte au contenu + padding
                padding: const EdgeInsets.fromLTRB(20, 60, 20, 40), 
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [AppTheme.teal1, AppTheme.teal2],
                  ),
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(30),
                    bottomRight: Radius.circular(30),
                  ),
                ),
                child: Column(
                  children: [
                    const Text(
                      "Se soigner avec des\nremèdes naturels",
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Colors.white, height: 1.2),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      "Une base de connaissances fiable sur les plantes médicinales validées par des études cliniques.",
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 15, color: Colors.white.withOpacity(0.9), height: 1.4),
                    ),
                    
                    const SizedBox(height: 30), // Espace entre texte et barre
                    
                    // BARRE DE RECHERCHE (Directement dans le vert)
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(30),
                        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.15), blurRadius: 15, offset: const Offset(0, 8))],
                      ),
                      child: TextField(
                        controller: _searchController,
                        focusNode: _searchFocus,
                        onChanged: _onSearchChanged,
                        decoration: InputDecoration(
                          hintText: "Rechercher une plante, un mal...",
                          hintStyle: TextStyle(color: Colors.grey.shade400),
                          prefixIcon: const Icon(Icons.search, color: AppTheme.teal1),
                          suffixIcon: _searchController.text.isNotEmpty 
                            ? IconButton(icon: const Icon(Icons.close, color: Colors.grey), onPressed: () { _searchController.clear(); _onSearchChanged(''); FocusScope.of(context).unfocus(); })
                            : null,
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // LISTE DES RÉSULTATS (Apparaît juste en dessous du header vert si recherche active)
              if (_isSearching && _searchController.text.length >= 3)
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  constraints: const BoxConstraints(maxHeight: 350),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 15, offset: const Offset(0, 5))],
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: _searchResults.isEmpty 
                      ? const Padding(padding: EdgeInsets.all(20), child: Text("Aucun résultat trouvé.", style: TextStyle(color: Colors.grey)))
                      : ListView.separated(
                          padding: EdgeInsets.zero,
                          shrinkWrap: true,
                          physics: const ClampingScrollPhysics(),
                          itemCount: _searchResults.length,
                          separatorBuilder: (context, index) => const Divider(height: 1),
                          itemBuilder: (context, index) => _buildResultItem(_searchResults[index]),
                        ),
                  ),
                ),

              const SizedBox(height: 20),

              // BOUTONS D'ACTION
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  children: [
                    _buildNavCard(
                      icon: Icons.local_florist_outlined,
                      title: "Explorer les remèdes",
                      subtitle: "Rechercher par plante, usage et preuves.",
                      color: AppTheme.teal1,
                      onTap: () => widget.onTabChange(1),
                    ),
                    const SizedBox(height: 16),
                    _buildNavCard(
                      icon: Icons.alt_route_outlined,
                      title: "Chemins de décision",
                      subtitle: "Trouver une solution selon vos symptômes.",
                      color: const Color(0xFF2C3E50),
                      onTap: () => widget.onTabChange(2),
                    ),
                    const SizedBox(height: 16),
                    _buildNavCard(
                      icon: Icons.menu_book_outlined,
                      title: "Index des problèmes",
                      subtitle: "Liste de A à Z des pathologies traitées.",
                      color: const Color(0xFF2C3E50),
                      onTap: () => widget.onTabChange(3),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 40),

              Center(child: Text("NOS PARTENAIRES", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey[400], letterSpacing: 1.5))),
              const SizedBox(height: 20),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Wrap(
                  spacing: 15, runSpacing: 15, alignment: WrapAlignment.center,
                  children: [
                    _buildPartnerLogo('assets/partner1.jpg'),
                    _buildPartnerLogo('assets/partner2.jpg'),
                    _buildPartnerLogo('assets/partner3.jpg'),
                    _buildPartnerLogo('assets/partner4.jpg'),
                    _buildPartnerLogo('assets/partner5.jpg'),
                  ],
                ),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildResultItem(dynamic result) {
    if (result is Plant) {
      return ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        leading: Container(width: 40, height: 40, decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(8)), child: result.image != null ? ClipRRect(borderRadius: BorderRadius.circular(8), child: Image.network(_api.getImageUrl(result.image!), fit: BoxFit.cover)) : const Icon(Icons.local_florist, size: 20, color: Colors.grey)),
        title: Text(result.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
        subtitle: const Text("Plante", style: TextStyle(fontSize: 12, color: AppTheme.teal1)),
        trailing: const Icon(Icons.chevron_right, size: 18, color: Colors.grey),
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => PlantDetailScreen(plant: result))),
      );
    } else if (result is Symptom) {
      return ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        leading: Container(width: 40, height: 40, decoration: BoxDecoration(color: Colors.blue.shade50, borderRadius: BorderRadius.circular(20)), child: const Icon(Icons.alt_route, size: 20, color: Colors.blue)),
        title: Text(result.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
        subtitle: const Text("Diagnostic interactif", style: TextStyle(fontSize: 12, color: Colors.blue)),
        trailing: const Icon(Icons.chevron_right, size: 18, color: Colors.grey),
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => DecisionSessionScreen(symptom: result))),
      );
    }
    return const SizedBox();
  }

  Widget _buildNavCard({required IconData icon, required String title, required String subtitle, required Color color, required VoidCallback onTap}) {
    return Card(elevation: 4, shadowColor: color.withOpacity(0.2), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)), child: InkWell(onTap: onTap, borderRadius: BorderRadius.circular(16), child: Padding(padding: const EdgeInsets.all(20), child: Row(children: [Container(width: 50, height: 50, decoration: BoxDecoration(color: color.withOpacity(0.1), shape: BoxShape.circle), child: Icon(icon, color: color, size: 28)), const SizedBox(width: 16), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: color)), const SizedBox(height: 4), Text(subtitle, style: TextStyle(fontSize: 13, color: Colors.grey[600]))])), Icon(Icons.chevron_right, color: Colors.grey[300])]))));
  }
  
  Widget _buildPartnerLogo(String assetPath) {
    return Container(padding: const EdgeInsets.all(8), width: 100, height: 60, decoration: BoxDecoration(color: Colors.white, border: Border.all(color: Colors.grey.shade200), borderRadius: BorderRadius.circular(10)), child: Image.asset(assetPath, fit: BoxFit.contain));
  }
}