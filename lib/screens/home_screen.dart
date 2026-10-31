import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../services/chef_brain.dart';
import '../services/detector_service.dart';
import '../services/recipe_generator.dart';
import '../strings.dart';
import '../widgets/app_card.dart';
import '../widgets/app_page.dart';
import '../widgets/app_sizes.dart';
import '../widgets/big_action_button.dart';
import '../widgets/custom_text.dart';
import '../widgets/friendly_dialog.dart';
import '../widgets/layout_helper.dart';
import '../widgets/step_indicator.dart';
import 'check_food_screen.dart';
import 'model_download_screen.dart';
import 'settings_screen.dart';

/// Step 1. The child takes one photo or picks one from the gallery.
class HomeScreen extends StatefulWidget {
  const HomeScreen({
    super.key,
    required this.detector,
    required this.chefBrain,
    required this.generator,
  });

  final DetectorService detector;
  final ChefBrain chefBrain;
  final RecipeGenerator generator;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final ImagePicker _imagePicker = ImagePicker();
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    // Android can close our app while the camera is open. Pick the photo up again.
    _checkLostPhoto();
  }

  Future<void> _checkLostPhoto() async {
    try {
      final LostDataResponse response = await _imagePicker.retrieveLostData();
      if (response.isEmpty || response.file == null) {
        return;
      }
      final Uint8List bytes = await response.file!.readAsBytes();
      if (!mounted) {
        return;
      }
      _openCheckScreen(bytes);
    } catch (error) {
      debugPrint('Could not recover a lost photo: $error');
    }
  }

  Future<void> _takePhoto() async {
    await _pickPhoto(ImageSource.camera);
  }

  Future<void> _pickFromGallery() async {
    await _pickPhoto(ImageSource.gallery);
  }

  /// Opens the camera or gallery and handles every friendly error case.
  Future<void> _pickPhoto(ImageSource source) async {
    if (_busy) {
      return;
    }
    if (widget.detector.status == DetectorStatus.loading) {
      _showSnackBar(AppStrings.getReady);
      return;
    }
    if (widget.detector.status == DetectorStatus.failed &&
        !await _showModelFailedDialog()) {
      return;
    }
    if (!mounted) {
      return;
    }

    setState(() => _busy = true);
    XFile? file;
    try {
      file = await _imagePicker.pickImage(
        source: source,
        maxWidth: 1280,
        maxHeight: 1280,
        imageQuality: 85,
        preferredCameraDevice: CameraDevice.rear,
      );
    } catch (error) {
      debugPrint('Could not open $source: $error');
      if (mounted) {
        setState(() => _busy = false);
        await _showPickerProblem(source);
      }
      return;
    }
    if (!mounted) {
      return;
    }
    setState(() => _busy = false);

    // Null means the child changed their mind. We simply stay here.
    if (file == null) {
      return;
    }

    Uint8List bytes;
    try {
      bytes = await file.readAsBytes();
    } catch (error) {
      debugPrint('Could not read the photo: $error');
      if (mounted) {
        await _showPhotoProblem(source);
      }
      return;
    }
    if (!mounted) {
      return;
    }
    if (bytes.isEmpty) {
      await _showPhotoProblem(source);
      return;
    }
    _openCheckScreen(bytes);
  }

  void _openCheckScreen(Uint8List bytes) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        settings: const RouteSettings(name: 'check'),
        builder: (BuildContext context) => CheckFoodScreen(
          detector: widget.detector,
          chefBrain: widget.chefBrain,
          generator: widget.generator,
          photoBytes: bytes,
        ),
      ),
    );
  }

  void _openManualFoods() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        settings: const RouteSettings(name: 'check'),
        builder: (BuildContext context) => CheckFoodScreen(
          detector: widget.detector,
          chefBrain: widget.chefBrain,
          generator: widget.generator,
          autoDetect: false,
        ),
      ),
    );
  }

  void _openSettings() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (BuildContext context) => SettingsScreen(
          chefBrain: widget.chefBrain,
          generator: widget.generator,
        ),
      ),
    );
  }

  Future<void> _openChefBrain() async {
    await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (BuildContext context) =>
            ModelDownloadScreen(chefBrain: widget.chefBrain),
      ),
    );
    if (mounted) {
      await widget.chefBrain.refresh();
    }
  }

  void _handleChefBrainTap() {
    if (widget.chefBrain.isReady) {
      _openSettings();
      return;
    }
    unawaited(_openChefBrain());
  }

  Future<void> _showPickerProblem(ImageSource source) async {
    final bool camera = source == ImageSource.camera;
    final bool? openGallery = await showFriendlyDialog(
      context,
      emoji: camera ? '📷' : '🖼️',
      title: camera
          ? AppStrings.cameraProblemTitle
          : AppStrings.galleryProblemTitle,
      body: camera
          ? AppStrings.cameraProblemBody
          : AppStrings.galleryProblemBody,
      primaryLabel: AppStrings.pickGallery,
      secondaryLabel: AppStrings.addFoodByHand,
    );
    if (!mounted || openGallery == null) {
      return;
    }
    if (openGallery) {
      await _pickPhoto(ImageSource.gallery);
    } else {
      _openManualFoods();
    }
  }

  Future<void> _showPhotoProblem(ImageSource source) async {
    final bool? tryAgain = await showFriendlyDialog(
      context,
      emoji: '🖼️',
      title: AppStrings.photoProblemTitle,
      body: AppStrings.photoProblemBody,
      primaryLabel: AppStrings.retry,
      secondaryLabel: AppStrings.addFoodByHand,
    );
    if (!mounted || tryAgain == null) {
      return;
    }
    if (tryAgain) {
      await _pickPhoto(source);
    } else {
      _openManualFoods();
    }
  }

  /// Returns true when the food finder is awake again.
  Future<bool> _showModelFailedDialog() async {
    final bool? retry = await showFriendlyDialog(
      context,
      emoji: '😴',
      title: AppStrings.modelFailedTitle,
      body: AppStrings.modelFailedBody,
      primaryLabel: AppStrings.retry,
      secondaryLabel: AppStrings.useHands,
    );
    if (!mounted || retry == null) {
      return false;
    }
    if (retry) {
      await widget.detector.loadModel();
      return widget.detector.status == DetectorStatus.ready;
    }
    _openManualFoods();
    return false;
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: CustomText(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: AnimatedBuilder(
          animation: Listenable.merge(<Listenable>[
            widget.detector,
            widget.chefBrain,
          ]),
          builder: (BuildContext context, Widget? child) {
            return LayoutBuilder(
              builder: (BuildContext context, BoxConstraints constraints) {
                final bool wide = isWideScreen(constraints.maxWidth);
                if (wide) {
                  return _buildWide(context);
                }
                return _buildNarrow(context);
              },
            );
          },
        ),
      ),
    );
  }

  Widget _buildNarrow(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;
    return AppScrollBody(
      maxWidth: 720,
      horizontalPadding: AppSpacing.xxl,
      topPadding: AppSpacing.xxl,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _TopBar(onSettings: _openSettings),
          const SizedBox(height: AppSpacing.xs),
          const _MascotHeader(centered: true),
          const SizedBox(height: AppSpacing.xl),
          _ModelBanner(
            detector: widget.detector,
            onRetry: widget.detector.loadModel,
            onManual: _openManualFoods,
          ),
          const SizedBox(height: AppSpacing.lg),
          _ChefBrainBanner(
            chefBrain: widget.chefBrain,
            onTap: _handleChefBrainTap,
          ),
          const SizedBox(height: AppSpacing.lg),
          _ActionButtons(
            busy: _busy,
            status: widget.detector.status,
            onCamera: _takePhoto,
            onGallery: _pickFromGallery,
          ),
          const SizedBox(height: AppSpacing.xxl),
          const HowItWorksStrip(),
          const SizedBox(height: AppSpacing.lg),
          const _OfflineBadge(),
          const SizedBox(height: AppSpacing.md),
          CustomText.bodyMedium(
            AppStrings.homeHint,
            textAlign: TextAlign.center,
            color: colors.onSurfaceVariant,
          ),
        ],
      ),
    );
  }

  Widget _buildWide(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.xxxl,
              AppSpacing.xxl,
              AppSpacing.xl,
              AppSpacing.xxxl,
            ),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 460),
                child: const _MascotHeader(centered: false),
              ),
            ),
          ),
        ),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.xl,
              AppSpacing.xxl,
              AppSpacing.xxxl,
              AppSpacing.xxxl,
            ),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 520),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _TopBar(onSettings: _openSettings),
                    const SizedBox(height: AppSpacing.xs),
                    _ModelBanner(
                      detector: widget.detector,
                      onRetry: widget.detector.loadModel,
                      onManual: _openManualFoods,
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    _ChefBrainBanner(
                      chefBrain: widget.chefBrain,
                      onTap: _handleChefBrainTap,
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    _ActionButtons(
                      busy: _busy,
                      status: widget.detector.status,
                      onCamera: _takePhoto,
                      onGallery: _pickFromGallery,
                    ),
                    const SizedBox(height: AppSpacing.xxl),
                    const HowItWorksStrip(),
                    const SizedBox(height: AppSpacing.lg),
                    const _OfflineBadge(),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// Settings stays out of the way in the top corner.
class _TopBar extends StatelessWidget {
  const _TopBar({required this.onSettings});

  final VoidCallback onSettings;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: <Widget>[
        SizedBox(
          width: AppSizes.touchTarget,
          height: AppSizes.touchTarget,
          child: IconButton.filledTonal(
            onPressed: onSettings,
            tooltip: AppStrings.settings,
            icon: const Icon(Icons.settings_outlined, size: AppSizes.iconLarge),
          ),
        ),
      ],
    );
  }
}

