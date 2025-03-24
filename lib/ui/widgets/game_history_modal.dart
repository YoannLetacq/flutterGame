import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:untitled/services/history_service.dart';
import 'package:untitled/services/user_profile_service.dart';

/// Modal affichant l'historique des 10 dernières parties du joueur.
class GameHistoryModal extends StatelessWidget {
  const GameHistoryModal({super.key});

  @override
  Widget build(BuildContext context) {
    final userProfileService = Provider.of<UserProfileService>(context, listen: false);
    String userId;
    try {
      userId = userProfileService.getUserProfile()['uid']!;
    } catch (e) {
      return Container(
        padding: const EdgeInsets.all(16.0),
        child: const Text("Impossible de charger l'historique : utilisateur non connecté."),
      );
    }

    final historyService = Provider.of<HistoryService>(context, listen: false);
    final futureHistory = historyService.getRecentGames(userId);

    return SafeArea(
      child: Container(
        padding: const EdgeInsets.all(16.0),
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.8,
        ),
        child: FutureBuilder<List<Map<String, dynamic>>>(
          future: futureHistory,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return Center(
                child: Text(
                  "Erreur lors du chargement de l'historique : ${snapshot.error}",
                  style: const TextStyle(color: Colors.red),
                ),
              );
            }
            if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return const Center(
                child: Text(
                  "Aucune partie récente trouvée.",
                  style: TextStyle(fontStyle: FontStyle.italic),
                ),
              );
            }
            final games = snapshot.data!;
            return ListView.builder(
              itemCount: games.length,
              itemBuilder: (context, index) {
                final game = games[index];
                DateTime date;
                final rawDate = game['date'];
                if (rawDate is DateTime) {
                  date = rawDate;
                } else if (rawDate != null && rawDate is! DateTime) {
                  try {
                    date = DateTime.parse(rawDate.toString());
                  } catch (_) {
                    date = DateTime.now();
                  }
                } else {
                  date = DateTime.now();
                }
                final day = date.day.toString().padLeft(2, '0');
                final month = date.month.toString().padLeft(2, '0');
                final year = date.year.toString().substring(2);
                final hour = date.hour.toString().padLeft(2, '0');
                final minute = date.minute.toString().padLeft(2, '0');
                final dateStr = "$day/$month/$year $hour:$minute";

                final opponent = game['opponent'] ?? 'Adversaire inconnu';
                final score = game['score']?.toString() ?? '?';
                final num eloChangeNum = game['eloChange'] ?? 0;
                final eloChangeText = eloChangeNum > 0
                    ? '+${eloChangeNum.toInt()}'
                    : eloChangeNum.toInt().toString();
                String resultStr = game['result']?.toString().toLowerCase() ?? '';
                late String resultLabel;
                late Color resultColor;
                if (resultStr.contains('vic') || resultStr.contains('win')) {
                  resultLabel = 'Victoire';
                  resultColor = Colors.green;
                } else {
                  resultLabel = 'Défaite';
                  resultColor = Colors.red;
                }

                return Card(
                  color: Colors.blue[50],
                  margin: const EdgeInsets.symmetric(vertical: 4.0),
                  elevation: 1,
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "$dateStr - vs $opponent",
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                "Score : $score    Elo : $eloChangeText",
                                style: const TextStyle(fontSize: 14),
                              ),
                            ),
                            Text(
                              resultLabel,
                              style: TextStyle(fontSize: 14, color: resultColor),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}
