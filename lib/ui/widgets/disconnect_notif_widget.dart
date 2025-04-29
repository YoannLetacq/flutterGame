import 'package:flutter/material.dart';

class DisconnectNotifWidget extends StatelessWidget {
  final IconData icon;
  final String   message;
  const DisconnectNotifWidget._(this.icon, this.message, {super.key});

  factory DisconnectNotifWidget.disconnect() => const DisconnectNotifWidget._(
    Icons.wifi_off,
    'Votre adversaire a perdu la connexion.\n'
        'S’il ne revient pas dans 10 s, vous gagnez automatiquement.',
  );

  factory DisconnectNotifWidget.reconnect() => const DisconnectNotifWidget._(
    Icons.wifi,
    'Votre adversaire est de nouveau connecté.',
  );

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 24),
        const SizedBox(width: 8),
        Expanded(child: Text(message)),
      ],
    );
  }
}
