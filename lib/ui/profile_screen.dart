// profile_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../services/user_profile_service.dart';
import 'history_screen.dart';

/// Écran de profil du joueur.
/// - Affiche les informations de profil (nom, avatar, XP, niveau).
/// - Permet de consulter l'historique des parties.
class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // 1. Récupération des infos basiques
    final userProfileService = context.read<UserProfileService>();
    final basicProfile = userProfileService.getUserProfile();
    final uid     = basicProfile['uid']!;
    final name    = basicProfile['displayName'] ?? 'Joueur';
    final avatar  = basicProfile['avatarUrl'] ?? '';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mon profil'),
      ),
      body: FutureBuilder<DocumentSnapshot>(
        future: FirebaseFirestore.instance.collection('users').doc(uid).get(),
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snap.hasError || !snap.hasData || !snap.data!.exists) {
            return const Center(child: Text('Impossible de charger le profil.'));
          }

          final data = snap.data!.data() as Map<String, dynamic>;
          final xp    = data['xp']    ?? 0;
          final lvl   = data['level'] ?? 1;

          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Avatar
                if (avatar.isNotEmpty)
                  CircleAvatar(
                    radius: 50,
                    backgroundImage: NetworkImage(avatar),
                  ),
                const SizedBox(height: 12),

                // Pseudo
                Text(
                  name,
                  style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),

                // XP et niveau
                Text('XP : $xp',    style: const TextStyle(fontSize: 18)),
                Text('Niveau : $lvl', style: const TextStyle(fontSize: 18)),
                const SizedBox(height: 24),

                // Bouton Historique
                ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const HistoryScreen()),
                    );
                  },
                  child: const Text('Voir mon historique'),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
