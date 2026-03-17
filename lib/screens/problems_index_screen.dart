import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/plant.dart';
import '../providers/plants_provider.dart';
import '../utils/string_utils.dart';
import '../services/api_service.dart';
import '../theme.dart';
import '../widgets/skeleton_loader.dart';
import '../widgets/error_view.dart';
import 'plant_detail_screen.dart';

class ProblemsIndexScreen extends ConsumerStatefulWidget {
  const ProblemsIndexScreen({super.key});

  @override
  ConsumerState<ProblemsIndexScreen> createState() => _ProblemsIndexScreenState();
}

class _ProblemsIndexScreenState extends ConsumerState<ProblemsIndexScreen> {
  final ApiService _api = ApiService();

  final Map<String, List<Plant>> _problemsMap = {};
  List<String> _allKeys = [];
  List<String> _filteredKeys = [];
  String _searchQuery = '';
  bool _initialized = false;

  void _buildIndex(List<Plant> plants) {
    if (_initialized) return;
    _initialized = true;
    final Map<String, List<Plant>> tempMap = {};
    for (var plant in plants) {
      for (var ailment in plant.ailments) {
        final cleanAilment = ailment.trim();
        if (cleanAilment.isNotEmpty) {
          tempMap.putIfAbsent(cleanAilment, () => []).add(plant);
        }
      }
    }
    final keys = tempMap.keys.toList();
    keys.sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
    _problemsMap.addAll(tempMap);
    _allKeys = keys;
    _filteredKeys = keys;
  }

  void _runFilter(String query) {
    setState(() {
      _searchQuery = query;
      if (query.isEmpty) {
        _filteredKeys = _allKeys;
      } else {
        final q = removeDiacritics(query.toLowerCase());
        _filteredKeys = _allKeys.where((key) => removeDiacritics(key.toLowerCase()).contains(q)).toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final plantsAsync = ref.watch(plantsProvider);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Index des problèmes', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Theme.of(context).colorScheme.surface,
        elevation: 0,
        foregroundColor: Theme.of(context).colorScheme.onSurface,
      ),
      body: plantsAsync.when(
        loading: () => const ListSkeleton(count: 8),
        error: (e, _) => ErrorView(
          isOffline: true,
          onRetry: () => ref.refresh(plantsProvider),
        ),
        data: (plants) {
          if (!_initialized) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              setState(() => _buildIndex(plants));
            });
            return const ListSkeleton(count: 8);
          }

          return Column(
            children: [
              Container(
                color: Theme.of(context).colorScheme.surface,
                padding: const EdgeInsets.all(16),
                child: TextField(
                  onChanged: _runFilter,
                  decoration: InputDecoration(
                    hintText: "Rechercher (ex: Acné, Stress...)",
                    hintStyle: TextStyle(color: Colors.grey.shade400),
                    prefixIcon: const Icon(Icons.search, color: AppTheme.teal1),
                    filled: true,
                    fillColor: Theme.of(context).brightness == Brightness.dark ? const Color(0xFF2A2A2A) : const Color(0xFFF1F5F9),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                    contentPadding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ),
              Expanded(
                child: _filteredKeys.isEmpty
                    ? Center(child: Text("Aucun problème trouvé pour \"$_searchQuery\"", style: TextStyle(color: Colors.grey.shade500)))
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _filteredKeys.length,
                        itemBuilder: (context, index) {
                          final ailmentName = _filteredKeys[index];
                          final relatedPlants = _problemsMap[ailmentName]!;
                          final letter = ailmentName[0].toUpperCase();
                          final bool showHeader = index == 0 || _filteredKeys[index - 1][0].toUpperCase() != letter;

                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (showHeader && _searchQuery.isEmpty)
                                Padding(
                                  padding: const EdgeInsets.only(top: 16, bottom: 8, left: 8),
                                  child: Text(letter, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: AppTheme.teal2)),
                                ),
                              Card(
                                margin: const EdgeInsets.only(bottom: 8),
                                elevation: 0,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: Colors.grey.shade200)),
                                child: ExpansionTile(
                                  shape: const Border(),
                                  title: Text(ailmentName, style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.textDark)),
                                  trailing: Container(
                                    padding: const EdgeInsets.all(6),
                                    decoration: BoxDecoration(color: AppTheme.teal1.withOpacity(0.1), shape: BoxShape.circle),
                                    child: Text(relatedPlants.length.toString(), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.teal1)),
                                  ),
                                  children: relatedPlants.map((plant) => ListTile(
                                    contentPadding: const EdgeInsets.only(left: 16, right: 16, bottom: 8),
                                    leading: Hero(
                                      tag: 'problems-plant-${plant.id}',
                                      child: Container(
                                        width: 40, height: 40,
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          color: Colors.grey.shade100,
                                          image: plant.image != null ? DecorationImage(image: CachedNetworkImageProvider(_api.getImageUrl(plant.image!)), fit: BoxFit.cover) : null,
                                        ),
                                        child: plant.image == null ? const Icon(Icons.local_florist, size: 20, color: Colors.grey) : null,
                                      ),
                                    ),
                                    title: Text(plant.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                                    subtitle: Text(plant.scientificName ?? '', style: const TextStyle(fontStyle: FontStyle.italic, fontSize: 12)),
                                    trailing: const Icon(Icons.chevron_right, size: 18, color: Colors.grey),
                                    onTap: () {
                                      FocusScope.of(context).unfocus();
                                      Navigator.push(context, MaterialPageRoute(builder: (context) => PlantDetailScreen(plant: plant, heroTag: 'problems-plant-${plant.id}')));
                                    },
                                  )).toList(),
                                ),
                              ),
                            ],
                          );
                        },
                      ),
              ),
            ],
          );
        },
      ),
    );
  }
}