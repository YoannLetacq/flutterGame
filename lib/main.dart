import 'package:flutter/material.dart';
import 'package:untitled/ui/home_screen.dart';
import 'package:untitled/ui/login_screen.dart';

void main() {
  runApp(const Zone01GameApp());
}

class Zone01GameApp extends StatelessWidget {
  const Zone01GameApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Zone01 Game',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      initialRoute: HomeScreen.routeName,
      routes: {
        HomeScreen.routeName: (context) => const HomeScreen(),
        LoginScreen.routeName: (context) => const LoginScreen(),
        // Les autres écrans (Matchmaking, Jeu, Résultats, Abandon) seront ajoutés par la suite.
      },
    );
  }
}
