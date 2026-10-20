import 'dart:async';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../data/ingredients.dart';
import '../services/detector_service.dart';
import '../services/recipe_picker.dart';
import '../strings.dart';
import '../widgets/add_food_sheet.dart';
import '../widgets/big_action_button.dart';
import '../widgets/food_chip.dart';
import '../widgets/food_feedback.dart';
import '../widgets/friendly_dialog.dart';
import '../widgets/layout_helper.dart';
import '../widgets/photo_with_boxes.dart';
import '../widgets/step_indicator.dart';
import 'roulette_screen.dart';

/// Why the food finder could not show a normal food list.
enum _ScanProblem { none, model, noFood, slow, photo }

/// Step 2. The child checks the foods we found, removes wrong ones,
/// and adds anything the food finder missed.
class CheckFoodScreen extends StatefulWidget {
  const CheckFoodScreen({
    super.key,
    required this.detector,
    required this.picker,
    this.photoBytes,
    this.autoDetect = true,
  });

  final DetectorService detector;
  final RecipePicker picker;

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

  void _spinTheWheel() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (BuildContext context) =>
            RouletteScreen(picker: widget.picker, foodIds: _foodIds.toList()),
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
      child: Scaffold(
        appBar: AppBar(title: const Text(AppStrings.checkTitle)),
        body: SafeArea(
          child: LayoutBuilder(
            builder: (BuildContext context, BoxConstraints constraints) {
              if (isWideScreen(constraints.maxWidth)) {
                return _buildWide(context);
              }
              return _buildNarrow(context);
            },
          ),
        ),
      ),
    );
  }

  Widget _buildNarrow(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 760),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const StepIndicator(currentStep: 1),
              const SizedBox(height: 18),
              Text(
                AppStrings.checkSubtitle,
                style: Theme.of(context).textTheme.bodyLarge,
              ),
              const SizedBox(height: 16),
              _buildPhoto(context),
              if (_problem != _ScanProblem.none) ...[
                const SizedBox(height: 16),
                _buildProblemCard(),
              ],
              const SizedBox(height: 22),
              _buildFoodList(context),
              const SizedBox(height: 14),
              _buildAddButton(),
              const SizedBox(height: 22),
              _buildSpinArea(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildWide(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(28, 8, 28, 24),
      child: Column(
        children: [
          const StepIndicator(currentStep: 1),
          const SizedBox(height: 16),
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  flex: 6,
                  child: SingleChildScrollView(child: _buildPhoto(context)),
                ),
                const SizedBox(width: 28),
                Expanded(
                  flex: 5,
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          AppStrings.checkSubtitle,
                          style: Theme.of(context).textTheme.bodyLarge,
                        ),
                        if (_problem != _ScanProblem.none) ...[
                          const SizedBox(height: 14),
                          _buildProblemCard(),
                        ],
                        const SizedBox(height: 18),
                        _buildFoodList(context),
                        const SizedBox(height: 14),
                        _buildAddButton(),
                        const SizedBox(height: 24),
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
            child: Stack(
              fit: StackFit.expand,
              children: [
                PhotoWithBoxes(
                  imageBytes: bytes,
                  aspectRatio: _aspectRatio,
                  detections: _detections,
                  activeFoodIds: _foodIds,
                  maxHeight: maxHeight,
                ),
                if (_detecting)
                  DetectingOverlay(
                    waitingForModel:
                        widget.detector.status == DetectorStatus.loading,
                  ),
              ],
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
        Text(
          AppStrings.yourFoods,
          style: Theme.of(context).textTheme.titleLarge,
        ),
        if (foods.isNotEmpty) ...[
          const SizedBox(height: 2),
          Text(
            AppStrings.foodCount(foods.length),
            style: Theme.of(
              context,
            ).textTheme.labelLarge?.copyWith(color: colors.primary),
          ),
        ],
        const SizedBox(height: 10),
        if (foods.isEmpty)
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: colors.surfaceContainerHigh,
              borderRadius: BorderRadius.circular(18),
            ),
            child: Text(
              AppStrings.noFoodsYet,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
          )
        else
          Wrap(
            spacing: 8,
            runSpacing: 8,
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
        child: const Text(AppStrings.addFood),
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
                size: 20,
                color: colors.onSurfaceVariant,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  AppStrings.notEnoughHint,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: colors.onSurfaceVariant,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
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
