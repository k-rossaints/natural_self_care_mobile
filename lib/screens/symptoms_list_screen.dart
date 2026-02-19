import 'package:flutter/material.dart';
import 'dart:async'; 
import '../models/symptom.dart';
import '../services/api_service.dart';
import '../theme.dart';
import 'decision_session_screen.dart';

class SymptomsListScreen extends StatefulWidget {
  const SymptomsListScreen({super.key});

  @override
  State<SymptomsListScreen> createState() => _SymptomsListScreenState();
}

class _SymptomsListScreenState extends State<SymptomsListScreen> {
  final ApiService _api = ApiService();
  
  List<Symptom> _allSymptoms = [];
  List<Symptom> _filteredSymptoms = [];
  
  bool _isLoading = true;
  String _searchQuery = '';
  
  // Timer pour éviter de surcharger le processeur ---
  Timer? _debounce; 

  @override
  void initState() {
    super.initState();
    _loadSymptoms();
  }

  //on trash le timer quand on quitte l'écran 
  @override
  void dispose() {
    _debounce?.cancel(); 
    super.dispose();
  }

  Future<void> _loadSymptoms() async {
    try {
      final data = await _api.getSymptoms();
      if (mounted) {
        setState(() {
          _allSymptoms = data;
          _filteredSymptoms = data;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  //Debounce
  void _runFilter(String query) {
    // Si l'utilisateur tape une lettre, on annule le compte à rebours précédent
    if (_debounce?.isActive ?? false) _debounce!.cancel();

    // 300ms
    _debounce = Timer(const Duration(milliseconds: 300), () {
      final q = _removeDiacritics(query.toLowerCase());
      if (mounted) {
        setState(() {
          _searchQuery = query;
          _filteredSymptoms = _allSymptoms.where((s) {
            return _removeDiacritics(s.name.toLowerCase()).contains(q);
          }).toList();
        });
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
        title: const Text('Chemins de décision', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: AppTheme.textDark,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppTheme.teal1))
          : Column(
              children: [
                // Search bar
                Container(
                  color: Colors.white,
                  padding: const EdgeInsets.all(16),
                  child: TextField(
                    onChanged: _runFilter,
                    decoration: InputDecoration(
                      hintText: "Rechercher un symptôme...",
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

                // Liste
                Expanded(
                  child: _filteredSymptoms.isEmpty 
                    ? Center(child: Text("Aucun résultat", style: TextStyle(color: Colors.grey.shade500)))
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
                              side: const BorderSide(color: Color(0xFFE2E8F0)),
                            ),
                            child: InkWell(
                              onTap: () {
                                // fermeture automatique du clavier
                                FocusScope.of(context).unfocus(); 

                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    fullscreenDialog: true,
                                    builder: (context) => DecisionSessionScreen(symptom: symptom),
                                  ),
                                );
                              },
                              borderRadius: BorderRadius.circular(12),
                              child: Padding(
                                padding: const EdgeInsets.all(20),
                                child: Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(10),
                                      decoration: BoxDecoration(color: Colors.blue.shade50, shape: BoxShape.circle),
                                      child: Icon(Icons.alt_route, color: Colors.blue.shade700, size: 20),
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            symptom.name,
                                            style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: AppTheme.textDark),
                                          ),
                                          if (symptom.description != null) ...[
                                            const SizedBox(height: 4),
                                            Text(
                                              symptom.description!,
                                              style: const TextStyle(color: AppTheme.textGrey, fontSize: 13, height: 1.4),
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
            ),
    );
  }
}