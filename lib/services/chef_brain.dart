import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_edge_ai/flutter_edge_ai.dart';
import 'package:flutter_edge_ai_mediapipe/flutter_edge_ai_mediapipe.dart';

import '../data/model_info.dart';

/// The state of the one-time AI model download.
enum ChefBrainStatus { checking, missing, downloading, ready, failed }

/// A friendly category for anything that can stop the chef brain download.
enum ChefBrainProblem {
  noInternet,
  server,
  storage,
  unavailable,
  startup,
  cancelled,
  unknown,
}

/// A download failure that the screen can explain without showing technical
/// words to the child.
class ChefBrainException implements Exception {
  const ChefBrainException(this.problem, this.message, [this.cause]);

  final ChefBrainProblem problem;
  final String message;
  final Object? cause;

  @override
  String toString() => 'ChefBrainException($problem): $message';
}

/// Turns any download error into one of the friendly problem groups.
///
/// It is public so the download screen and tests can use the same rules.
ChefBrainProblem classifyDownloadError(Object error) {
  if (error is ChefBrainException) {
    return error.problem;
  }
  if (error is DownloadException) {
    return switch (error.error) {
      NetworkError() => ChefBrainProblem.noInternet,
      ServerError() || RateLimitedError() => ChefBrainProblem.server,
      UnauthorizedError() ||
      ForbiddenError() ||
      NotFoundError() => ChefBrainProblem.unavailable,
      CanceledError() => ChefBrainProblem.cancelled,
      UnknownError(:final message) => _classifyText(message),
    };
  }
  if (error is SocketException ||
      error is TimeoutException ||
      error is HttpException ||
      error is HandshakeException) {
    return ChefBrainProblem.noInternet;
  }
  if (error is FileSystemException) {
    return _classifyText('${error.message} ${error.osError?.message ?? ''}');
  }
  if (error is PlatformException || error is MissingPluginException) {
    return ChefBrainProblem.startup;
  }
  return _classifyText(error.toString());
}

ChefBrainProblem _classifyText(String raw) {
  final String text = raw.toLowerCase();
  if (text.contains('no space') ||
      text.contains('enospc') ||
      text.contains('not enough space') ||
      text.contains('storage full') ||
      text.contains('disk full') ||
      text.contains('out of memory')) {
    return ChefBrainProblem.storage;
  }
  if (text.contains('socket') ||
      text.contains('network') ||
      text.contains('internet') ||
      text.contains('connection') ||
      text.contains('timeout') ||
      text.contains('timed out') ||
      text.contains('host') ||
      text.contains('dns') ||
      text.contains('handshake') ||
      text.contains('clientexception')) {
    return ChefBrainProblem.noInternet;
  }
  if (text.contains('server error') ||
      text.contains('http 5') ||
      text.contains('rate limit') ||
      text.contains('http 429') ||
      text.contains('service unavailable') ||
      text.contains('bad gateway') ||
      text.contains('gateway timeout')) {
    return ChefBrainProblem.server;
  }
  if (text.contains('http 401') ||
      text.contains('http 403') ||
      text.contains('http 404') ||
      text.contains('not found') ||
      text.contains('forbidden') ||
      text.contains('unauthorized')) {
    return ChefBrainProblem.unavailable;
  }
  if (text.contains('cancel')) {
    return ChefBrainProblem.cancelled;
  }
  return ChefBrainProblem.unknown;
}

/// Keeps the "Chef brain" download state in one place.
///
/// The model is downloaded once and stored by flutter_edge_ai. After that the
/// recipe writer works without internet.
class ChefBrain extends ChangeNotifier {
  ChefBrain({ChefBrainStatus initialStatus = ChefBrainStatus.checking})
    : _status = initialStatus;

  ChefBrainStatus _status;
  String? _error;
  ChefBrainProblem? _problem;
  int _progress = 0;
  CancelToken? _cancelToken;
  Future<void>? _initFuture;
  bool _initialized = false;

  ChefBrainStatus get status => _status;
  String? get error => _error;
  ChefBrainProblem? get problem => _problem;
  int get progress => _progress;
  bool get isReady => _status == ChefBrainStatus.ready;
  bool get isDownloading => _status == ChefBrainStatus.downloading;

  /// Starts the plugin once. Safe to call more than once, and safe to retry
  /// after a failure.
  Future<void> initialize() {
    return _initFuture ??= _initializeOnce();
  }

