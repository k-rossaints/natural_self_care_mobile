import 'package:flutter/material.dart';
import 'theme.dart';
import 'screens/main_scaffold.dart'; // <--- Importe le nouveau fichier

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Natural Self-Care',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      
      // On pointe vers le MainScaffold qui contient la barre de navigation
      home: const MainScaffold(), 
    );
  }
}