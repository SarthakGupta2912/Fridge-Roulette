import 'dart:async';

import 'package:flutter/material.dart';

import '../data/model_info.dart';
import '../services/chef_brain.dart';
import '../strings.dart';
import '../widgets/app_card.dart';
import '../widgets/app_page.dart';
import '../widgets/app_sizes.dart';
import '../widgets/big_action_button.dart';
import '../widgets/custom_text.dart';
import '../widgets/friendly_dialog.dart';

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
  bool _askedForNotifications = false;
  bool _starting = false;

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
    widget.chefBrain.addListener(_handleBrainChange);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        unawaited(_refreshStatus());
      }
    });
  }

  @override
  void dispose() {
    widget.chefBrain.removeListener(_handleBrainChange);
    super.dispose();
  }

  void _handleBrainChange() {
    if (!mounted) {
      return;
    }
    // The download service can report a failure without completing its
    // Future (for example when Android refuses to start the worker). Clear
    // the button's busy flag so Try again is tappable right away.
    if (_starting && widget.chefBrain.status == ChefBrainStatus.failed) {
      setState(() => _starting = false);
    }
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
    if (_starting) {
      return;
    }
    setState(() {
      _problem = null;
      _starting = true;
    });

    try {
      // Ask for notification permission now, with our own friendly words,
      // instead of letting the downloader surprise the child mid-start.
      bool useForeground = await widget.chefBrain.hasNotificationPermission();
      if (!mounted) {
        return;
      }
      if (!useForeground && !_askedForNotifications) {
        _askedForNotifications = true;
        final bool? allow = await showFriendlyDialog(
          context,
          emoji: '🔔',
          title: AppStrings.downloadNotificationsTitle,
          body: AppStrings.downloadNotificationsBody,
          primaryLabel: AppStrings.downloadNotificationsAllow,
          secondaryLabel: AppStrings.downloadNotificationsSkip,
        );
        if (!mounted) {
          return;
        }
        if (allow == true) {
          useForeground = await widget.chefBrain
              .requestNotificationPermission();
          if (!mounted) {
            return;
          }
        }
      }

      await widget.chefBrain.download(useForeground: useForeground);
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _problem = error is ChefBrainException
            ? error.problem
            : classifyDownloadError(error);
      });
    } finally {
      if (mounted) {
        setState(() => _starting = false);
      }
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
          child: AppPage(
            title: AppStrings.downloadTitle,
            body: AppScrollBody(
              topPadding: AppSpacing.sm,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  _buildHero(context),
                  const SizedBox(height: AppSpacing.lg),
                  _buildModelCard(context),
                  const SizedBox(height: AppSpacing.md),
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
    );
  }

  Widget _buildHero(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;
    return AppCard(
      radius: AppRadius.hero,
      padding: const EdgeInsets.all(AppSpacing.xl),
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: <Color>[colors.primaryContainer, colors.tertiaryContainer],
      ),
      child: Column(
        children: <Widget>[
          const AppEmoji('🧑‍🍳', size: AppSizes.emojiHero),
          const SizedBox(height: AppSpacing.sm),
          CustomText.headlineSmall(
            AppStrings.downloadHeroTitle,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.sm),
          CustomText.bodyLarge(
            AppStrings.downloadHeroBody,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildModelCard(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;
    return AppCard(
      color: colors.surfaceContainerHigh,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
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
          const SizedBox(height: AppSpacing.md),
        ],
        AppCard(
          color: colors.secondaryContainer,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Icon(
                Icons.sd_storage_outlined,
                color: colors.onSecondaryContainer,
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    CustomText.titleMedium(AppStrings.downloadStorageTitle),
                    const SizedBox(height: AppSpacing.xs),
                    CustomText.bodyMedium(AppStrings.downloadStorageBody),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        CustomText.bodyMedium(
          AppStrings.downloadWifiHint,
          color: colors.onSurfaceVariant,
        ),
        const SizedBox(height: AppSpacing.lg),
        BigActionButton(
          label: _starting
              ? AppStrings.downloadPreparing
              : failed
              ? AppStrings.downloadTryAgain
              : AppStrings.downloadButton,
          icon: failed ? Icons.refresh : Icons.download,
          busy: _starting,
          onPressed: _starting ? null : _download,
        ),
        if (widget.canSkip) ...<Widget>[
          const SizedBox(height: AppSpacing.md),
          OutlinedButton.icon(
            onPressed: () => _leave(false),
            icon: const Icon(Icons.soup_kitchen_outlined),
            label: const CustomText(AppStrings.useQuickChef),
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
    return AppCard(
      color: colors.secondaryContainer,
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
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: CustomText.titleMedium(AppStrings.chefBrainDownloading),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          ClipRRect(
            borderRadius: BorderRadius.circular(AppRadius.pill),
            // While the download is being prepared we do not have a percentage
            // yet, so keep the bar moving instead of showing an empty bar.
            child: LinearProgressIndicator(
              value: starting ? null : percent / 100,
              minHeight: 16,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Semantics(
            liveRegion: true,
            label: progressText,
            child: CustomText.bodyMedium(
              progressText,
              textAlign: TextAlign.center,
            ),
          ),
          if (starting) ...<Widget>[
            const SizedBox(height: AppSpacing.xs),
            CustomText.bodySmall(
              AppStrings.downloadStartingHint,
              textAlign: TextAlign.center,
            ),
          ],
          const SizedBox(height: AppSpacing.sm),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Icon(
                widget.chefBrain.usesForeground
                    ? Icons.notifications_active_outlined
                    : Icons.screen_lock_portrait_outlined,
                size: AppSizes.iconSmall,
                color: colors.onSecondaryContainer,
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: CustomText.bodySmall(
                  widget.chefBrain.usesForeground
                      ? AppStrings.downloadNotificationHint
                      : AppStrings.downloadKeepOpenHint,
                  color: colors.onSecondaryContainer,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          OutlinedButton.icon(
            onPressed: widget.chefBrain.cancelDownload,
            icon: const Icon(Icons.close),
            label: const CustomText(AppStrings.downloadCancel),
          ),
        ],
      ),
    );
  }

  Widget _buildChecking(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.xxl),
      child: Column(
        children: <Widget>[
          const CircularProgressIndicator(),
          const SizedBox(height: AppSpacing.md),
          CustomText.bodyLarge(
            AppStrings.loadingChefBrain,
            textAlign: TextAlign.center,
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
        AppCard(
          color: colors.primaryContainer,
          child: Column(
            children: <Widget>[
              const AppEmoji('🎉', size: AppSizes.emojiLarge),
              const SizedBox(height: AppSpacing.sm),
              CustomText.titleLarge(
                AppStrings.downloadReadyTitle,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.sm),
              CustomText.bodyLarge(
                AppStrings.downloadReadyBody,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        BigActionButton(
          label: AppStrings.downloadDone,
          icon: Icons.restaurant_menu,
          onPressed: () => _leave(true),
        ),
      ],
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
    return AppCard(
      color: colors.errorContainer,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const AppEmoji('😵', size: AppSizes.emojiMedium),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                CustomText.titleMedium(title),
                const SizedBox(height: AppSpacing.xs),
                CustomText.bodyMedium(body),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
