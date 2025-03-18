import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'package:untitled/ui/home_screen.dart';
import 'package:untitled/ui/login_screen.dart';
import 'package:untitled/ui/matchmaking_screen.dart';
import 'package:untitled/ui/game_screen.dart';
import 'package:untitled/ui/result_screen.dart';
import 'package:untitled/ui/abandon_screen.dart';
import 'package:untitled/providers/connectivity_provider.dart';
import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const Zone01GameApp());
}

class Zone01GameApp extends StatelessWidget {
  const Zone01GameApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ConnectivityProvider()),
      ],
      child: MaterialApp(
        title: 'Zone01 Game',
        theme: ThemeData(primarySwatch: Colors.blue),
        initialRoute: LoginScreen.routeName,
        routes: {
          LoginScreen.routeName: (context) => const LoginScreen(),
          HomeScreen.routeName: (context) => const HomeScreen(),
          MatchmakingScreen.routeName: (context) => const MatchmakingScreen(),
          GameScreen.routeName: (context) => const GameScreen(),
          ResultScreen.routeName: (context) => const ResultScreen(),
          AbandonScreen.routeName: (context) => const AbandonScreen(),
        },
      ),
    );
  }
}
