import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../theme.dart';
import '../providers/plants_provider.dart';
import '../providers/symptoms_provider.dart';
import '../widgets/global_search_delegate.dart';
import 'home_screen.dart';
import 'remedies_list_screen.dart';
import 'symptoms_list_screen.dart';
import 'problems_index_screen.dart';
import '../widgets/main_drawer.dart';
import '../widgets/offline_banner.dart';

class MainScaffold extends ConsumerStatefulWidget {
  const MainScaffold({super.key});

  @override
  ConsumerState<MainScaffold> createState() => _MainScaffoldState();
}

class _MainScaffoldState extends ConsumerState<MainScaffold> {
  int _currentIndex = 0;

  void _goToTab(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  void _openGlobalSearch(BuildContext context) {
    final plants = ref.read(plantsProvider).asData?.value ?? [];
    final symptoms = ref.read(symptomsProvider).asData?.value ?? [];
    showSearch(
      context: context,
      delegate: GlobalSearchDelegate(plants: plants, symptoms: symptoms),
    );
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
        actions: [
          if (_currentIndex != 0)
            IconButton(
              icon: const Icon(Icons.search),
              tooltip: 'Rechercher',
              onPressed: () => _openGlobalSearch(context),
            ),
        ],
      ),

      drawer: MainDrawer(onTabChange: _goToTab),

      body: Column(
        children: [
          const OfflineBanner(),
          Expanded(
            child: IndexedStack(
              index: _currentIndex,
              children: pages,
            ),
          ),
        ],
      ),

      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: _goToTab,
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