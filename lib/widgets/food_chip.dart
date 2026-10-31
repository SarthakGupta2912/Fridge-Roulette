import 'package:flutter/material.dart';

import '../data/ingredients.dart';
import '../strings.dart';
import 'app_sizes.dart';
import 'custom_text.dart';

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
        avatar: AppEmoji(food.emoji, size: 22),
        label: CustomText(food.name),
        onPressed: onRemove,
        onDeleted: onRemove,
        deleteIcon: const Icon(Icons.close, size: AppSizes.iconSmall),
        deleteButtonTooltipMessage: '${AppStrings.removeFood} ${food.name}',
        tooltip: AppStrings.listeningHint,
        visualDensity: VisualDensity.comfortable,
        materialTapTargetSize: MaterialTapTargetSize.padded,
      ),
    );
  }
}
