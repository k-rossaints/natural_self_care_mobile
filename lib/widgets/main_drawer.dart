import 'package:flutter/material.dart';
import '../theme.dart';
import '../screens/about_screen.dart';
import '../screens/methodology_screen.dart';
import 'package:flutter_svg/flutter_svg.dart';

class MainDrawer extends StatelessWidget {
  // Cette fonction permet de changer l'onglet du bas depuis le menu
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
                // TON LOGO SVG (Version plus grande)
                Container(
                  width: 70, height: 70,
                  padding: const EdgeInsets.all(15), // Marge intérieure
                  decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                  child: SvgPicture.asset(
                    'assets/favicon.svg',
                    // Ici on force la couleur verte du thème sur ton SVG
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
          // --- NAVIGATION PRINCIPALE (Change l'onglet) ---
          ListTile(
            leading: const Icon(Icons.home_filled, color: AppTheme.teal1),
            title: const Text('Accueil / Remèdes', style: TextStyle(fontWeight: FontWeight.bold)),
            onTap: () {
              Navigator.pop(context); // Ferme le menu
              onTabChange(0); // Va à l'onglet 0
            },
          ),
          ListTile(
            leading: const Icon(Icons.alt_route, color: AppTheme.teal1),
            title: const Text('Chemins de décision', style: TextStyle(fontWeight: FontWeight.bold)),
            onTap: () {
              Navigator.pop(context);
              onTabChange(1); // Va à l'onglet 1
            },
          ),
          ListTile(
            leading: const Icon(Icons.menu_book, color: AppTheme.teal1),
            title: const Text('Index des problèmes', style: TextStyle(fontWeight: FontWeight.bold)),
            onTap: () {
              Navigator.pop(context);
              onTabChange(2); // Va à l'onglet 2
            },
          ),

          const Divider(),

          // --- PAGES D'INFORMATION (Ouvre une nouvelle page) ---
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