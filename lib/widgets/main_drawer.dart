import 'package:flutter/material.dart';
import '../theme.dart';
import '../screens/about_screen.dart';
import '../screens/methodology_screen.dart';
import 'package:flutter_svg/flutter_svg.dart';

class MainDrawer extends StatelessWidget {
  final Function(int) onTabChange;

  const MainDrawer({super.key, required this.onTabChange});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          // EN-TÊTE
          DrawerHeader(
            decoration: const BoxDecoration(color: AppTheme.teal1),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 70, height: 70,
                  padding: const EdgeInsets.all(15),
                  decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                  child: SvgPicture.asset(
                    'assets/favicon.svg',
                    colorFilter: const ColorFilter.mode(AppTheme.teal1, BlendMode.srcIn),
                  ),
                ),
                const SizedBox(height: 10),
                const Text(
                  'Natural Self-Care',
                  style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
          
          // --- NAVIGATION PRINCIPALE ---
          
          // 1. Accueil (Index 0)
          ListTile(
            leading: const Icon(Icons.home_filled, color: AppTheme.teal1),
            title: const Text('Accueil', style: TextStyle(fontWeight: FontWeight.bold)), // Nom corrigé
            onTap: () {
              Navigator.pop(context); // Ferme le menu
              onTabChange(0); // Va à l'onglet 0
            },
          ),

          // 2. Remèdes (Index 1) - C'était le lien manquant
          ListTile(
            leading: const Icon(Icons.local_florist, color: AppTheme.teal1),
            title: const Text('Explorer les remèdes', style: TextStyle(fontWeight: FontWeight.bold)),
            onTap: () {
              Navigator.pop(context);
              onTabChange(1); // Va à l'onglet 1 (Liste des plantes)
            },
          ),

          // 3. Chemins (Index 2) - Corrigé
          ListTile(
            leading: const Icon(Icons.alt_route, color: AppTheme.teal1),
            title: const Text('Chemins de décision', style: TextStyle(fontWeight: FontWeight.bold)),
            onTap: () {
              Navigator.pop(context);
              onTabChange(2); // Va à l'onglet 2 (Symptômes)
            },
          ),

          // 4. Index (Index 3) - Corrigé
          ListTile(
            leading: const Icon(Icons.menu_book, color: AppTheme.teal1),
            title: const Text('Index des problèmes', style: TextStyle(fontWeight: FontWeight.bold)),
            onTap: () {
              Navigator.pop(context);
              onTabChange(3); // Va à l'onglet 3 (Problèmes A-Z)
            },
          ),

          const Divider(),

          // --- PAGES D'INFORMATION ---
          ListTile(
            leading: const Icon(Icons.info_outline),
            title: const Text('À propos'),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(context, MaterialPageRoute(builder: (context) => const AboutScreen()));
            },
          ),
          ListTile(
            leading: const Icon(Icons.science),
            title: const Text('Démarche scientifique'),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(context, MaterialPageRoute(builder: (context) => const MethodologyScreen()));
            },
          ),
          
          const Divider(),
          const Padding(
            padding: EdgeInsets.all(16.0),
            child: Text("v1.0.0 - ASC Genève", style: TextStyle(color: Colors.grey, fontSize: 12)),
          ),
        ],
      ),
    );
  }
}