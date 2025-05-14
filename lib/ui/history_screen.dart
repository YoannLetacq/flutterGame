// history_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../../services/user_profile_service.dart';
import '../helpers/firestore_helper.dart';

/// Écran d'historique des parties.
/// - Affiche la liste des parties jouées.
/// - Permet de consulter les détails d'une partie en cliquant dessus.
class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  late final String uid;

  @override
  void initState() {
    super.initState();
    uid = context.read<UserProfileService>().getUserProfile()['uid']!;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Historique des parties')),
      body: FutureBuilder<QuerySnapshot<Map<String, dynamic>>>(
        future: FirestoreHelper.getCollection(
          collection: 'game_history/$uid/history',
        ),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Erreur : ${snapshot.error}'));
          }
          final docs = snapshot.data?.docs ?? [];
          if (docs.isEmpty) {
            return const Center(child: Text('Aucune partie jouée.'));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(8),
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final data = docs[index].data();
              final date = ((data['date'] as Timestamp?)?.toDate() ?? DateTime.now());
              final formattedDate = DateFormat(
                "d MMMM yyyy 'à' HH:mm:ss",
                'fr_FR',
              ).format(date);

              final opponentId = (data['opponentId'] as String?) ?? '';
              // si opponentId vide, on renvoie directement "Adversaire"
              final opponentNameFuture = opponentId.isNotEmpty
                  ? FirestoreHelper
                  .getField(collection: 'users', docId: opponentId, field: 'displayName')
                  .then((v) => (v as String?) ?? 'Adversaire')
                  : Future.value('Adversaire');

              return FutureBuilder<String>(
                future: opponentNameFuture,
                builder: (ctx, oppSnap) {
                  final oppName = oppSnap.data ?? 'Adversaire';

                  return InkWell(
                    onTap: () => _showExtended(ctx, data, oppName),
                    child: Card(
                      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Partie versus $oppName',
                              style: Theme.of(ctx).textTheme.titleMedium,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Jouée le $formattedDate',
                              style: Theme.of(ctx).textTheme.bodyMedium,
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }

  void _showExtended(
      BuildContext ctx,
      Map<String, dynamic> data,
      String opponentName,
      ) {
    final date = ((data['date'] as Timestamp?)?.toDate() ?? DateTime.now());
    final formattedDate = DateFormat(
      "d MMMM yyyy 'à' HH:mm:ss",
      'fr_FR',
    ).format(date);

    final mode         = data['mode']    as String? ?? '';
    final result       = data['result']  as String? ?? '';
    final score        = data['score']?.toString()         ?? '0';
    final oppScore     = data['opponentScore']?.toString() ?? '0';
    final eloChange    = data['elo']?.toString()           ?? '0';

    String labelResult;
    switch (result) {
      case 'win':  labelResult = 'Victoire';   break;
      case 'loss': labelResult = 'Défaite';    break;
      case 'draw': labelResult = 'Match nul';  break;
      default:     labelResult = result;
    }

    showDialog(
      context: ctx,
      builder: (dialogCtx) => AlertDialog(
        title: Text('Partie vs $opponentName'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Date            : $formattedDate'),
              const SizedBox(height: 8),
              Text('Mode            : $mode'),
              const SizedBox(height: 8),
              Text('Résultat        : $labelResult'),
              const SizedBox(height: 8),
              Text('Votre score     : $score'),
              Text('Score adversaire: $oppScore'),
              const SizedBox(height: 8),
              Text('Elo  : $eloChange'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: const Text('Fermer'),
          ),
        ],
      ),
    );
  }
}
