import 'package:flutter/material.dart';
import 'package:untitled/ui/home_screen.dart';
import 'package:untitled/ui/login_screen.dart';
import 'package:untitled/ui/matchmaking_screen.dart';
import 'package:untitled/ui/game_screen.dart';
import 'package:untitled/ui/result_screen.dart';
import 'package:untitled/ui/abandon_screen.dart';

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
      // Pour simuler l'abandon, nous définissons AbandonScreen comme route initiale.
      initialRoute: AbandonScreen.routeName,
      routes: {
        HomeScreen.routeName: (context) => const HomeScreen(),
        LoginScreen.routeName: (context) => const LoginScreen(),
        MatchmakingScreen.routeName: (context) => const MatchmakingScreen(),
        GameScreen.routeName: (context) => const GameScreen(),
        ResultScreen.routeName: (context) => const ResultScreen(),
        AbandonScreen.routeName: (context) => const AbandonScreen(),
      },
    );
  }
}
