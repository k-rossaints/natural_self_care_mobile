import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/symptom.dart';
import '../models/decision_step.dart';
import '../models/plant.dart';
import '../services/api_service.dart';
import '../theme.dart';
import 'plant_detail_screen.dart';

class StepRecord {
  final DecisionStep step;
  final bool answer;
  StepRecord({required this.step, required this.answer});
}

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
  final List<StepRecord> _history = [];
  
  bool _isLoading = true;
  final ScrollController _scrollController = ScrollController();

  List<String> _futureQuestions = [];
  // _hasMoreFuture n'est plus vraiment utile si on affiche tout, mais on le garde en sécurité
  bool _hasMoreFuture = false; 

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
        if (widget.symptom.startStepId != null) {
          _currentStep = steps.firstWhere(
            (step) => step.id == widget.symptom.startStepId,
            orElse: () => steps.first,
          );
          _calculateFutureQuestions(); 
        }
        _isLoading = false;
      });
    } catch (e) {
      print("Erreur chargement steps: $e");
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // --- ALGORITHME DE PRÉVISUALISATION ---
  void _calculateFutureQuestions() {
    if (_currentStep == null || _currentStep!.type != 'question') {
      _futureQuestions = [];
      _hasMoreFuture = false;
      return;
    }

    final Set<String> collectedContents = {};
    final List<int> queue = [];
    final Set<int> visited = {};
    
    if (_currentStep!.nextStepYes != null) queue.add(_currentStep!.nextStepYes!);
    if (_currentStep!.nextStepNo != null) queue.add(_currentStep!.nextStepNo!);

    int iterations = 0;
    // MODIFICATION ICI : On passe la limite à 50 pour être sûr de tout prendre
    const int limit = 50; 
    const int maxIter = 100;

    while (queue.isNotEmpty && iterations < maxIter) {
      iterations++;
      final id = queue.removeAt(0);
      
      if (visited.contains(id)) continue;
      visited.add(id);

      try {
        final step = _allSteps.firstWhere((s) => s.id == id);
        
        if (step.type == 'question') {
          if (!collectedContents.contains(step.content)) {
            collectedContents.add(step.content);
          }
        }

        // On continue d'explorer tant qu'on n'a pas tout trouvé
        if (collectedContents.length < limit + 1) {
          if (step.nextStepYes != null) queue.add(step.nextStepYes!);
          if (step.nextStepNo != null) queue.add(step.nextStepNo!);
        }
      } catch (e) {
        // Step introuvable
      }
      
      if (collectedContents.length >= limit) break;
    }

    final List<String> result = collectedContents.toList();
    
    if (result.length > limit) {
      _futureQuestions = result.sublist(0, limit);
      _hasMoreFuture = true;
    } else {
      _futureQuestions = result;
      _hasMoreFuture = false;
    }
  }

  void _answer(bool isYes) {
    if (_currentStep == null) return;

    setState(() {
      _history.add(StepRecord(step: _currentStep!, answer: isYes));

      final nextId = isYes ? _currentStep!.nextStepYes : _currentStep!.nextStepNo;

      if (nextId != null) {
        try {
          _currentStep = _allSteps.firstWhere((step) => step.id == nextId);
        } catch (e) {
          _currentStep = null; 
        }
      } else {
        _currentStep = null;
      }
      
      _calculateFutureQuestions();
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _goBackOne() {
    if (_history.isEmpty) return;
    setState(() {
      final last = _history.removeLast();
      _currentStep = last.step;
      _calculateFutureQuestions();
    });
  }

  void _editAt(int index) {
    setState(() {
      _currentStep = _history[index].step;
      _history.removeRange(index, _history.length);
      _calculateFutureQuestions();
    });
  }

  void _reset() {
    Navigator.pop(context);
  }

  void _restart() {
    setState(() {
      _history.clear();
      if (widget.symptom.startStepId != null) {
        _currentStep = _allSteps.firstWhere((s) => s.id == widget.symptom.startStepId);
        _calculateFutureQuestions();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text(widget.symptom.name, style: const TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: AppTheme.textDark,
        actions: [
          IconButton(icon: const Icon(Icons.refresh), tooltip: "Recommencer", onPressed: _restart),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              controller: _scrollController,
              padding: const EdgeInsets.all(20),
              children: [
                if (widget.symptom.additionalInfo != null)
                  Container(
                    margin: const EdgeInsets.only(bottom: 24),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      border: Border(left: BorderSide(color: Colors.blue.shade700, width: 4)),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(children: [
                          Icon(Icons.info, color: Colors.blue.shade700, size: 20),
                          const SizedBox(width: 8),
                          Text("Bon à savoir", style: TextStyle(color: Colors.blue.shade900, fontWeight: FontWeight.bold)),
                        ]),
                        const SizedBox(height: 8),
                        Text(widget.symptom.additionalInfo!, style: TextStyle(color: Colors.blue.shade900, height: 1.4)),
                      ],
                    ),
                  ),

                ..._history.asMap().entries.map((entry) => _buildHistoryItem(entry.key, entry.value)),

                if (_currentStep != null)
                  _buildCurrentStepCard(_currentStep!)
                else if (_history.isNotEmpty)
                  const Padding(padding: EdgeInsets.all(20), child: Center(child: Text("Fin du parcours."))),
                  
                const SizedBox(height: 40),
              ],
            ),
    );
  }

  Widget _buildHistoryItem(int index, StepRecord record) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Column(
              children: [
                Container(
                  width: 24, height: 24,
                  decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle, border: Border.fromBorderSide(BorderSide(color: Colors.grey, width: 2))),
                  child: Center(child: Icon(Icons.check, size: 14, color: Colors.grey.shade600)),
                ),
                Expanded(child: Container(width: 2, color: Colors.grey.shade300)),
              ],
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Opacity(
                opacity: 0.7,
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey.shade200)),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text("Question ${index + 1}", style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey)),
                          InkWell(
                            onTap: () => _editAt(index),
                            child: const Padding(padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4), child: Text("Modifier", style: TextStyle(color: AppTheme.teal1, fontWeight: FontWeight.bold, fontSize: 12))),
                          )
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(record.step.content, style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 15)),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(20)),
                        child: Text("Votre réponse : ${record.answer ? 'Oui' : 'Non'}", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.grey.shade700)),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCurrentStepCard(DecisionStep step) {
    bool isQuestion = step.type == 'question';
    bool isEmergency = step.isEmergency;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Container(
              width: 24, height: 24,
              decoration: const BoxDecoration(color: AppTheme.teal1, shape: BoxShape.circle, boxShadow: [BoxShadow(color: Colors.teal, blurRadius: 4)]),
              child: const Center(child: CircleAvatar(backgroundColor: Colors.white, radius: 4)),
            ),
          ],
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: isEmergency ? AppTheme.danger : AppTheme.teal1, width: 2),
              boxShadow: [BoxShadow(color: (isEmergency ? AppTheme.danger : AppTheme.teal1).withOpacity(0.1), blurRadius: 12, offset: const Offset(0, 4))],
            ),
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                if (isQuestion)
                  Text("Question ${_history.length + 1}", style: const TextStyle(color: AppTheme.teal1, fontWeight: FontWeight.bold, letterSpacing: 1))
                else 
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(isEmergency ? Icons.warning_rounded : Icons.check_circle, color: isEmergency ? AppTheme.danger : AppTheme.teal2),
                      const SizedBox(width: 8),
                      Text(isEmergency ? "Attention requise" : "Recommandation", style: TextStyle(color: isEmergency ? AppTheme.danger : AppTheme.teal2, fontWeight: FontWeight.bold, fontSize: 16)),
                    ],
                  ),
                
                const SizedBox(height: 16),
                
                Text(step.content, textAlign: TextAlign.center, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold, height: 1.4, color: AppTheme.textDark)),

                const SizedBox(height: 24),

                if (isQuestion)
                  Column(
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () => _answer(false),
                              style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16), side: BorderSide(color: Colors.grey.shade300), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                              child: const Text("Non", style: TextStyle(color: Colors.black87, fontSize: 16)),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: () => _answer(true),
                              style: ElevatedButton.styleFrom(backgroundColor: AppTheme.teal1, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 16), elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                              child: const Text("Oui", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                            ),
                          ),
                        ],
                      ),
                      
                      // --- SECTION QUESTIONS FUTURES ---
                      if (_futureQuestions.isNotEmpty) ...[
                        const SizedBox(height: 24),
                        const Divider(color: Colors.grey),
                        const SizedBox(height: 12),
                        Align(
                          alignment: Alignment.centerLeft,
                          // CORRECTION ICI : .toUpperCase() au lieu de uppercase: true
                          child: Text(
                            "Questions suivantes possibles :".toUpperCase(), 
                            style: const TextStyle(
                              fontSize: 12, 
                              fontWeight: FontWeight.bold, 
                              color: Colors.grey, 
                              letterSpacing: 0.5
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        ..._futureQuestions.map((q) => Padding(
                          padding: const EdgeInsets.only(bottom: 6),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text("• ", style: TextStyle(color: Colors.grey)),
                              Expanded(child: Text(q, style: const TextStyle(fontSize: 13, color: Colors.grey, height: 1.3))),
                            ],
                          ),
                        )),
                        if (_hasMoreFuture)
                          const Padding(
                            padding: EdgeInsets.only(top: 4),
                            child: Text("... et d'autres selon vos réponses.", style: TextStyle(fontSize: 12, fontStyle: FontStyle.italic, color: Colors.grey)),
                          ),
                      ],
                    ],
                  )
                else
                  Column(
                    children: [
                      if (step.recommendedPlants.isNotEmpty) ...[
                        const Divider(),
                        const SizedBox(height: 12),
                        const Align(alignment: Alignment.centerLeft, child: Text("REMÈDE(S) SUGGÉRÉ(S)", style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold, fontSize: 11))),
                        const SizedBox(height: 12),
                        ...step.recommendedPlants.map((plant) => Padding(padding: const EdgeInsets.only(bottom: 8), child: _buildRecommendedPlantCard(plant))),
                        const SizedBox(height: 12),
                      ],
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _reset,
                          style: ElevatedButton.styleFrom(backgroundColor: isEmergency ? AppTheme.danger : AppTheme.teal1, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                          child: const Text("Terminer"),
                        ),
                      ),
                    ],
                  ),
                  
                  if (_history.isNotEmpty && isQuestion)
                    Padding(
                      padding: const EdgeInsets.only(top: 16),
                      child: TextButton.icon(
                        onPressed: _goBackOne,
                        icon: const Icon(Icons.undo, size: 16, color: Colors.grey),
                        label: const Text("Revenir à la question précédente", style: TextStyle(color: Colors.grey, fontSize: 12)),
                      ),
                    ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRecommendedPlantCard(Plant plant) {
    final imageUrl = plant.image != null ? _api.getImageUrl(plant.image!) : null;
    return Container(
      decoration: BoxDecoration(color: Colors.grey.shade50, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey.shade200)),
      child: Material(
        color: Colors.transparent, borderRadius: BorderRadius.circular(12), clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => PlantDetailScreen(plant: plant))),
          child: Padding(
            padding: const EdgeInsets.all(10),
            child: Row(
              children: [
                Container(
                  width: 50, height: 50,
                  decoration: BoxDecoration(borderRadius: BorderRadius.circular(8), color: Colors.white, image: imageUrl != null ? DecorationImage(image: CachedNetworkImageProvider(imageUrl), fit: BoxFit.cover) : null),
                  child: imageUrl == null ? const Icon(Icons.local_florist, color: Colors.grey, size: 20) : null,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(plant.name, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppTheme.textDark)),
                    const Text("Voir la fiche", style: TextStyle(fontSize: 12, color: AppTheme.teal1, fontWeight: FontWeight.w600)),
                  ]),
                ),
                const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey),
              ],
            ),
          ),
        ),
      ),
    );
  }
}