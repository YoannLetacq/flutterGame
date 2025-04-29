import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:untitled/helpers/firestore_helper.dart';
import '../../services/auth_service.dart';
import 'home_screen.dart';

/// Écran de connexion utilisateur.
/// - Affiche un bouton de connexion Google et éventuellement des champs de connexion.
/// - Après connexion réussie, redirige vers l'écran d'accueil.
class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Récupère le service d'authentification.
    final authService = Provider.of<AuthService>(context, listen: false);

    return Scaffold(
      appBar: AppBar(title: const Text('Connexion'), automaticallyImplyLeading: false,),
      body: Center(
        child: ElevatedButton.icon(
          icon: const Icon(Icons.login),
          label: const Text('Se connecter avec Google'),
          onPressed: () async {
            final result = await authService.signInWithGoogle();
            if (result != null) {
              // Navigation vers l'accueil avec transition slide
              if (!context.mounted) return;
              Navigator.pushReplacement(
                context,
                PageRouteBuilder(
                  pageBuilder: (_, __, ___) => const HomeScreen(),
                  transitionsBuilder: (_, animation, __, child) => SlideTransition(
                    position: Tween<Offset>(begin: const Offset(1.0, 0.0), end: Offset.zero)
                        .animate(animation),
                    child: child,
                  ),
                ),
              );
            }
          },
        ),
      ),
    );
  }
}
