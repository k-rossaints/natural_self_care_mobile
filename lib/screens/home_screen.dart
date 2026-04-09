import 'package:flutter/material.dart';
import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../utils/string_utils.dart';
import 'package:url_launcher/url_launcher.dart';
import '../theme.dart';
import '../services/api_service.dart';
import '../models/plant.dart';
import '../models/symptom.dart';
import '../providers/plants_provider.dart';
import '../providers/symptoms_provider.dart';
import 'plant_detail_screen.dart';
import 'decision_session_screen.dart';

class HomeScreen extends ConsumerStatefulWidget {
  final Function(int) onTabChange;

  const HomeScreen({super.key, required this.onTabChange});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  final ApiService _api = ApiService();

  List<dynamic> _searchResults = [];
  bool _isSearching = false;

  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocus = FocusNode();
  Timer? _debounce;

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocus.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  Future<void> _launchPartnerUrl(String urlString) async {
    final Uri url = Uri.parse(urlString);
    try {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } catch (e) {
      debugPrint("Erreur ouverture lien partenaire: $e");
    }
  }

  void _onSearchChanged(String query, List<Plant> plants, List<Symptom> symptoms) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    if (query.trim().isEmpty) {
      setState(() { _searchResults = []; _isSearching = false; });
      return;
    }
    _debounce = Timer(const Duration(milliseconds: 300), () {
      if (query.trim().length >= 3) _performSearch(query, plants, symptoms);
    });
  }

  void _performSearch(String query, List<Plant> plants, List<Symptom> symptoms) {
    final q = removeDiacritics(query.toLowerCase());
    final matchingPlants = plants.where((p) {
      final name = removeDiacritics(p.name.toLowerCase());
      final sci = removeDiacritics((p.scientificName ?? '').toLowerCase());
      bool match = name.contains(q) || sci.contains(q);
      if (!match) match = p.ailments.any((a) => removeDiacritics(a.toLowerCase()).contains(q));
      return match;
    }).toList();
    final matchingSymptoms = symptoms.where((s) {
      final name = removeDiacritics(s.name.toLowerCase());
      final desc = removeDiacritics((s.description ?? '').toLowerCase());
      return name.contains(q) || desc.contains(q);
    }).toList();
    setState(() {
      _searchResults = [...matchingSymptoms, ...matchingPlants];
      _isSearching = true;
    });
  }
  @override
  Widget build(BuildContext context) {
    final plantsAsync = ref.watch(plantsProvider);
    final symptomsAsync = ref.watch(symptomsProvider);

    // On récupère les données des providers (listes vides si pas encore chargé)
    final plants = plantsAsync.asData?.value ?? [];
    final symptoms = symptomsAsync.asData?.value ?? [];

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
              // HEADER VERT COMPLET
              Container(
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

                    const SizedBox(height: 30),

                    // BARRE DE RECHERCHE
                    Container(
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surface,
                        borderRadius: BorderRadius.circular(30),
                        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.15), blurRadius: 15, offset: const Offset(0, 8))],
                      ),
                      child: TextField(
                        controller: _searchController,
                        focusNode: _searchFocus,
                        onChanged: (val) => _onSearchChanged(val, plants, symptoms),
                        decoration: InputDecoration(
                          hintText: "Rechercher une plante, un mal...",
                          hintStyle: TextStyle(color: Colors.grey.shade400),
                          prefixIcon: const Icon(Icons.search, color: AppTheme.teal1),
                          suffixIcon: _searchController.text.isNotEmpty
                            ? IconButton(icon: const Icon(Icons.close, color: Colors.grey), onPressed: () { _searchController.clear(); _onSearchChanged('', plants, symptoms); FocusScope.of(context).unfocus(); })
                            : null,
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // RÉSULTATS DE RECHERCHE
              if (_isSearching && _searchController.text.length >= 3)
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  constraints: const BoxConstraints(maxHeight: 350),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surface,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 15, offset: const Offset(0, 5))],
                    border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
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
                      color: AppTheme.teal1,
                      onTap: () => widget.onTabChange(2),
                    ),
                    const SizedBox(height: 16),
                    _buildNavCard(
                      icon: Icons.menu_book_outlined,
                      title: "Index des problèmes",
                      subtitle: "Liste de A à Z des pathologies traitées.",
                      color: AppTheme.teal1,
                      onTap: () => widget.onTabChange(3),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 40),

              // PARTENAIRES (Mise à jour avec URLs)
              Center(child: Text("NOS PARTENAIRES", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey[400], letterSpacing: 1.5))),
              const SizedBox(height: 20),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Wrap(
                  spacing: 15, runSpacing: 15, alignment: WrapAlignment.center,
                  children: [
                    _buildPartnerLogo('assets/partner1.jpg', 'https://www.ox.ac.uk/'),
                    _buildPartnerLogo('assets/partner2.jpg', 'https://www.ugb.sn/'),
                    _buildPartnerLogo('assets/partner3.jpg', 'https://www.nybg.org/'),
                    _buildPartnerLogo('assets/partner4.jpg', 'https://uog.edu.et/'),
                    _buildPartnerLogo('assets/partner5.jpg', 'https://www.unige.ch/'),
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
    // On crée un ID unique pour l'animation Hero
    final String heroTag = result is Plant ? 'home-plant-${result.id}' : 'home-symptom-${result.id}';

    if (result is Plant) {
      return ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        leading: Hero(
          tag: heroTag,
          child: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Theme.of(context).brightness == Brightness.dark ? AppTheme.darkCard : Colors.grey.shade100,
              borderRadius: BorderRadius.circular(8),
            ),
            child: result.image != null
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(_api.getImageUrl(result.image!), fit: BoxFit.cover),
                  )
                : const Icon(Icons.local_florist, size: 20, color: Colors.grey),
          ),
        ),
        title: Text(result.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
        subtitle: Text("Plante", style: TextStyle(fontSize: 12, color: Theme.of(context).brightness == Brightness.dark ? AppTheme.tealDark : AppTheme.teal1)),
        trailing: const Icon(Icons.chevron_right, size: 18, color: Colors.grey),
        onTap: () {
          _searchFocus.unfocus(); // On ferme le clavier AVANT de partir
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => PlantDetailScreen(plant: result, heroTag: 'home-plant-${result.id}')),
          );
        },
      );
    } else if (result is Symptom) {
      return ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        leading: const Icon(Icons.alt_route, size: 20, color: Colors.blue),
        title: Text(result.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
        subtitle: const Text("Diagnostic interactif", style: TextStyle(fontSize: 12, color: Colors.blue)),
        trailing: const Icon(Icons.chevron_right, size: 18, color: Colors.grey),
        onTap: () {
          _searchFocus.unfocus();
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => DecisionSessionScreen(symptom: result)),
          );
        },
      );
    }
    return const SizedBox();
  }

  Widget _buildNavCard({required IconData icon, required String title, required String subtitle, required Color color, required VoidCallback onTap}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cs = Theme.of(context).colorScheme;
    final displayColor = isDark ? (color == AppTheme.teal1 ? AppTheme.tealDark : cs.onSurface) : color;
    return Card(elevation: isDark ? 0 : 4, shadowColor: color.withOpacity(0.2), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: isDark ? BorderSide(color: cs.outlineVariant) : BorderSide.none), child: InkWell(onTap: onTap, borderRadius: BorderRadius.circular(16), child: Padding(padding: const EdgeInsets.all(20), child: Row(children: [Container(width: 50, height: 50, decoration: BoxDecoration(color: displayColor.withOpacity(0.12), shape: BoxShape.circle), child: Icon(icon, color: displayColor, size: 28)), const SizedBox(width: 16), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: displayColor)), const SizedBox(height: 4), Text(subtitle, style: TextStyle(fontSize: 13, color: cs.onSurfaceVariant))])), Icon(Icons.chevron_right, color: cs.onSurfaceVariant)]))));
  }

  // MODIFICATION ICI : On accepte l'URL et on utilise InkWell pour le clic
  Widget _buildPartnerLogo(String assetPath, String url) {
    return InkWell(
      onTap: () => _launchPartnerUrl(url),
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.all(8),
        width: 100,
        height: 60,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
          borderRadius: BorderRadius.circular(10)
        ), 
        child: Image.asset(assetPath, fit: BoxFit.contain)
      ),
    );
  }
}