import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:untitled/ui/home_screen.dart';
import 'package:untitled/ui/login_screen.dart';
import 'package:untitled/ui/matchmaking_screen.dart';
import 'package:untitled/ui/game_screen.dart';
import 'package:untitled/ui/result_screen.dart';
import 'package:untitled/ui/abandon_screen.dart';

import 'firebase_options.dart';

Future<void> main() async {
  // S'assure que binding est initialisé avant toute opération asynchrone.
  WidgetsFlutterBinding.ensureInitialized();
  //  Initialise Firebase.
    await Firebase.initializeApp(
    options:
    DefaultFirebaseOptions.currentPlatform,
    );
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
      // Pour tester en situation réelle avec la DB, définissez l'écran de démarrage souhaité.
      initialRoute: LoginScreen.routeName,
      routes: {
        LoginScreen.routeName: (context) => const LoginScreen(),
        HomeScreen.routeName: (context) => const HomeScreen(),
        MatchmakingScreen.routeName: (context) => const MatchmakingScreen(),
        GameScreen.routeName: (context) => const GameScreen(),
        ResultScreen.routeName: (context) => const ResultScreen(),
        AbandonScreen.routeName: (context) => const AbandonScreen(),
      },
    );
  }
}
