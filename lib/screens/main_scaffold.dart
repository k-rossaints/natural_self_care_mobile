import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../theme.dart';
import 'home_screen.dart';
import 'remedies_list_screen.dart';
import 'symptoms_list_screen.dart';
import 'problems_index_screen.dart';
import '../widgets/main_drawer.dart';
import '../widgets/offline_banner.dart'; // <--- 1. IMPORT DU FICHIER CRÉÉ

class MainScaffold extends StatefulWidget {
  const MainScaffold({super.key});

  @override
  State<MainScaffold> createState() => _MainScaffoldState();
}

class _MainScaffoldState extends State<MainScaffold> {
  int _currentIndex = 0;

  void _goToTab(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> pages = [
      HomeScreen(onTabChange: _goToTab),
      const RemediesListScreen(),
      const SymptomsListScreen(),
      const ProblemsIndexScreen(),
    ];

    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
              child: SvgPicture.asset(
                'assets/favicon.svg',
                width: 20, height: 20,
                colorFilter: const ColorFilter.mode(AppTheme.teal1, BlendMode.srcIn),
              ),
            ),
            const SizedBox(width: 10),
            const Text('Natural Self-Care', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          ],
        ),
        centerTitle: true,
      ),
      
      drawer: MainDrawer(onTabChange: _goToTab),

      // --- 2. MODIFICATION DE LA STRUCTURE DU BODY ---
      body: Column(
        children: [
          // La banderole est insérée ici. Elle ne s'affichera que si le Wifi est coupé.
          const OfflineBanner(),
          
          // Le contenu principal prend tout le reste de la place
          Expanded(
            child: IndexedStack(
              index: _currentIndex,
              children: pages,
            ),
          ),
        ],
      ),
      // -----------------------------------------------
      
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: _goToTab,
        backgroundColor: Colors.white,
        indicatorColor: AppTheme.teal1.withOpacity(0.15),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Accueil',
          ),
          NavigationDestination(
            icon: Icon(Icons.local_florist_outlined),
            selectedIcon: Icon(Icons.local_florist),
            label: 'Remèdes',
          ),
          NavigationDestination(
            icon: Icon(Icons.alt_route_outlined),
            selectedIcon: Icon(Icons.alt_route),
            label: 'Chemins',
          ),
          NavigationDestination(
            icon: Icon(Icons.menu_book_outlined),
            selectedIcon: Icon(Icons.menu_book),
            label: 'Problèmes',
          ),
        ],
      ),
    );
  }
}