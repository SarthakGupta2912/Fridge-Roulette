import 'dart:async';

import 'package:flutter/material.dart';

import '../data/model_info.dart';
import '../services/chef_brain.dart';
import '../strings.dart';
import '../widgets/big_action_button.dart';
import '../widgets/friendly_dialog.dart';
import '../widgets/layout_helper.dart';

/// The one-time download screen for the small AI recipe writer.
class ModelDownloadScreen extends StatefulWidget {
  const ModelDownloadScreen({
    super.key,
    required this.chefBrain,
    this.canSkip = true,
  });

  final ChefBrain chefBrain;

  /// When true, the child may leave and use the Quick chef instead.
  final bool canSkip;

  @override
  State<ModelDownloadScreen> createState() => _ModelDownloadScreenState();
}

class _ModelDownloadScreenState extends State<ModelDownloadScreen> {
  ChefBrainProblem? _problem;

  ChefBrainProblem? get _shownProblem {
    if (_problem != null) {
      return _problem;
    }
    final ChefBrainProblem? problem = widget.chefBrain.problem;
    return problem == ChefBrainProblem.cancelled ? null : problem;
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        unawaited(_refreshStatus());
      }
    });
  }

  Future<void> _refreshStatus() async {
    if (widget.chefBrain.isDownloading) {
      return;
    }
    if (widget.chefBrain.status == ChefBrainStatus.checking ||
        widget.chefBrain.status == ChefBrainStatus.failed) {
      await widget.chefBrain.initialize();
    }
    if (mounted) {
      await widget.chefBrain.refresh();
    }
  }

  Future<void> _download() async {
    setState(() => _problem = null);
    try {
      await widget.chefBrain.download();
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _problem = error is ChefBrainException
            ? error.problem
            : classifyDownloadError(error);
      });
    }
  }

  String _problemTitle(ChefBrainProblem problem) {
    return switch (problem) {
      ChefBrainProblem.noInternet => AppStrings.downloadNoInternetTitle,
      ChefBrainProblem.server => AppStrings.downloadServerTitle,
      ChefBrainProblem.storage => AppStrings.downloadStorageErrorTitle,
      ChefBrainProblem.unavailable => AppStrings.downloadUnavailableTitle,
      ChefBrainProblem.startup => AppStrings.downloadStartupTitle,
      ChefBrainProblem.cancelled ||
      ChefBrainProblem.unknown => AppStrings.downloadErrorTitle,
    };
  }

  String _problemBody(ChefBrainProblem problem) {
    return switch (problem) {
      ChefBrainProblem.noInternet => AppStrings.downloadNoInternetBody,
      ChefBrainProblem.server => AppStrings.downloadServerBody,
      ChefBrainProblem.storage => AppStrings.downloadStorageErrorBody,
      ChefBrainProblem.unavailable => AppStrings.downloadUnavailableBody,
      ChefBrainProblem.startup => AppStrings.downloadStartupBody,
      ChefBrainProblem.cancelled ||
      ChefBrainProblem.unknown => AppStrings.downloadGenericBody,
    };
  }

  Future<void> _confirmLeave() async {
    final bool? keep = await showFriendlyDialog(
      context,
      emoji: '📥',
      title: AppStrings.leaveDownloadTitle,
      body: AppStrings.leaveDownloadBody,
      primaryLabel: AppStrings.keepDownloading,
      secondaryLabel: AppStrings.cancelAndLeave,
    );
    if (!mounted || keep == null) {
      return;
    }
    if (!keep) {
      widget.chefBrain.cancelDownload();
      Navigator.of(context).pop(false);
    }
  }

  void _leave(bool downloaded) {
    Navigator.of(context).pop(downloaded);
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.chefBrain,
      builder: (BuildContext context, Widget? child) {
        final ChefBrainStatus status = widget.chefBrain.status;
        return PopScope<Object?>(
          canPop: status != ChefBrainStatus.downloading,
          onPopInvokedWithResult: (bool didPop, Object? result) {
            if (!didPop && status == ChefBrainStatus.downloading) {
              unawaited(_confirmLeave());
            }
          },
          child: Scaffold(
            appBar: AppBar(title: const Text(AppStrings.downloadTitle)),
            body: SafeArea(
              child: LayoutBuilder(
                builder: (BuildContext context, BoxConstraints constraints) {
                  final bool wide = isWideScreen(constraints.maxWidth);
                  return SingleChildScrollView(
                    padding: EdgeInsets.fromLTRB(
                      wide ? 28 : 20,
                      8,
                      wide ? 28 : 20,
                      32,
                    ),
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 760),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: <Widget>[
                            _buildHero(context),
                            const SizedBox(height: 18),
                            _buildModelCard(context),
                            const SizedBox(height: 14),
                            if (status == ChefBrainStatus.ready)
                              _buildReady(context)
                            else if (status == ChefBrainStatus.downloading)
                              _buildProgress(context)
                            else if (status == ChefBrainStatus.checking)
                              _buildChecking(context)
                            else
                              _buildStart(context),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildHero(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: <Color>[colors.primaryContainer, colors.tertiaryContainer],
        ),
      ),
      child: Column(
        children: <Widget>[
          const ExcludeSemantics(
            child: Text('🧑‍🍳', style: TextStyle(fontSize: 68)),
          ),
          const SizedBox(height: 8),
          Text(
            AppStrings.downloadHeroTitle,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          Text(
            AppStrings.downloadHeroBody,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyLarge,
          ),
        ],
      ),
    );
  }

  Widget _buildModelCard(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
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
        ],
      ),
    );
  }

  Widget _buildStart(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;
    final ChefBrainProblem? problem = _shownProblem;
    final bool failed =
        problem != null || widget.chefBrain.status == ChefBrainStatus.failed;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        if (failed) ...<Widget>[
          _ErrorCard(
            title: _problemTitle(problem ?? ChefBrainProblem.unknown),
            body: _problemBody(problem ?? ChefBrainProblem.unknown),
          ),
          const SizedBox(height: 14),
        ],
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: colors.secondaryContainer,
            borderRadius: BorderRadius.circular(22),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Icon(
                Icons.sd_storage_outlined,
                color: colors.onSecondaryContainer,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      AppStrings.downloadStorageTitle,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      AppStrings.downloadStorageBody,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Text(
          AppStrings.downloadWifiHint,
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(color: colors.onSurfaceVariant),
        ),
        const SizedBox(height: 16),
        BigActionButton(
          label: failed
              ? AppStrings.downloadTryAgain
              : AppStrings.downloadButton,
          icon: failed ? Icons.refresh : Icons.download,
          onPressed: _download,
        ),
        if (widget.canSkip) ...<Widget>[
          const SizedBox(height: 10),
          OutlinedButton.icon(
            onPressed: () => _leave(false),
            icon: const Icon(Icons.soup_kitchen_outlined),
            label: const Text(AppStrings.useQuickChef),
          ),
        ],
      ],
    );
  }

  Widget _buildProgress(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;
    final int percent = widget.chefBrain.progress;
    final int totalMb = (ModelInfo.sizeBytes / (1024 * 1024)).round();
    final int doneMb = (totalMb * percent / 100).round();
    final bool starting = percent <= 0;
    final String progressText = starting
        ? AppStrings.downloadStarting
        : AppStrings.downloadProgress(percent, doneMb, totalMb);
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: colors.secondaryContainer,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Row(
            children: <Widget>[
              const SizedBox(
                width: 26,
                height: 26,
                child: CircularProgressIndicator(strokeWidth: 3),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  AppStrings.chefBrainDownloading,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          ClipRRect(
            borderRadius: BorderRadius.circular(20),
            // While the download is being prepared we do not have a percentage
            // yet, so keep the bar moving instead of showing an empty bar.
            child: LinearProgressIndicator(
              value: starting ? null : percent / 100,
              minHeight: 16,
            ),
          ),
          const SizedBox(height: 8),
          Semantics(
            liveRegion: true,
            label: progressText,
            child: Text(
              progressText,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Icon(
                Icons.notifications_active_outlined,
                size: 20,
                color: colors.onSecondaryContainer,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  AppStrings.downloadNotificationHint,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: colors.onSecondaryContainer,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          OutlinedButton.icon(
            onPressed: widget.chefBrain.cancelDownload,
            icon: const Icon(Icons.close),
            label: const Text(AppStrings.downloadCancel),
          ),
        ],
      ),
    );
  }

  Widget _buildChecking(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: <Widget>[
          const CircularProgressIndicator(),
          const SizedBox(height: 12),
          Text(
            AppStrings.loadingChefBrain,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyLarge,
          ),
        ],
      ),
    );
  }

  Widget _buildReady(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: colors.primaryContainer,
            borderRadius: BorderRadius.circular(22),
          ),
          child: Column(
            children: <Widget>[
              const ExcludeSemantics(
                child: Text('🎉', style: TextStyle(fontSize: 48)),
              ),
              const SizedBox(height: 8),
              Text(
                AppStrings.downloadReadyTitle,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 6),
              Text(
                AppStrings.downloadReadyBody,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyLarge,
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        BigActionButton(
          label: AppStrings.downloadDone,
          icon: Icons.restaurant_menu,
          onPressed: () => _leave(true),
        ),
      ],
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
      padding: const EdgeInsets.symmetric(vertical: 4),
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

class _ErrorCard extends StatelessWidget {
  const _ErrorCard({required this.title, required this.body});

  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.errorContainer,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const ExcludeSemantics(
            child: Text('😵', style: TextStyle(fontSize: 28)),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(title, style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 4),
                Text(body, style: Theme.of(context).textTheme.bodyMedium),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
