import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'screens/home_screen.dart';

void main() {
  runApp(const ProviderScope(child: ChessTournamentApp()));
}

class ChessTournamentApp extends StatelessWidget {
  const ChessTournamentApp({super.key});

  @override
  Widget build(BuildContext context) {
    final seed = const Color(0xFF1B1B1F);
    return MaterialApp(
      title: 'Chess Tournament Manager',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: seed),
        useMaterial3: true,
        appBarTheme: const AppBarTheme(centerTitle: false),
      ),
      home: const HomeScreen(),
    );
  }
}
