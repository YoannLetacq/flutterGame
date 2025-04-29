import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';

// Tes imports de services
import 'package:untitled/providers/connectivity_provider.dart';
import 'package:untitled/services/card_service.dart';
import 'package:untitled/ui/widgets/kick_listener_widget.dart';
import 'services/auth_service.dart';
import 'services/matchmaking_service.dart';
import 'services/session_management_service.dart';
import 'services/elo_service.dart';
import 'services/ranking_service.dart';
import 'services/history_service.dart';
import 'services/security_service.dart';
import 'services/abandon_service.dart';
import 'services/game_progress_service.dart';
import 'services/timer_service.dart';
import 'services/user_profile_service.dart';

// Ton écran racine
import 'ui/login_screen.dart';
import 'ui/home_screen.dart';
import 'firebase_options.dart';

// ─────────────────────────── GLOBAL KEYS ─────────────────────────────

final GlobalKey<ScaffoldMessengerState> rootMessengerKey =
GlobalKey<ScaffoldMessengerState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );


  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider<AuthService>(
          create: (_) => AuthService(
            firebaseAuth: FirebaseAuth.instance,
            googleSignIn: GoogleSignIn(),
          ),
        ),
        // Les services sans "with ChangeNotifier" => Provider simple
        Provider<SessionManagementService>(
          create: (_) => SessionManagementService(),
        ),
        Provider<UserProfileService>(
          create: (_) => UserProfileService(),
        ),
        Provider<CardService>(
          create: (_) => CardService(),
        ),
        Provider<EloService>(
          create: (_) => EloService(),
        ),
        Provider<RankingService>(
          create: (context) {
            final elo = context.read<EloService>();
            return RankingService(eloService: elo);
          },
        ),
        Provider<HistoryService>(
          create: (_) => HistoryService(),
        ),
        Provider<SecurityService>(
          create: (_) => SecurityService(),
        ),
        Provider<AbandonService>(
          create: (_) => AbandonService(),
        ),
        Provider<GameProgressService>(
          create: (_) => GameProgressService(),
        ),
        Provider<TimerService>(
          create: (_) => TimerService(),
        ),

        // ConnectivityProvider => "with ChangeNotifier" => ChangeNotifierProvider
        ChangeNotifierProvider<ConnectivityProvider>(
          create: (_) => ConnectivityProvider(),
        ),
        // MatchmakingService => "with ChangeNotifier" => ChangeNotifierProvider
        ChangeNotifierProvider<MatchmakingService>(
          create: (_) => MatchmakingService(),
        ),
      ],
      child: const KickListener(child: MyApp()),
    ),
  );
}

class MyApp extends StatelessWidget {
   const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final authService = context.read<AuthService>();
    // On choisit la page d’accueil en fonction de si l’utilisateur est loggé
    final bool loggedIn = authService.isLoggedIn;

    return MaterialApp(
      scaffoldMessengerKey: rootMessengerKey,
      title: 'Flutter Game',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(primarySwatch: Colors.blue),
      home: loggedIn ? const HomeScreen() : const LoginScreen(),
    );
  }
}
