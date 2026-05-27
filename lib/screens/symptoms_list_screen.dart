import 'package:flutter/material.dart';
import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/symptom.dart';
import '../providers/symptoms_provider.dart';
import '../utils/string_utils.dart';
import '../theme.dart';
import '../widgets/skeleton_loader.dart';
import '../widgets/error_view.dart';
import 'decision_session_screen.dart';

class SymptomsListScreen extends ConsumerStatefulWidget {
  const SymptomsListScreen({super.key});

  @override
  ConsumerState<SymptomsListScreen> createState() => _SymptomsListScreenState();
}

class _SymptomsListScreenState extends ConsumerState<SymptomsListScreen> {
  List<Symptom> _filteredSymptoms = [];
  String _searchQuery = '';
  Timer? _debounce;
  // Evite de réinitialiser _filteredSymptoms à chaque rebuild une fois les données chargées.
  bool _initialized = false;

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }

  /*
    Filtre la liste des symptômes avec un debounce de 300ms pour éviter
    de recalculer à chaque frappe. La recherche porte sur le nom, la description
    et le champ additionalInfo, ce qui permet par exemple de trouver
    "Mal de gorge" en tapant "angine".
  */
  void _runFilter(List<Symptom> allSymptoms, String query) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      final q = removeDiacritics(query.toLowerCase().trim());
      if (mounted) {
        setState(() {
          _searchQuery = query;
          if (q.isEmpty) {
            _filteredSymptoms = allSymptoms;
          } else {
            _filteredSymptoms = allSymptoms.where((s) {
              return removeDiacritics(s.name.toLowerCase()).contains(q) ||
                     removeDiacritics((s.description ?? '').toLowerCase()).contains(q) ||
                     removeDiacritics((s.additionalInfo ?? '').toLowerCase()).contains(q);
            }).toList();
          }
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final symptomsAsync = ref.watch(symptomsProvider);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Du symptôme au remède', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Theme.of(context).colorScheme.surface,
        elevation: 0,
        foregroundColor: Theme.of(context).colorScheme.onSurface,
      ),
      body: symptomsAsync.when(
        loading: () => const ListSkeleton(count: 7),
        error: (e, _) => ErrorView(
          isOffline: true,
          onRetry: () => ref.refresh(symptomsProvider),
        ),
        data: (symptoms) {
          // Initialisation unique de la liste filtrée au premier chargement des données.
          if (!_initialized) {
            _initialized = true;
            _filteredSymptoms = symptoms;
          }

          return Column(
            children: [
              Container(
                color: Theme.of(context).colorScheme.surface,
                padding: const EdgeInsets.all(16),
                child: Container(
                  decoration: BoxDecoration(
                    color: Theme.of(context).brightness == Brightness.dark
                        ? AppTheme.darkCard
                        : Colors.white,
                    borderRadius: BorderRadius.circular(30),
                    border: Theme.of(context).brightness == Brightness.dark
                        ? Border.all(color: const Color(0xFF3A3A3A))
                        : null,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(
                            Theme.of(context).brightness == Brightness.dark ? 0.2 : 0.08),
                        blurRadius:
                            Theme.of(context).brightness == Brightness.dark ? 4 : 10,
                        offset: const Offset(0, 2),
                      )
                    ],
                  ),
                  child: TextField(
                    onChanged: (val) => _runFilter(symptoms, val),
                    decoration: InputDecoration(
                      hintText: "Symptôme, maladie, mot-clé...",
                      hintStyle: TextStyle(
                          color: Theme.of(context).brightness == Brightness.dark
                              ? AppTheme.darkTextSecondary
                              : Colors.grey.shade400),
                      prefixIcon: Icon(
                        Icons.search,
                        color: Theme.of(context).brightness == Brightness.dark
                            ? AppTheme.tealDark
                            : AppTheme.teal1,
                      ),
                      filled: false,
                      border: InputBorder.none,
                      contentPadding:
                          const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                    ),
                  ),
                ),
              ),
              Expanded(
                child: _filteredSymptoms.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.search_off, size: 50, color: Colors.grey.shade300),
                            const SizedBox(height: 10),
                            Text("Aucun résultat pour \"$_searchQuery\"",
                                style: TextStyle(color: Colors.grey.shade500)),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _filteredSymptoms.length,
                        itemBuilder: (context, index) {
                          final symptom = _filteredSymptoms[index];
                          return Card(
                            margin: const EdgeInsets.only(bottom: 16),
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                                side: BorderSide(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .outlineVariant)),
                            child: InkWell(
                              onTap: () {
                                // Le clavier est fermé avant la navigation pour éviter
                                // un saut visuel à l'ouverture de l'écran suivant.
                                FocusScope.of(context).unfocus();
                                Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                        fullscreenDialog: true,
                                        builder: (context) =>
                                            DecisionSessionScreen(symptom: symptom)));
                              },
                              borderRadius: BorderRadius.circular(12),
                              child: Padding(
                                padding: const EdgeInsets.all(20),
                                child: Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(10),
                                      decoration: BoxDecoration(
                                        color: Theme.of(context).brightness ==
                                                Brightness.dark
                                            ? Colors.blue.withOpacity(0.15)
                                            : Colors.blue.shade50,
                                        shape: BoxShape.circle,
                                      ),
                                      child: Icon(
                                        Icons.alt_route,
                                        color: Theme.of(context).brightness ==
                                                Brightness.dark
                                            ? Colors.blue.shade300
                                            : Colors.blue.shade700,
                                        size: 20,
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            symptom.name,
                                            style: TextStyle(
                                                fontSize: 17,
                                                fontWeight: FontWeight.bold,
                                                color: Theme.of(context)
                                                    .colorScheme
                                                    .onSurface),
                                          ),
                                          if (symptom.description != null) ...[
                                            const SizedBox(height: 4),
                                            Text(
                                              symptom.description!,
                                              style: TextStyle(
                                                  color: Theme.of(context)
                                                      .colorScheme
                                                      .onSurfaceVariant,
                                                  fontSize: 13,
                                                  height: 1.4),
                                            ),
                                          ],
                                        ],
                                      ),
                                    ),
                                    const Icon(Icons.chevron_right, color: Colors.grey),
                                  ],
                                ),
                              ),
                            ),
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