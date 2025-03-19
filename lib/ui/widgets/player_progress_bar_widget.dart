import 'package:flutter/material.dart';

class PlayerProgressBarWidget extends StatelessWidget {
  final double progress; // Valeur entre 0 et 1
  final String avatarUrl;

  const PlayerProgressBarWidget({
    super.key,
    required this.progress,
    required this.avatarUrl,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // Avatar à gauche
        CircleAvatar(
          backgroundImage: NetworkImage(avatarUrl),
          radius: 20,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: TweenAnimationBuilder<double>(
            tween: Tween<double>(begin: 0, end: progress),
            duration: const Duration(milliseconds: 500),
            builder: (context, value, child) {
              return LinearProgressIndicator(
                value: value,
                minHeight: 10,
                backgroundColor: Colors.grey[300],
                color: Theme.of(context).primaryColor,
              );
            },
          ),
        ),
      ],
    );
  }
}
