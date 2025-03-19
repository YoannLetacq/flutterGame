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
          backgroundImage: avatarUrl.startsWith('http')
              ? NetworkImage(avatarUrl)
              : AssetImage(avatarUrl) as ImageProvider,
          radius: 24,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: TweenAnimationBuilder<double>(
            tween: Tween<double>(begin: 0, end: progress),
            duration: const Duration(milliseconds: 500),
            builder: (context, value, child) {
              return Container(
                height: 20,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  // Gradient du rose vers le bleu, intensité croissante
                  gradient: LinearGradient(
                    colors: [
                      Color.lerp(
                        Colors.pinkAccent.withOpacity(0.5),
                        Colors.blueAccent,
                        value,
                      )!,
                      Color.lerp(
                        Colors.pinkAccent.withOpacity(0.2),
                        Colors.blue,
                        value,
                      )!,
                    ],
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
