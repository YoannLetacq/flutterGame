import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/auth_service.dart';
import '../login_screen.dart';
import 'package:untitled/main.dart';

class KickListener extends StatelessWidget {
  final Widget child;
  const KickListener({required this.child, super.key});

  @override
  Widget build(BuildContext context) {
    return Selector<AuthService, bool>(
        selector: (_, a) => a.kickedByOtherDevice,
        builder: (_, kicked, __) {
            if (kicked) {
              // ① Snackbar via le ScaffoldMessenger racine
              Future.microtask(() {
                rootMessengerKey.currentState!
                  ..clearSnackBars()
                  ..showSnackBar(
                    const SnackBar(
                      content: Text(
                        'Connexion ouverte sur un autre appareil.\nVous avez été déconnecté.',
                      ),
                      duration: Duration(seconds: 4),
                    ),
                  );
              });

              // ② Redirection hors du build-cycle
              Future.microtask(() {
                Navigator.of(rootMessengerKey.currentContext!)
                    .pushAndRemoveUntil(
                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                  (_) => false,
                );
              });
            }
            return child;
          },
        );
  }
}
