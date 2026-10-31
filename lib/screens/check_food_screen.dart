import 'dart:async';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../data/ingredients.dart';
import '../services/chef_brain.dart';
import '../services/detector_service.dart';
import '../services/recipe_generator.dart';
import '../strings.dart';
import '../widgets/add_food_sheet.dart';
import '../widgets/app_card.dart';
import '../widgets/app_page.dart';
import '../widgets/app_sizes.dart';
import '../widgets/big_action_button.dart';
import '../widgets/custom_text.dart';
import '../widgets/food_chip.dart';
import '../widgets/food_feedback.dart';
import '../widgets/friendly_dialog.dart';
import '../widgets/layout_helper.dart';
import '../widgets/photo_with_boxes.dart';
import '../widgets/step_indicator.dart';
import 'model_download_screen.dart';
import 'roulette_screen.dart';

/// Why the food finder could not show a normal food list.
enum _ScanProblem { none, model, noFood, slow, photo }

/// Step 2. The child checks the foods we found, removes wrong ones,
/// and adds anything the food finder missed.
class CheckFoodScreen extends StatefulWidget {
  const CheckFoodScreen({
    super.key,
    required this.detector,
    required this.chefBrain,
    required this.generator,
    this.photoBytes,
    this.autoDetect = true,
  });

  final DetectorService detector;
  final ChefBrain chefBrain;
  final RecipeGenerator generator;

  /// Null when the child chose to add food by hand, without a photo.
  final Uint8List? photoBytes;

  /// False when the child skipped the photo. We then open the food list.
  final bool autoDetect;

  @override
  State<CheckFoodScreen> createState() => _CheckFoodScreenState();
}

class _CheckFoodScreenState extends State<CheckFoodScreen> {
  final Set<String> _foodIds = <String>{};
  final List<FoodDetection> _detections = <FoodDetection>[];

  bool _detecting = false;
  bool _leaveDialogOpen = false;
  bool _askedAboutAi = false;
  double _aspectRatio = 3 / 4;
  _ScanProblem _problem = _ScanProblem.none;