  Future<void> _initializeOnce() async {
    try {
      await FlutterEdgeAi.initialize(
        inferenceEngines: const <InferenceEngineProvider>[MediaPipeEngine()],
        // Show a friendly error after a few tries instead of keeping a child
        // waiting through the plugin's default ten long back-offs.
        maxDownloadRetries: 3,
      );
      _initialized = true;
      await refresh();
    } catch (error) {
      debugPrint('Could not start the AI chef: $error');
      // Let the next attempt try again instead of replaying this failure.
      _initFuture = null;
      _initialized = false;
      _status = ChefBrainStatus.failed;
      _error = error.toString();
      _problem = classifyDownloadError(error);
      notifyListeners();
    }
  }

  /// Checks whether the model is already on the phone.
  Future<void> refresh() async {
    if (_status == ChefBrainStatus.downloading) {
      return;
    }
    try {
      final bool installed = await FlutterEdgeAi.isModelInstalled(
        ModelInfo.fileName,
      );
      _status = installed ? ChefBrainStatus.ready : ChefBrainStatus.missing;
      _error = null;
      _problem = null;
    } catch (error) {
      debugPrint('Could not check the chef brain: $error');
      _status = ChefBrainStatus.failed;
      _error = error.toString();
      _problem = classifyDownloadError(error);
    }
    notifyListeners();
  }

  /// Downloads the model once. Throws [ChefBrainException] on failure.
  Future<void> download() async {
    if (_status == ChefBrainStatus.downloading) {
      return;
    }

    if (!_initialized) {
      await initialize();
      if (!_initialized) {
        throw ChefBrainException(
          _problem ?? ChefBrainProblem.unavailable,
          _error ?? 'The chef brain did not start.',
        );
      }
    }

    // Fail fast when the phone is offline instead of waiting for the
    // downloader's retries. DNS is a cheap check that needs no new package.
    await _ensureInternet();

    _status = ChefBrainStatus.downloading;
    _progress = 0;
    _error = null;
    _problem = null;
    notifyListeners();

    final CancelToken token = CancelToken();
    _cancelToken = token;
    try {
      await FlutterEdgeAi.installModel(
            modelType: ModelType.qwen,
            fileType: ModelFileType.task,
          )
          // A foreground service keeps the 500 MB download alive and shows a
          // progress notification. The plugin also asks for notification
          // permission on Android 13 and newer.
          .fromNetwork(ModelInfo.downloadUrl, foreground: true)
          .withProgress((int percent) {
            _progress = percent.clamp(0, 100);
            notifyListeners();
          })
          .withCancelToken(token)
          .install();
      _status = ChefBrainStatus.ready;
      _progress = 100;
      _error = null;
      _problem = null;
    } on DownloadCancelledException {
      _status = ChefBrainStatus.missing;
      _progress = 0;
      _error = null;
      _problem = ChefBrainProblem.cancelled;
    } catch (error) {
      _status = ChefBrainStatus.failed;
      _progress = 0;
      _error = error.toString();
      _problem = classifyDownloadError(error);
      throw ChefBrainException(_problem!, _error!, error);
    } finally {
      _cancelToken = null;
      notifyListeners();
    }
  }

  Future<void> _ensureInternet() async {
    try {
      final List<InternetAddress> addresses = await InternetAddress.lookup(
        'huggingface.co',
      ).timeout(const Duration(seconds: 5));
      if (addresses.isEmpty) {
        throw SocketException('No internet connection.');
      }
    } catch (error) {
      final ChefBrainProblem problem = classifyDownloadError(error);
      final ChefBrainProblem friendly = problem == ChefBrainProblem.unknown
          ? ChefBrainProblem.noInternet
          : problem;
      _status = ChefBrainStatus.failed;
      _progress = 0;
      _error = 'No internet connection.';
      _problem = friendly;
      notifyListeners();
      throw ChefBrainException(friendly, _error!, error);
    }
  }

  /// Stops a download. The plugin removes its temporary download file.
  void cancelDownload() {
    _cancelToken?.cancel('The child cancelled the download.');
    _status = ChefBrainStatus.missing;
    _progress = 0;
    _error = null;
    _problem = ChefBrainProblem.cancelled;
    notifyListeners();
  }

  /// Deletes the downloaded model and frees the space.
  Future<void> deleteModel() async {
    await FlutterEdgeAi.uninstallModel(ModelInfo.fileName);
    _status = ChefBrainStatus.missing;
    _progress = 0;
    _error = null;
    _problem = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _cancelToken?.cancel('The app closed the download.');
    super.dispose();
  }
}
