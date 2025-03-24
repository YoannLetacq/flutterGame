import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'package:untitled/services/auth_service.dart';
import 'package:untitled/services/user_profile_service.dart';
import 'package:untitled/services/history_service.dart';
import 'package:untitled/services/matchmaking_service.dart';
import 'package:untitled/services/card_service.dart';
import 'package:untitled/services/game_service.dart';
import 'package:untitled/repositories/game_repository_firebase.dart';
import 'package:untitled/ui/home_screen.dart';
import 'package:untitled/ui/login_screen.dart';
import 'package:untitled/ui/matchmaking_screen.dart';
import 'package:untitled/ui/result_screen.dart';
import 'firebase_options.dart'; // Fichier généré par FlutterFire

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<AuthService>(create: (_) => AuthService()),
        Provider<UserProfileService>(create: (_) => UserProfileService()),
        Provider<HistoryService>(create: (_) => HistoryService()),
        Provider<MatchmakingService>(create: (_) => MatchmakingService(firestore: FirebaseFirestore.instance)),
        Provider<CardService>(create: (_) => CardService()),
        Provider<GameService>(create: (_) => GameService(gameRepository: FirebaseGameRepository())),
        // Les providers spécifiques aux parties (GameProvider) seront créés lors de la navigation vers GameScreen.
      ],
      child: MaterialApp(
        title: 'Zone01 Game',
        theme: ThemeData(
          primaryColor: Colors.white,
          colorScheme: const ColorScheme.dark(
            primary: Colors.white,
            secondary: Color(0xFFFC9905),
          ),
          scaffoldBackgroundColor: const Color(0xFF0F0D7B),
          textTheme: const TextTheme(
            headlineSmall: TextStyle(color: Colors.white, fontSize: 22),
            bodyLarge: TextStyle(color: Colors.white70, fontSize: 16),
            headlineMedium: TextStyle(color: Colors.white, fontSize: 24),
          ),
        ),
        initialRoute: LoginScreen.routeName,
        routes: {
          LoginScreen.routeName: (context) => const LoginScreen(),
          HomeScreen.routeName: (context) => const HomeScreen(),
          MatchmakingScreen.routeName: (context) => const MatchmakingScreen(),
          ResultScreen.routeName: (context) => const ResultScreen(),
          // D'autres routes peuvent être ajoutées ici.
        },
      ),
    );
  }
}