/// A small card that shows whether the AI chef is ready.
class _ChefBrainBanner extends StatelessWidget {
  const _ChefBrainBanner({required this.chefBrain, required this.onTap});

  final ChefBrain chefBrain;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;
    final ChefBrainStatus status = chefBrain.status;
    final bool ready = status == ChefBrainStatus.ready;
    final bool downloading = status == ChefBrainStatus.downloading;
    final bool failed = status == ChefBrainStatus.failed;
    final Color background = ready
        ? colors.primaryContainer
        : failed
        ? colors.errorContainer
        : colors.secondaryContainer;

    final String title = switch (status) {
      ChefBrainStatus.ready => AppStrings.chefBrainReady,
      ChefBrainStatus.missing => AppStrings.chefBrainMissing,
      ChefBrainStatus.downloading => AppStrings.chefBrainDownloading,
      ChefBrainStatus.failed => AppStrings.chefBrainFailed,
      ChefBrainStatus.checking => AppStrings.chefBrainChecking,
    };

    return Semantics(
      button: true,
      label: title,
      child: AppCard(
        color: background,
        padding: const EdgeInsets.all(AppSpacing.lg),
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Row(
              children: <Widget>[
                const AppEmoji('🧠', size: AppSizes.emojiMedium),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      CustomText.titleMedium(title),
                      const SizedBox(height: AppSpacing.xxs),
                      CustomText.bodySmall(
                        ready
                            ? AppStrings.chefBrainReadyBody
                            : AppStrings.chefBrainMissingBody,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Icon(
                  ready ? Icons.check_circle : Icons.download,
                  color: colors.onSecondaryContainer,
                ),
              ],
            ),
            if (downloading) ...<Widget>[
              const SizedBox(height: AppSpacing.sm),
              ClipRRect(
                borderRadius: BorderRadius.circular(AppRadius.pill),
                child: LinearProgressIndicator(
                  value: chefBrain.progress / 100,
                  minHeight: 10,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Big emoji picture and the app name.
class _MascotHeader extends StatelessWidget {
  const _MascotHeader({required this.centered});

  final bool centered;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: centered
          ? CrossAxisAlignment.center
          : CrossAxisAlignment.start,
      children: [
        Semantics(
          label: AppStrings.mascotSemantic,
          child: SizedBox(
            width: 170,
            height: 170,
            child: Stack(
              alignment: Alignment.center,
              children: [
                Container(
                  width: 154,
                  height: 154,
                  decoration: BoxDecoration(
                    color: colors.primaryContainer,
                    shape: BoxShape.circle,
                  ),
                ),
                const AppEmoji('🧑‍🍳', size: AppSizes.emojiMascot),
                const Positioned(
                  left: 2,
                  top: 20,
                  child: AppEmoji('🍎', size: AppSizes.emojiMedium),
                ),
                const Positioned(
                  right: 6,
                  top: 46,
                  child: AppEmoji('🥦', size: AppSizes.emoji),
                ),
                const Positioned(
                  right: 26,
                  bottom: 2,
                  child: AppEmoji('🧀', size: AppSizes.emojiMedium),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        CustomText.headlineLarge(
          AppStrings.appName,
          textAlign: centered ? TextAlign.center : TextAlign.start,
          color: colors.primary,
        ),
        const SizedBox(height: AppSpacing.sm),
        CustomText.headlineSmall(
          AppStrings.homeTitle,
          textAlign: centered ? TextAlign.center : TextAlign.start,
        ),
        const SizedBox(height: AppSpacing.sm),
        CustomText.bodyLarge(
          AppStrings.homeSubtitle,
          textAlign: centered ? TextAlign.center : TextAlign.start,
        ),
      ],
    );
  }
}

/// Shows a friendly note while the food finder is loading or sleepy.
class _ModelBanner extends StatelessWidget {
  const _ModelBanner({
    required this.detector,
    required this.onRetry,
    required this.onManual,
  });

  final DetectorService detector;
  final VoidCallback onRetry;
  final VoidCallback onManual;

  @override
  Widget build(BuildContext context) {
    if (detector.status == DetectorStatus.ready) {
      return const SizedBox.shrink();
    }
    final bool loading = detector.status == DetectorStatus.loading;
    final ColorScheme colors = Theme.of(context).colorScheme;
    return AppCard(
      color: loading ? colors.secondaryContainer : colors.errorContainer,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (loading)
                const SizedBox(
                  width: AppSizes.icon,
                  height: AppSizes.icon,
                  child: CircularProgressIndicator(strokeWidth: 3),
                )
              else
                const AppEmoji('😴', size: AppSizes.emojiMedium),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: CustomText.titleMedium(
                  loading
                      ? AppStrings.loadingTitle
                      : AppStrings.modelFailedTitle,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          CustomText.bodyMedium(
            loading ? AppStrings.loadingBody : AppStrings.modelFailedBody,
          ),
          if (!loading) ...[
            const SizedBox(height: AppSpacing.md),
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: [
                FilledButton.tonalIcon(
                  onPressed: onRetry,
                  icon: const Icon(Icons.refresh),
                  label: const CustomText(AppStrings.retry),
                ),
                OutlinedButton.icon(
                  onPressed: onManual,
                  icon: const Icon(Icons.edit_outlined),
                  label: const CustomText(AppStrings.useHands),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

/// The giant photo button and the smaller gallery button.
class _ActionButtons extends StatelessWidget {
  const _ActionButtons({
    required this.busy,
    required this.status,
    required this.onCamera,
    required this.onGallery,
  });

  final bool busy;
  final DetectorStatus status;
  final VoidCallback onCamera;
  final VoidCallback onGallery;

  @override
  Widget build(BuildContext context) {
    final bool loading = status == DetectorStatus.loading;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        BigActionButton(
          label: loading ? AppStrings.getReady : AppStrings.takePhoto,
          icon: Icons.photo_camera,
          onPressed: onCamera,
          busy: busy,
          semanticLabel: AppStrings.takePhoto,
        ),
        const SizedBox(height: AppSpacing.md),
        Semantics(
          button: true,
          enabled: !busy && !loading,
          label: AppStrings.pickGallery,
          child: OutlinedButton.icon(
            onPressed: busy || loading ? null : onGallery,
            icon: const Icon(Icons.photo_library_outlined),
            label: const CustomText(AppStrings.pickGallery),
          ),
        ),
      ],
    );
  }
}

/// A small reminder that the app can work in airplane mode.
class _OfflineBadge extends StatelessWidget {
  const _OfflineBadge();

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          Icons.download_done,
          size: AppSizes.iconSmall,
          color: colors.onSurfaceVariant,
        ),
        const SizedBox(width: AppSpacing.sm),
        Flexible(
          child: CustomText.bodyMedium(
            AppStrings.offlineBadge,
            textAlign: TextAlign.center,
            color: colors.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}
