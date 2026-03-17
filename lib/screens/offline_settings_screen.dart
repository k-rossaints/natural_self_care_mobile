import 'package:flutter/material.dart';
import '../theme.dart';
import '../services/offline_service.dart';
import '../services/api_service.dart';

class OfflineSettingsScreen extends StatefulWidget {
  const OfflineSettingsScreen({super.key});

  @override
  State<OfflineSettingsScreen> createState() => _OfflineSettingsScreenState();
}

class _OfflineSettingsScreenState extends State<OfflineSettingsScreen> {
  final OfflineService _offlineService = OfflineService();
  final ApiService _api = ApiService();

  bool _saveImages = false;
  bool _isDownloading = false;
  String _statusMessage = "";

  String? _datePlants;
  String? _datePaths;
  String? _dateMethodology;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final saveImg = await _offlineService.shouldSaveImages();
    final dates = await _offlineService.getSyncDates();
    if (mounted) {
      setState(() {
        _saveImages = saveImg;
        _datePlants = dates['plants'];
        _datePaths = dates['paths'];
        _dateMethodology = dates['methodology'];
      });
    }
  }

  Future<void> _startDownload({
    bool downloadPlants = false,
    bool downloadPaths = false,
    bool downloadMethodology = false,
  }) async {
    setState(() {
      _isDownloading = true;
      _statusMessage = "Connexion au serveur...";
    });

    try {
      if (downloadPlants) {
        setState(() => _statusMessage = "Téléchargement des plantes...");
        await _api.downloadPlants();
      }
      if (downloadPaths) {
        setState(() => _statusMessage = "Téléchargement des parcours...");
        await _api.downloadDecisionPaths();
      }
      if (downloadMethodology) {
        setState(() => _statusMessage = "Téléchargement des références...");
        await _api.downloadMethodology();
      }

      final dates = await _offlineService.getSyncDates();
      if (mounted) {
        setState(() {
          _datePlants = dates['plants'];
          _datePaths = dates['paths'];
          _dateMethodology = dates['methodology'];
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Téléchargement terminé avec succès !"),
            backgroundColor: AppTheme.teal1,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Erreur: $e"), backgroundColor: AppTheme.danger),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isDownloading = false;
          _statusMessage = "";
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Mode Hors Ligne")),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const Text(
            "Téléchargez le contenu pour l'utiliser sans internet.\nLes données sont aussi sauvegardées automatiquement à chaque visite.",
            style: TextStyle(color: Colors.grey, fontSize: 15, height: 1.5),
          ),
          const SizedBox(height: 30),

          // --- OPTIONS ---
          const Text("OPTIONS", style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.teal1)),
          SwitchListTile(
            title: const Text("Sauvegarder les images"),
            subtitle: const Text("Consomme plus d'espace de stockage"),
            value: _saveImages,
            activeColor: AppTheme.teal1,
            onChanged: (val) {
              setState(() => _saveImages = val);
              _offlineService.setSaveImages(val);
            },
          ),

          const Divider(height: 40),

          // --- CONTENU ---
          const Text("CONTENU À TÉLÉCHARGER", style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.teal1)),
          const SizedBox(height: 10),

          _buildDownloadButton(
            title: "Base de données Plantes",
            icon: Icons.local_florist,
            lastSync: _datePlants,
            onTap: () => _startDownload(downloadPlants: true),
          ),
          const SizedBox(height: 10),

          _buildDownloadButton(
            title: "Chemins de décision",
            icon: Icons.alt_route,
            lastSync: _datePaths,
            onTap: () => _startDownload(downloadPaths: true),
          ),
          const SizedBox(height: 10),

          _buildDownloadButton(
            title: "Démarche scientifique",
            icon: Icons.science,
            lastSync: _dateMethodology,
            onTap: () => _startDownload(downloadMethodology: true),
          ),

          const SizedBox(height: 20),

          if (_isDownloading) ...[
            const LinearProgressIndicator(color: AppTheme.teal1),
            const SizedBox(height: 10),
            Center(
              child: Text(
                _statusMessage,
                style: const TextStyle(color: AppTheme.teal1, fontWeight: FontWeight.bold),
              ),
            ),
          ],

          const SizedBox(height: 40),

          // --- TOUT TÉLÉCHARGER ---
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              icon: const Icon(Icons.download_for_offline),
              label: const Text("Tout télécharger"),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.teal1,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: _isDownloading
                  ? null
                  : () => _startDownload(
                        downloadPlants: true,
                        downloadPaths: true,
                        downloadMethodology: true,
                      ),
            ),
          ),

          const SizedBox(height: 16),

          // --- NETTOYAGE ---
          OutlinedButton.icon(
            icon: const Icon(Icons.delete_outline, color: AppTheme.danger),
            label: const Text("Supprimer les données locales", style: TextStyle(color: AppTheme.danger)),
            style: OutlinedButton.styleFrom(side: const BorderSide(color: AppTheme.danger)),
            onPressed: () async {
              await _offlineService.clearAllData();
              setState(() {
                _datePlants = null;
                _datePaths = null;
                _dateMethodology = null;
              });
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Données supprimées")),
                );
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildDownloadButton({
    required String title,
    required IconData icon,
    required String? lastSync,
    required VoidCallback onTap,
  }) {
    final isSynced = lastSync != null;
    return Card(
      elevation: 0,
      color: Colors.grey.shade50,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8)),
          child: Icon(icon, color: AppTheme.teal1),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Row(
          children: [
            Icon(
              isSynced ? Icons.check_circle : Icons.info_outline,
              size: 12,
              color: isSynced ? Colors.green : Colors.grey,
            ),
            const SizedBox(width: 4),
            Text(
              isSynced ? "Synchro : $lastSync" : "Non téléchargé",
              style: TextStyle(fontSize: 12, color: isSynced ? Colors.green : Colors.grey),
            ),
          ],
        ),
        trailing: _isDownloading
            ? null
            : IconButton(
                icon: const Icon(Icons.download_rounded, color: AppTheme.teal1),
                onPressed: onTap,
              ),
      ),
    );
  }
}