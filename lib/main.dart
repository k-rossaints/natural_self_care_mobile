import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'theme.dart';
import 'screens/main_scaffold.dart';
import 'providers/theme_provider.dart';

/*
  Point d'entrée de l'application.
  L'ensemble du widget tree est enveloppé dans un ProviderScope,
  ce qui est requis par Riverpod pour que les providers soient accessibles
  depuis n'importe quel widget de l'arbre.
*/
void main() {
  runApp(
    const ProviderScope(
      child: MyApp(),
    ),
  );
}

/*
  Widget racine de l'application.
  ConsumerWidget permet d'écouter le themeModeProvider pour appliquer
  dynamiquement le thème clair ou sombre sans reconstruire l'ensemble de l'arbre.
*/
class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);
    return MaterialApp(
      title: 'Natural Self-Care',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeMode,
      home: const MainScaffold(),
    );
  }
}