  @override
  void initState() {
    super.initState();
    if (widget.photoBytes != null) {
      _readPhotoShape();
      if (widget.autoDetect) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            _scanPhoto();
          }
        });
      }
    } else if (!widget.autoDetect) {
      // The child came here to add food by hand, so show the food tiles.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _openFoodSheet();
        }
      });
    }
  }

  /// Reads the real photo width and height so the boxes line up.
  Future<void> _readPhotoShape() async {
    final Uint8List? bytes = widget.photoBytes;
    if (bytes == null) {
      return;
    }
    ui.Codec? codec;
    try {
      codec = await ui.instantiateImageCodec(bytes);
      final ui.FrameInfo frame = await codec.getNextFrame();
      final double ratio = frame.image.width / frame.image.height;
      frame.image.dispose();
      if (!mounted) {
        return;
      }
      if (ratio.isFinite && ratio > 0.2 && ratio < 5) {
        setState(() => _aspectRatio = ratio);
      }
    } catch (error) {
      // A normal photo box still looks fine, so we keep the default shape.
      debugPrint('Could not read the photo shape: $error');
    } finally {
      codec?.dispose();
    }
  }

  /// Looks at the photo one time, or again when the child taps Try Again.
  Future<void> _scanPhoto() async {
    final Uint8List? bytes = widget.photoBytes;
    if (bytes == null || _detecting) {
      return;
    }
    setState(() {
      _detecting = true;
      _problem = _ScanProblem.none;
    });

    if (widget.detector.status != DetectorStatus.ready) {
      await widget.detector.loadModel();
    }
    if (!mounted) {
      return;
    }
    if (widget.detector.status != DetectorStatus.ready) {
      setState(() {
        _detecting = false;
        _problem = _ScanProblem.model;
      });
      return;
    }

    try {
      final DetectionResult result = await widget.detector.detectFoods(bytes);
      if (!mounted) {
        return;
      }
      setState(() {
        _detecting = false;
        _detections
          ..clear()
          ..addAll(result.detections);
        for (final FoodDetection detection in result.detections) {
          _foodIds.add(detection.food.id);
        }
        if (result.detections.isEmpty) {
          _problem = _ScanProblem.noFood;
        }
      });
    } on ScanCancelledException {
      // The child tapped Stop or left the page. Do not show an error.
      if (!mounted) {
        return;
      }
      setState(() {
        _detecting = false;
        _problem = _ScanProblem.none;
      });
    } on TimeoutException {
      if (!mounted) {
        return;
      }
      setState(() {
        _detecting = false;
        _problem = _ScanProblem.slow;
      });
    } catch (error) {
      debugPrint('The food finder had a problem: $error');
      if (!mounted) {
        return;
      }
      setState(() {
        _detecting = false;
        _problem = _ScanProblem.photo;
      });
    }
  }

  /// Asks the finder to stop. The overlay stays until the current close-up
  /// finishes, then the scan ends without an error card.
  void _stopScan() {
    widget.detector.cancelScan();
  }

  @override
  void dispose() {
    if (_detecting) {
      widget.detector.cancelScan();
    }
    super.dispose();
  }

  /// Opens the big food grid. The child can add and remove foods there.
  Future<void> _openFoodSheet() async {
    if (_detecting) {
      return;
    }
    final Set<String>? chosen = await openAddFoodSheet(
      context,
      currentFoodIds: _foodIds,
    );
    if (!mounted || chosen == null) {
      return;
    }
    setState(() {
      _foodIds
        ..clear()
        ..addAll(chosen);
      // The child fixed the empty list, so the warning can go away.
      if (_problem == _ScanProblem.noFood && _foodIds.isNotEmpty) {
        _problem = _ScanProblem.none;
      }
    });
  }

  void _removeFood(String id) {
    setState(() => _foodIds.remove(id));
  }

  Future<void> _spinTheWheel() async {
    // On the first recipe request we offer the one-time chef brain download.
    // If the child skips it, the Quick chef still makes a recipe.
    if (!_askedAboutAi && !widget.chefBrain.isReady) {
      _askedAboutAi = true;
      await Navigator.of(context).push<bool>(
        MaterialPageRoute<bool>(
          builder: (BuildContext context) =>
              ModelDownloadScreen(chefBrain: widget.chefBrain),
        ),
      );
      if (!mounted) {
        return;
      }
      await widget.chefBrain.refresh();
      if (!mounted) {
        return;
      }
    }

    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        settings: const RouteSettings(name: 'roulette'),
        builder: (BuildContext context) => RouletteScreen(
          chefBrain: widget.chefBrain,
          generator: widget.generator,
          foodIds: _foodIds.toList(),
        ),
      ),
    );
  }

  /// Asks before throwing away the photo and the food list.
  Future<void> _confirmLeave() async {
    if (_leaveDialogOpen) {
      return;
    }
    _leaveDialogOpen = true;
    final bool? stay = await showFriendlyDialog(
      context,
      emoji: '🚪',
      title: AppStrings.leaveTitle,
      body: AppStrings.leaveBody,
      primaryLabel: AppStrings.stay,
      secondaryLabel: AppStrings.leave,
    );
    _leaveDialogOpen = false;
    if (!mounted || stay == null) {
      return;
    }
    if (!stay) {
      widget.detector.cancelScan();
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope<Object?>(
      canPop: false,
      onPopInvokedWithResult: (bool didPop, Object? result) {
        if (didPop) {
          return;
        }
        _confirmLeave();
      },
      child: AppPage(
        title: AppStrings.checkTitle,
        body: Stack(
          children: [
            LayoutBuilder(
              builder: (BuildContext context, BoxConstraints constraints) {
                if (isWideScreen(constraints.maxWidth)) {
                  return _buildWide(context);
                }
                return _buildNarrow(context);
              },
            ),
            // A long scan covers the whole page, not just the photo. This
            // keeps the progress bar and Stop button easy to reach even when
            // the photo is a wide panorama.
            if (_detecting)
              Positioned.fill(
                child: ListenableBuilder(
                  listenable: widget.detector,
                  builder: (BuildContext context, Widget? child) {
                    final ScanProgress progress =
                        widget.detector.scanProgress.value;
                    return DetectingOverlay(
                      waitingForModel:
                          widget.detector.status == DetectorStatus.loading,
                      progress: progress.fraction,
                      progressLabel: progress.total <= 0
                          ? null
                          : AppStrings.scanningStep(
                              progress.done,
                              progress.total,
                            ),
                      onCancel: _stopScan,
                      borderRadius: 0,
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildNarrow(BuildContext context) {
    return AppScrollBody(
      topPadding: AppSpacing.sm,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const StepIndicator(currentStep: 1),
          const SizedBox(height: AppSpacing.lg),
          CustomText.bodyLarge(AppStrings.checkSubtitle),
          const SizedBox(height: AppSpacing.lg),
          _buildPhoto(context),
          if (_problem != _ScanProblem.none) ...[
            const SizedBox(height: AppSpacing.lg),
            _buildProblemCard(),
          ],
          const SizedBox(height: AppSpacing.xl),
          _buildFoodList(context),
          const SizedBox(height: AppSpacing.md),
          _buildAddButton(),
          const SizedBox(height: AppSpacing.xl),
          _buildSpinArea(),
        ],
      ),
    );
  }

  Widget _buildWide(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.xxl,
        AppSpacing.sm,
        AppSpacing.xxl,
        AppSpacing.xxl,
      ),
      child: Column(
        children: [
          const StepIndicator(currentStep: 1),
          const SizedBox(height: AppSpacing.lg),
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  flex: 6,
                  child: SingleChildScrollView(child: _buildPhoto(context)),
                ),
                const SizedBox(width: AppSpacing.xxl),
                Expanded(
                  flex: 5,
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        CustomText.bodyLarge(AppStrings.checkSubtitle),
                        if (_problem != _ScanProblem.none) ...[
                          const SizedBox(height: AppSpacing.md),
                          _buildProblemCard(),
                        ],
                        const SizedBox(height: AppSpacing.lg),
                        _buildFoodList(context),
                        const SizedBox(height: AppSpacing.md),
                        _buildAddButton(),
                        const SizedBox(height: AppSpacing.xxl),
                        _buildSpinArea(),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// The photo with boxes, or a soft card when there is no photo.
  Widget _buildPhoto(BuildContext context) {
    final Uint8List? bytes = widget.photoBytes;
    if (bytes == null) {
      return const NoPhotoCard();
    }
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        const double maxHeight = 440;
        double width = constraints.maxWidth;
        double height = width / _aspectRatio;
        if (height > maxHeight) {
          height = maxHeight;
          width = height * _aspectRatio;
        }
        return Center(
          child: SizedBox(
            width: width,
            height: height,
            child: PhotoWithBoxes(
              imageBytes: bytes,
              aspectRatio: _aspectRatio,
              detections: _detections,
              activeFoodIds: _foodIds,
              maxHeight: maxHeight,
            ),
          ),
        );
      },
    );
  }

  /// A friendly card for each thing that can go wrong with the photo.
  Widget _buildProblemCard() {
    switch (_problem) {
      case _ScanProblem.none:
        return const SizedBox.shrink();
      case _ScanProblem.model:
        return FoodProblemCard(
          emoji: '😴',
          title: AppStrings.modelFailedTitle,
          body: AppStrings.modelFailedBody,
          primaryLabel: AppStrings.retry,
          onPrimary: _scanPhoto,
          secondaryLabel: AppStrings.useHands,
          onSecondary: _openFoodSheet,
        );
      case _ScanProblem.noFood:
        return FoodProblemCard(
          emoji: '🔍',
          title: AppStrings.noFoodTitle,
          body: AppStrings.noFoodBody,
          primaryLabel: AppStrings.retry,
          onPrimary: _scanPhoto,
          secondaryLabel: AppStrings.addFoodByHand,
          onSecondary: _openFoodSheet,
        );
      case _ScanProblem.slow:
        return FoodProblemCard(
          emoji: '⏱️',
          title: AppStrings.tooLongTitle,
          body: AppStrings.tooLongBody,
          primaryLabel: AppStrings.retry,
          onPrimary: _scanPhoto,
          secondaryLabel: AppStrings.addFoodByHand,
          onSecondary: _openFoodSheet,
        );
      case _ScanProblem.photo:
        return FoodProblemCard(
          emoji: '🖼️',
          title: AppStrings.photoProblemTitle,
          body: AppStrings.photoProblemBody,
          primaryLabel: AppStrings.retry,
          onPrimary: _scanPhoto,
          secondaryLabel: AppStrings.addFoodByHand,
          onSecondary: _openFoodSheet,
        );
    }
  }

  Widget _buildFoodList(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;
    final List<Ingredient> foods = <Ingredient>[];
    for (final String id in _foodIds) {
      final Ingredient? food = findIngredient(id);
      if (food != null) {
        foods.add(food);
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        CustomText.titleLarge(AppStrings.yourFoods),
        if (foods.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.xxs),
          CustomText.labelLarge(
            AppStrings.foodCount(foods.length),
            color: colors.primary,
          ),
        ],
        const SizedBox(height: AppSpacing.sm),
        if (foods.isEmpty)
          AppCard(
            radius: AppRadius.large,
            padding: const EdgeInsets.all(AppSpacing.lg),
            color: colors.surfaceContainerHigh,
            child: CustomText.bodyLarge(AppStrings.noFoodsYet),
          )
        else
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [
              for (final Ingredient food in foods)
                FoodChip(
                  key: ValueKey<String>(food.id),
                  food: food,
                  onRemove: () => _removeFood(food.id),
                ),
            ],
          ),
      ],
    );
  }

  Widget _buildAddButton() {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton(
        onPressed: _detecting ? null : _openFoodSheet,
        child: const CustomText(AppStrings.addFood),
      ),
    );
  }

  Widget _buildSpinArea() {
    final ColorScheme colors = Theme.of(context).colorScheme;
    final bool enoughFood = _foodIds.length >= 2;
    final bool canSpin = enoughFood && !_detecting;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (!enoughFood) ...[
          Row(
            children: [
              Icon(
                Icons.info_outline,
                size: AppSizes.iconSmall,
                color: colors.onSurfaceVariant,
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: CustomText.bodyMedium(
                  AppStrings.notEnoughHint,
                  color: colors.onSurfaceVariant,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
        ],
        BigActionButton(
          label: AppStrings.spinTheWheel,
          icon: Icons.casino_outlined,
          onPressed: canSpin ? _spinTheWheel : null,
          semanticLabel: canSpin
              ? AppStrings.spinTheWheel
              : AppStrings.notEnoughHint,
        ),
      ],
    );
  }
}
