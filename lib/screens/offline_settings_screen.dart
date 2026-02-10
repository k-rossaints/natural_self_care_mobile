import 'package:flutter/material.dart';
import '../theme.dart';
import '../services/offline_service.dart';

class OfflineSettingsScreen extends StatefulWidget {
  const OfflineSettingsScreen({super.key});

  @override
  State<OfflineSettingsScreen> createState() => _OfflineSettingsScreenState();
}

class _OfflineSettingsScreenState extends State<OfflineSettingsScreen> {
  final OfflineService _offlineService = OfflineService();
  
  bool _saveImages = false;
  bool _isDownloading = false;
  String? _lastSync;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final saveImg = await _offlineService.shouldSaveImages();
    final lastSync = await _offlineService.getLastSyncDate();
    if (mounted) {
      setState(() {
        _saveImages = saveImg;
        _lastSync = lastSync;
      });
    }
  }

  Future<void> _startDownload() async {
    setState(() => _isDownloading = true);
    
    try {
      // On lance le téléchargement des plantes
      await _offlineService.downloadPlants();
      
      // On recharge la date de synchro
      final lastSync = await _offlineService.getLastSyncDate();
      
      if (mounted) {
        setState(() => _lastSync = lastSync);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Plantes téléchargées avec succès !"), backgroundColor: AppTheme.teal1),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Erreur: $e"), backgroundColor: AppTheme.danger),
        );
      }
    } finally {
      if (mounted) setState(() => _isDownloading = false);
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
            "Téléchargez le contenu pour l'utiliser sans internet.",
            style: TextStyle(color: Colors.grey, fontSize: 16),
          ),
          const SizedBox(height: 30),

          // --- OPTION IMAGES ---
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

          // --- TÉLÉCHARGEMENT ---
          const Text("CONTENU", style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.teal1)),
          const SizedBox(height: 10),
          
          Card(
            elevation: 0,
            color: Colors.grey.shade50,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: Colors.grey.shade200)),
            child: ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8)),
                child: const Icon(Icons.local_florist, color: AppTheme.teal1),
              ),
              title: const Text("Base de données Plantes", style: TextStyle(fontWeight: FontWeight.bold)),
              subtitle: _lastSync != null ? Text("Dernière synchro : $_lastSync") : const Text("Jamais synchronisé"),
              trailing: _isDownloading 
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                : IconButton(
                    icon: const Icon(Icons.download_rounded, color: AppTheme.teal1),
                    onPressed: _startDownload,
                  ),
            ),
          ),

          const SizedBox(height: 40),
          
          // --- NETTOYAGE ---
          OutlinedButton.icon(
            icon: const Icon(Icons.delete_outline, color: AppTheme.danger),
            label: const Text("Supprimer les données locales", style: TextStyle(color: AppTheme.danger)),
            style: OutlinedButton.styleFrom(side: const BorderSide(color: AppTheme.danger)),
            onPressed: () async {
              await _offlineService.clearAllData();
              setState(() => _lastSync = null);
              if(mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Données supprimées")));
            },
          ),
        ],
      ),
    );
  }
}