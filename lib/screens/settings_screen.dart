import 'package:flutter/material.dart';

import '../data/model_info.dart';
import '../services/chef_brain.dart';
import '../services/recipe_generator.dart';
import '../strings.dart';
import '../widgets/friendly_dialog.dart';
import '../widgets/layout_helper.dart';
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
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text(AppStrings.modelDeleted)));
      }
    } catch (error) {
      debugPrint('Could not delete the chef brain: $error');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text(AppStrings.downloadGenericBody)),
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
        return Scaffold(
          appBar: AppBar(title: const Text(AppStrings.settingsTitle)),
          body: SafeArea(
            child: LayoutBuilder(
              builder: (BuildContext context, BoxConstraints constraints) {
                final bool wide = isWideScreen(constraints.maxWidth);
                return SingleChildScrollView(
                  padding: EdgeInsets.fromLTRB(
                    wide ? 28 : 20,
                    12,
                    wide ? 28 : 20,
                    32,
                  ),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 760),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: <Widget>[
                          _buildChefBrain(context),
                          const SizedBox(height: 20),
                          _buildAbout(context),
                        ],
                      ),
                    ),
                  ),
                );
              },
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

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: colors.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Row(
            children: <Widget>[
              const ExcludeSemantics(
                child: Text('🧠', style: TextStyle(fontSize: 38)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      AppStrings.chefBrainTitle,
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _statusLabel(status),
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: ready ? colors.primary : colors.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              if (ready)
                Icon(Icons.check_circle, color: colors.primary, size: 30),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            ready
                ? AppStrings.chefBrainReadyBody
                : downloading
                ? AppStrings.chefBrainDownloading
                : AppStrings.chefBrainMissingBody,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          if (failed && widget.chefBrain.error != null) ...<Widget>[
            const SizedBox(height: 8),
            Text(
              AppStrings.downloadGenericBody,
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: colors.error),
            ),
          ],
          if (downloading) ...<Widget>[
            const SizedBox(height: 14),
            ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: LinearProgressIndicator(
                value: widget.chefBrain.progress / 100,
                minHeight: 14,
              ),
            ),
          ],
          const SizedBox(height: 14),
          _InfoRow(label: AppStrings.modelName, value: ModelInfo.name),
          _InfoRow(label: AppStrings.modelSize, value: ModelInfo.sizeLabel),
          _InfoRow(
            label: AppStrings.modelLicense,
            value: ModelInfo.licenseName,
          ),
          const SizedBox(height: 6),
          SelectableText(
            ModelInfo.licenseUrl,
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: colors.primary),
          ),
          const SizedBox(height: 16),
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
              label: const Text(AppStrings.deleteModel),
            )
          else
            FilledButton.icon(
              onPressed: downloading ? _openDownload : _openDownload,
              icon: const Icon(Icons.download),
              label: const Text(AppStrings.downloadAiChef),
            ),
        ],
      ),
    );
  }

  Widget _buildAbout(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: colors.secondaryContainer,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            AppStrings.aboutTitle,
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          Text(
            AppStrings.aboutBody,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 8),
          Text(
            AppStrings.privacyPromise,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 12),
          Text(
            AppStrings.appVersion,
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: colors.onSecondaryContainer,
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          SizedBox(
            width: 92,
            child: Text(label, style: Theme.of(context).textTheme.labelLarge),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(value, style: Theme.of(context).textTheme.bodyMedium),
          ),
        ],
      ),
    );
  }
}
