import 'package:flutter/material.dart';
import 'learning_view_mode.dart';

class LearningToggleView extends StatelessWidget {
  final LearningViewMode viewMode;
  final ValueChanged<LearningViewMode> onToggle;

  const LearningToggleView({
    super.key,
    required this.viewMode,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return ToggleButtons(
      isSelected: [
        viewMode == LearningViewMode.list,
        viewMode == LearningViewMode.grid,
      ],
      onPressed: (index) => onToggle(LearningViewMode.values[index]),
      borderRadius: BorderRadius.circular(8),
      selectedColor: Colors.white,
      fillColor: Theme.of(context).primaryColor,
      children: const [
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 16),
          child: Icon(Icons.list),
        ),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 16),
          child: Icon(Icons.grid_view),
        ),
      ],
    );
  }
}
