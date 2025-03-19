import 'package:flutter/material.dart';

class AnimatedCardDisplay extends StatelessWidget {
  final Widget child;
  final Key cardKey;

  const AnimatedCardDisplay({
    required this.child,
    required this.cardKey,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 500),
      switchInCurve: Curves.easeOut,
      switchOutCurve: Curves.easeIn,
      transitionBuilder: (child, animation) {
        // Si child.key == cardKey => carte entrante (depuis la gauche),
        // sinon carte sortante (vers la droite).
        final beginOffset = child.key == cardKey
            ? const Offset(-1, 0)
            : const Offset(1, 0);
        return ClipRect(
          child: SlideTransition(
            position: Tween<Offset>(begin: beginOffset, end: Offset.zero)
                .animate(animation),
            child: child,
          ),
        );
      },
      child: child,
    );
  }
}
