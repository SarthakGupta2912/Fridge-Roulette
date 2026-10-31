import 'package:flutter/material.dart';

import '../data/model_info.dart';
import '../services/chef_brain.dart';
import '../services/recipe_generator.dart';
import '../strings.dart';
import '../widgets/app_card.dart';
import '../widgets/app_page.dart';
import '../widgets/app_sizes.dart';
import '../widgets/custom_text.dart';
import '../widgets/friendly_dialog.dart';
import 'model_download_screen.dart';

/// Settings and About. The main job is showing the Chef brain status.
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({
    super.key,
    required this.chefBrain,
    required this.generator,
  });

  final ChefBrain chefBrain;
  final RecipeGenerator generator;

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _deleting = false;

  Future<void> _openDownload() async {
    await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (BuildContext context) =>
            ModelDownloadScreen(chefBrain: widget.chefBrain, canSkip: false),
      ),
    );
    if (mounted) {
      await widget.chefBrain.refresh();
    }
  }

  Future<void> _deleteModel() async {
    final bool? delete = await showFriendlyDialog(
      context,
      emoji: '🗑️',
      title: AppStrings.deleteModelTitle,
      body: AppStrings.deleteModelBody,
      primaryLabel: AppStrings.delete,
      secondaryLabel: AppStrings.cancel,
    );
    if (!mounted || delete != true) {
      return;
    }

    setState(() => _deleting = true);
    try {
      await widget.generator.release();
      await widget.chefBrain.deleteModel();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: CustomText(AppStrings.modelDeleted)),
        );
      }
    } catch (error) {
      debugPrint('Could not delete the chef brain: $error');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: CustomText(AppStrings.downloadGenericBody)),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _deleting = false);
      }
    }
  }

  String _statusLabel(ChefBrainStatus status) {
    switch (status) {
      case ChefBrainStatus.checking:
        return AppStrings.chefBrainChecking;
      case ChefBrainStatus.ready:
        return AppStrings.chefBrainReady;
      case ChefBrainStatus.downloading:
        return AppStrings.chefBrainDownloading;
      case ChefBrainStatus.failed:
        return AppStrings.chefBrainFailed;
      case ChefBrainStatus.missing:
        return AppStrings.chefBrainMissing;
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.chefBrain,
      builder: (BuildContext context, Widget? child) {
        return AppPage(
          title: AppStrings.settingsTitle,
          body: AppScrollBody(
            topPadding: AppSpacing.md,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                _buildChefBrain(context),
                const SizedBox(height: AppSpacing.xl),
                _buildAbout(context),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildChefBrain(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;
    final ChefBrainStatus status = widget.chefBrain.status;
    final bool ready = status == ChefBrainStatus.ready;
    final bool downloading = status == ChefBrainStatus.downloading;
    final bool failed = status == ChefBrainStatus.failed;

    return AppCard(
      color: colors.surfaceContainerHigh,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Row(
            children: <Widget>[
              const AppEmoji('🧠', size: 38),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    CustomText.titleLarge(AppStrings.chefBrainTitle),
                    const SizedBox(height: AppSpacing.xxs),
                    CustomText.titleMedium(
                      _statusLabel(status),
                      color: ready ? colors.primary : colors.onSurfaceVariant,
                    ),
                  ],
                ),
              ),
              if (ready)
                Icon(
                  Icons.check_circle,
                  color: colors.primary,
                  size: AppSizes.iconLarge,
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          CustomText.bodyMedium(
            ready
                ? AppStrings.chefBrainReadyBody
                : downloading
                ? AppStrings.chefBrainDownloading
                : AppStrings.chefBrainMissingBody,
          ),
          if (failed && widget.chefBrain.error != null) ...<Widget>[
            const SizedBox(height: AppSpacing.sm),
            CustomText.bodySmall(
              AppStrings.downloadGenericBody,
              color: colors.error,
            ),
          ],
          if (downloading) ...<Widget>[
            const SizedBox(height: AppSpacing.md),
            ClipRRect(
              borderRadius: BorderRadius.circular(AppRadius.pill),
              child: LinearProgressIndicator(
                value: widget.chefBrain.progress / 100,
                minHeight: 14,
              ),
            ),
          ],
          const SizedBox(height: AppSpacing.md),
          AppInfoRow(label: AppStrings.modelName, value: ModelInfo.name),
          AppInfoRow(label: AppStrings.modelSize, value: ModelInfo.sizeLabel),
          AppInfoRow(
            label: AppStrings.modelLicense,
            value: ModelInfo.licenseName,
          ),
          const SizedBox(height: AppSpacing.sm),
          AppSelectableText(
            ModelInfo.licenseUrl,
            variant: AppTextVariant.bodySmall,
            color: colors.primary,
          ),
          const SizedBox(height: AppSpacing.lg),
          if (ready)
            OutlinedButton.icon(
              onPressed: _deleting ? null : _deleteModel,
              icon: _deleting
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.delete_outline),
              label: const CustomText(AppStrings.deleteModel),
            )
          else
            FilledButton.icon(
              onPressed: downloading ? _openDownload : _openDownload,
              icon: const Icon(Icons.download),
              label: const CustomText(AppStrings.downloadAiChef),
            ),
        ],
      ),
    );
  }

  Widget _buildAbout(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;
    return AppCard(
      color: colors.secondaryContainer,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          CustomText.titleLarge(AppStrings.aboutTitle),
          const SizedBox(height: AppSpacing.sm),
          CustomText.bodyMedium(AppStrings.aboutBody),
          const SizedBox(height: AppSpacing.sm),
          CustomText.bodyMedium(AppStrings.privacyPromise),
          const SizedBox(height: AppSpacing.md),
          CustomText.labelLarge(
            AppStrings.appVersion,
            color: colors.onSecondaryContainer,
          ),
        ],
      ),
    );
  }
}
