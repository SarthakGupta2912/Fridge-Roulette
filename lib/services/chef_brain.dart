import 'package:flutter/foundation.dart';
import 'package:flutter_edge_ai/flutter_edge_ai.dart';
import 'package:flutter_edge_ai_mediapipe/flutter_edge_ai_mediapipe.dart';

import '../data/model_info.dart';

/// The state of the one-time AI model download.
enum ChefBrainStatus { checking, missing, downloading, ready, failed }

/// Keeps the "Chef brain" download state in one place.
///
/// The model is downloaded once and stored by flutter_edge_ai. After that the
/// recipe writer works without internet.
class ChefBrain extends ChangeNotifier {
  ChefBrain({ChefBrainStatus initialStatus = ChefBrainStatus.checking})
    : _status = initialStatus;

  ChefBrainStatus _status;
  String? _error;
  int _progress = 0;
  CancelToken? _cancelToken;
  Future<void>? _initFuture;

  ChefBrainStatus get status => _status;
  String? get error => _error;
  int get progress => _progress;
  bool get isReady => _status == ChefBrainStatus.ready;
  bool get isDownloading => _status == ChefBrainStatus.downloading;

  /// Starts the plugin once. Safe to call more than once.
  Future<void> initialize() {
    return _initFuture ??= _initializeOnce();
  }

  Future<void> _initializeOnce() async {
    try {
      await FlutterEdgeAi.initialize(
        inferenceEngines: const <InferenceEngineProvider>[MediaPipeEngine()],
      );
      await refresh();
    } catch (error) {
      debugPrint('Could not start the AI chef: $error');
      _status = ChefBrainStatus.failed;
      _error = error.toString();
      notifyListeners();
    }
  }

  /// Checks whether the model is already on the phone.
  Future<void> refresh() async {
    try {
      final bool installed = await FlutterEdgeAi.isModelInstalled(
        ModelInfo.fileName,
      );
      _status = installed ? ChefBrainStatus.ready : ChefBrainStatus.missing;
      _error = null;
    } catch (error) {
      debugPrint('Could not check the chef brain: $error');
      _status = ChefBrainStatus.failed;
      _error = error.toString();
    }
    notifyListeners();
  }

  /// Downloads the model once. Throws a friendly error on failure.
  Future<void> download() async {
    if (_status == ChefBrainStatus.downloading) {
      return;
    }
    _status = ChefBrainStatus.downloading;
    _progress = 0;
    _error = null;
    notifyListeners();

    final CancelToken token = CancelToken();
    _cancelToken = token;
    try {
      await FlutterEdgeAi.installModel(
            modelType: ModelType.qwen,
            fileType: ModelFileType.task,
          )
          .fromNetwork(ModelInfo.downloadUrl, foreground: false)
          .withProgress((int percent) {
            _progress = percent.clamp(0, 100);
            notifyListeners();
          })
          .withCancelToken(token)
          .install();
      _status = ChefBrainStatus.ready;
      _progress = 100;
    } on DownloadCancelledException {
      _status = ChefBrainStatus.missing;
      _progress = 0;
    } catch (error) {
      _status = ChefBrainStatus.failed;
      _progress = 0;
      _error = error.toString();
      rethrow;
    } finally {
      _cancelToken = null;
      notifyListeners();
    }
  }

  /// Stops a download. The plugin removes its temporary download file.
  void cancelDownload() {
    _cancelToken?.cancel('The child cancelled the download.');
    _status = ChefBrainStatus.missing;
    _progress = 0;
    notifyListeners();
  }

  /// Deletes the downloaded model and frees the space.
  Future<void> deleteModel() async {
    await FlutterEdgeAi.uninstallModel(ModelInfo.fileName);
    _status = ChefBrainStatus.missing;
    _progress = 0;
    notifyListeners();
  }

  @override
  void dispose() {
    _cancelToken?.cancel('The app closed the download.');
    super.dispose();
  }
}
