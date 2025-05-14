import 'package:flutter/material.dart';

class DisconnectNotifWidget extends StatefulWidget {
  final IconData icon;
  final String message;

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
  State<DisconnectNotifWidget> createState() => _DisconnectNotifWidgetState();
}

class _DisconnectNotifWidgetState extends State<DisconnectNotifWidget> {
  bool _isVisible = true;

  @override
  Widget build(BuildContext context) {
    if (!_isVisible) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(12),
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.grey.shade200,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(widget.icon, size: 24),
          const SizedBox(width: 8),
          Expanded(child: Text(widget.message)),
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: () {
              setState(() {
                _isVisible = false;
              });
            },
          )
        ],
      ),
    );
  }
}
