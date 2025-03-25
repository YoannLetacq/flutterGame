import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:untitled/ui/home_screen.dart';
import 'package:untitled/ui/login_screen.dart';
import 'firebase_options.dart';
import 'services/auth_service.dart';
import 'services/user_profile_service.dart';
import 'services/elo_service.dart';
import 'services/ranking_service.dart';
import 'services/history_service.dart';
import 'services/security_service.dart';
import 'services/abandon_service.dart';
import 'services/game_progress_service.dart';
import 'services/timer_service.dart';
import 'services/game_service.dart';
import 'services/matchmaking_service.dart';
import 'providers/connectivity_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(
    MultiProvider(
      providers: [
        // Inject all services via Provider (business logic and data services)
        Provider(create: (_) => AuthService()),
        Provider(create: (_) => UserProfileService()),
        Provider(create: (_) => EloService()),
        Provider(create: (context) {
          // RankingService depends on EloService
          final eloService = Provider.of<EloService>(context, listen: false);
          return RankingService(eloService: eloService);
        }),
        Provider(create: (_) => HistoryService()),
        Provider(create: (_) => SecurityService()),
        Provider(create: (_) => AbandonService()),
        Provider(create: (_) => GameProgressService()),
        Provider(create: (_) => TimerService()),
        Provider(create: (_) => GameService()),
        Provider(create: (_) => MatchmakingService()),
        ChangeNotifierProvider(create: (_) => ConnectivityProvider()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Game',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(primarySwatch: Colors.blue),
      home: Consumer<AuthService>(
        // If user is logged in, go to HomeScreen, otherwise LoginScreen
        builder: (context, authService, _) {
          return authService.isLoggedIn
              ? const HomeScreen()
              : const LoginScreen();
        },
      ),
    );
  }
}
