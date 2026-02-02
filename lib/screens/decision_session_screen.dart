import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/symptom.dart';
import '../models/decision_step.dart';
import '../models/plant.dart';
import '../services/api_service.dart';
import '../theme.dart';
import 'plant_detail_screen.dart'; // Pour pouvoir naviguer vers le détail

class DecisionSessionScreen extends StatefulWidget {
  final Symptom symptom;

  const DecisionSessionScreen({super.key, required this.symptom});

  @override
  State<DecisionSessionScreen> createState() => _DecisionSessionScreenState();
}

class _DecisionSessionScreenState extends State<DecisionSessionScreen> {
  final ApiService _api = ApiService();
  
  List<DecisionStep> _allSteps = [];
  DecisionStep? _currentStep;
  final List<Map<String, String>> _history = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final steps = await _api.getDecisionSteps();
      
      setState(() {
        _allSteps = steps;
        // On trouve la première étape
        if (widget.symptom.startStepId != null) {
          _currentStep = steps.firstWhere(
            (step) => step.id == widget.symptom.startStepId,
            orElse: () => steps.first,
          );
        }
        _isLoading = false;
      });
    } catch (e) {
      print("Erreur chargement steps: $e");
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _answer(bool isYes) {
    if (_currentStep == null) return;

    setState(() {
      // Ajout à l'historique visuel
      _history.add({
        'question': _currentStep!.content,
        'answer': isYes ? 'Oui' : 'Non',
      });

      // Calcul de la prochaine étape
      final nextId = isYes ? _currentStep!.nextStepYes : _currentStep!.nextStepNo;

      if (nextId != null) {
        _currentStep = _allSteps.firstWhere(
          (step) => step.id == nextId,
          orElse: () => _currentStep!, 
        );
      }
    });
  }

  void _reset() {
    Navigator.pop(context); // On ferme l'écran
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.symptom.name),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: _reset,
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // 1. BLOC INFO "BON À SAVOIR" (S'il existe)
                  if (widget.symptom.additionalInfo != null)
                    Container(
                      margin: const EdgeInsets.only(bottom: 20),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade50,
                        border: Border(left: BorderSide(color: Colors.blue.shade800, width: 4)),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(children: [
                            Icon(Icons.info_outline, color: Colors.blue.shade800, size: 20),
                            const SizedBox(width: 8),
                            Text("Bon à savoir", style: TextStyle(color: Colors.blue.shade900, fontWeight: FontWeight.bold)),
                          ]),
                          const SizedBox(height: 8),
                          Text(widget.symptom.additionalInfo!, style: TextStyle(color: Colors.blue.shade900)),
                        ],
                      ),
                    ),

                  // 2. HISTORIQUE DES QUESTIONS PRÉCÉDENTES
                  ..._history.map((item) => Padding(
                    padding: const EdgeInsets.only(bottom: 16, left: 10),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 2, height: 40, color: Colors.grey.shade300, margin: const EdgeInsets.only(right: 16, top: 4),
                        ),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(item['question']!, style: const TextStyle(color: Colors.grey)),
                              const SizedBox(height: 4),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(color: Colors.grey.shade200, borderRadius: BorderRadius.circular(10)),
                                child: Text("Réponse : ${item['answer']}", style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.black54)),
                              )
                            ],
                          ),
                        ),
                      ],
                    ),
                  )),

                  // 3. L'ÉTAPE COURANTE (Question ou Résultat)
                  if (_currentStep != null)
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 300),
                      child: _buildStepCard(_currentStep!),
                    ),
                ],
              ),
            ),
    );
  }

  Widget _buildStepCard(DecisionStep step) {
    // --- CAS A : C'est une QUESTION ---
    if (step.type == 'question') {
      return Card(
        key: ValueKey(step.id),
        elevation: 4,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: AppTheme.teal1, width: 2)
        ),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              Text("Question ${_history.length + 1}", style: const TextStyle(color: AppTheme.teal1, fontWeight: FontWeight.bold, letterSpacing: 1)),
              const SizedBox(height: 16),
              Text(step.content, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, height: 1.3), textAlign: TextAlign.center),
              const SizedBox(height: 30),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => _answer(false),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        side: BorderSide(color: Colors.grey.shade300),
                      ),
                      child: const Text("Non", style: TextStyle(color: Colors.black)),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => _answer(true),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.teal1,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: const Text("Oui"),
                    ),
                  ),
                ],
              )
            ],
          ),
        ),
      );
    } 
    
    // --- CAS B : C'est un RÉSULTAT ---
    else {
      final isEmergency = step.isEmergency;
      return Column(
        key: ValueKey(step.id),
        children: [
          // Le gros bloc de résultat (Contient le texte + les plantes)
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: isEmergency ? const Color(0xFFFEF2F2) : const Color(0xFFF0FDF4),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: isEmergency ? AppTheme.danger : AppTheme.teal2),
            ),
            child: Column(
              children: [
                // Icône et Titre
                Icon(
                  isEmergency ? Icons.warning_rounded : Icons.check_circle_outline,
                  size: 48,
                  color: isEmergency ? AppTheme.danger : AppTheme.teal2,
                ),
                const SizedBox(height: 16),
                Text(
                  isEmergency ? "Attention requise" : "Notre recommandation",
                  style: TextStyle(
                    fontSize: 20, 
                    fontWeight: FontWeight.bold,
                    color: isEmergency ? AppTheme.danger : AppTheme.teal2
                  ),
                ),
                const SizedBox(height: 16),
                
                // Texte du conseil
                Text(step.content, style: const TextStyle(fontSize: 16, height: 1.5), textAlign: TextAlign.center),
                
                // --- LISTE DES PLANTES SUGGÉRÉES (À l'intérieur du bloc) ---
                if (step.recommendedPlants.isNotEmpty) ...[
                  const SizedBox(height: 24),
                  const Divider(height: 1), // Séparateur discret
                  const SizedBox(height: 24),
                  
                  const Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      "REMÈDE(S) SUGGÉRÉ(S)", 
                      style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold, fontSize: 12, letterSpacing: 1)
                    ),
                  ),
                  const SizedBox(height: 12),
                  
                  // On affiche chaque plante liée
                  ...step.recommendedPlants.map((plant) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _buildRecommendedPlantCard(plant),
                  )),
                ],
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Bouton Terminer (En dehors du bloc)
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _reset,
              style: ElevatedButton.styleFrom(
                backgroundColor: isEmergency ? AppTheme.danger : AppTheme.teal1,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: const Text("Terminer"),
            ),
          )
        ],
      );
    }
  }

  // Widget pour afficher la plante en "Mode Compact"
  Widget _buildRecommendedPlantCard(Plant plant) {
    final imageUrl = plant.image != null ? _api.getImageUrl(plant.image!) : null;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        // Bordure fine verte pour rappeler le thème
        border: Border.all(color: AppTheme.teal1.withOpacity(0.3)),
        boxShadow: [
          BoxShadow(color: Colors.teal.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () {
            // Navigation vers la fiche complète
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => PlantDetailScreen(plant: plant)),
            );
          },
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                // Image Carrée à gauche
                Container(
                  width: 70, height: 70,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    color: Colors.grey.shade100,
                    image: imageUrl != null 
                      ? DecorationImage(
                          image: CachedNetworkImageProvider(imageUrl),
                          fit: BoxFit.cover
                        )
                      : null,
                  ),
                  child: imageUrl == null ? const Icon(Icons.local_florist, color: Colors.grey) : null,
                ),
                
                const SizedBox(width: 16),
                
                // Infos Texte
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        plant.name,
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.textDark),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Text("Voir la fiche complète", style: TextStyle(fontSize: 14, color: AppTheme.teal1, fontWeight: FontWeight.w600)),
                          const SizedBox(width: 4),
                          const Icon(Icons.arrow_forward, size: 14, color: AppTheme.teal1)
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}