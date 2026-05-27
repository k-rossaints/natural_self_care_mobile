import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/*
  Provider gérant le thème de l'application avec persistance locale.
  L'état initial est ThemeMode.system, puis corrigé de manière asynchrone
  par _load() dès la construction du notifier.
*/
final themeModeProvider = NotifierProvider<ThemeModeNotifier, ThemeMode>(() {
  return ThemeModeNotifier();
});

class ThemeModeNotifier extends Notifier<ThemeMode> {
  @override
  ThemeMode build() {
    _load();
    return ThemeMode.system;
  }

  // Lit la préférence sauvegardée et met à jour l'état au démarrage.
  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString('themeMode');
    if (saved == 'dark') {
      state = ThemeMode.dark;
    } else if (saved == 'light') {
      state = ThemeMode.light;
    } else {
      state = ThemeMode.system;
    }
  }

  // Bascule entre clair et sombre et persiste le choix via SharedPreferences.
  Future<void> toggle() async {
    final prefs = await SharedPreferences.getInstance();
    if (state == ThemeMode.dark) {
      state = ThemeMode.light;
      await prefs.setString('themeMode', 'light');
    } else {
      state = ThemeMode.dark;
      await prefs.setString('themeMode', 'dark');
    }
  }
}