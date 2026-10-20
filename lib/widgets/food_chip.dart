import 'package:flutter/material.dart';

import '../data/ingredients.dart';
import '../strings.dart';

/// A food pill. Tap it to take that food out of the list.
class FoodChip extends StatelessWidget {
  const FoodChip({super.key, required this.food, required this.onRemove});

  final Ingredient food;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: '${food.name}. ${AppStrings.listeningHint}',
      child: InputChip(
        avatar: ExcludeSemantics(
          child: Text(food.emoji, style: const TextStyle(fontSize: 22)),
        ),
        label: Text(food.name),
        onPressed: onRemove,
        onDeleted: onRemove,
        deleteIcon: const Icon(Icons.close, size: 20),
        deleteButtonTooltipMessage: '${AppStrings.removeFood} ${food.name}',
        tooltip: AppStrings.listeningHint,
        visualDensity: VisualDensity.comfortable,
        materialTapTargetSize: MaterialTapTargetSize.padded,
      ),
    );
  }
}
