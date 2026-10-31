import 'package:flutter/material.dart';

import '../data/ingredients.dart';
import '../strings.dart';
import 'app_card.dart';
import 'app_sizes.dart';
import 'custom_text.dart';

/// Opens the bottom sheet with big food tiles.
/// Returns the new set of food ids, or null if the child closed it.
Future<Set<String>?> openAddFoodSheet(
  BuildContext context, {
  required Set<String> currentFoodIds,
}) {
  return showModalBottomSheet<Set<String>>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (BuildContext sheetContext) {
      return AddFoodSheet(currentFoodIds: currentFoodIds);
    },
  );
}

/// A grid of common fridge foods. Tap a tile to add or remove that food.
class AddFoodSheet extends StatefulWidget {
  const AddFoodSheet({super.key, required this.currentFoodIds});

  final Set<String> currentFoodIds;

  @override
  State<AddFoodSheet> createState() => _AddFoodSheetState();
}

class _AddFoodSheetState extends State<AddFoodSheet> {
  late final Set<String> _selectedIds;

  @override
  void initState() {
    super.initState();
    _selectedIds = {...widget.currentFoodIds};
  }

  void _toggleFood(String id) {
    setState(() {
      if (_selectedIds.contains(id)) {
        _selectedIds.remove(id);
      } else {
        _selectedIds.add(id);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final double screenHeight = MediaQuery.sizeOf(context).height;
    final double textScale = MediaQuery.textScalerOf(context).scale(14) / 14;
    final double tileHeight = 76 + 26 * textScale;
    final double screenWidth = MediaQuery.sizeOf(context).width;
    int columns = 3;
    if (screenWidth >= 900) {
      columns = 7;
    } else if (screenWidth >= 700) {
      columns = 6;
    } else if (screenWidth >= 520) {
      columns = 5;
    } else if (screenWidth >= 400) {
      columns = 4;
    }

    return SizedBox(
      height: screenHeight * 0.88,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.xl,
              AppSpacing.xs,
              AppSpacing.xl,
              AppSpacing.sm,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CustomText.headlineSmall(AppStrings.addFoodTitle),
                const SizedBox(height: AppSpacing.xs),
                CustomText.bodyMedium(AppStrings.addFoodSubtitle),
              ],
            ),
          ),
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg,
                AppSpacing.sm,
                AppSpacing.lg,
                AppSpacing.md,
              ),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: columns,
                mainAxisSpacing: AppSpacing.md,
                crossAxisSpacing: AppSpacing.md,
                mainAxisExtent: tileHeight,
              ),
              itemCount: commonFoodIds.length,
              itemBuilder: (BuildContext context, int index) {
                final Ingredient? food = findIngredient(commonFoodIds[index]);
                if (food == null) {
                  return const SizedBox.shrink();
                }
                return _FoodTile(
                  food: food,
                  isSelected: _selectedIds.contains(food.id),
                  onTap: () => _toggleFood(food.id),
                );
              },
            ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.xl,
                AppSpacing.xs,
                AppSpacing.xl,
                AppSpacing.lg,
              ),
              child: FilledButton.icon(
                onPressed: () => Navigator.of(context).pop(_selectedIds),
                icon: const Icon(Icons.check),
                label: CustomText(
                  AppStrings.doneWithCount(_selectedIds.length),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// One big emoji tile in the add-food grid.
class _FoodTile extends StatelessWidget {
  const _FoodTile({
    required this.food,
    required this.isSelected,
    required this.onTap,
  });

  final Ingredient food;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;
    return Semantics(
      button: true,
      selected: isSelected,
      label: isSelected
          ? AppStrings.addedFoodSemantic(food.name)
          : AppStrings.notAddedFoodSemantic(food.name),
      child: AppCard(
        color: isSelected
            ? colors.primaryContainer
            : colors.surfaceContainerHigh,
        radius: AppRadius.large,
        padding: const EdgeInsets.all(AppSpacing.sm),
        border: Border.all(
          color: isSelected ? colors.primary : colors.outlineVariant,
          width: 2,
        ),
        onTap: onTap,
        child: Stack(
          children: [
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    height: 34,
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: AppEmoji(food.emoji, size: AppSizes.emojiMedium),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  CustomText.labelMedium(
                    food.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
            if (isSelected)
              Positioned(
                top: 0,
                right: 0,
                child: Icon(
                  Icons.check_circle,
                  size: AppSizes.iconSmall,
                  color: colors.primary,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
