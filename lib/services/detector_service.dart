import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:ultralytics_yolo/ultralytics_yolo.dart';

import '../data/ingredients.dart';
import 'label_reader.dart';

/// How the food finder is doing right now.
enum DetectorStatus { loading, ready, failed }

/// Thrown when the child stops a long scan.
class ScanCancelledException implements Exception {
  const ScanCancelledException();
}

/// How far the close-up scan has got.
class ScanProgress {
  const ScanProgress({required this.done, required this.total});

  final int done;
  final int total;

  double get fraction =>
      total <= 0 ? 0 : (done / total).clamp(0.0, 1.0).toDouble();
}

/// One object found in the photo.
class FoodDetection {
  const FoodDetection({required this.food, required this.confidence, this.box});

  final Ingredient food;
  final double confidence;

  /// A box from 0.0 to 1.0, so we can draw it on any size photo.
  final ui.Rect? box;
}

/// Everything the food finder saw in one photo.
class DetectionResult {
  const DetectionResult(this.detections);

  final List<FoodDetection> detections;
}

/// Loads the bundled food models once, then looks closely at one photo.
///
/// Three on-device readers work together:
/// 1. A COCO YOLO model catches common foods like bananas and apples.
/// 2. A FoodSeg103 YOLO model catches milk, eggs, bread, meat, vegetables and
///    many more foods.
/// 3. ML Kit reads package labels such as "Milk" or "Philadelphia".
///
/// The photo is checked once as a whole, then in nine overlapping close-ups.
/// This is slower than one pass, but it finds much smaller items. Everything
/// stays on the phone.
class DetectorService extends ChangeNotifier {
  static const String modelAsset = 'assets/models/food_detector.tflite';
  static const String foodSegModelAsset =
      'assets/models/food_detector_foodseg.tflite';

  DetectorStatus status = DetectorStatus.loading;
  bool _loading = false;
  bool _scanning = false;
  bool _cancelRequested = false;
  bool _disposed = false;

  YOLO? _coco;
  YOLO? _foodSeg;
  LabelReader? _labelReader;

  /// The check screen watches this to show a progress bar.
  final ValueNotifier<ScanProgress> scanProgress = ValueNotifier<ScanProgress>(
    const ScanProgress(done: 0, total: 0),
  );

  /// Loads the models. Safe to call again after a failure.
  Future<void> loadModel() async {
    if (_loading || status == DetectorStatus.ready) {
      return;
    }
    _loading = true;
    status = DetectorStatus.loading;
    _notify();

    try {
      final List<YOLO?> models = await Future.wait<YOLO?>(<Future<YOLO?>>[
        _loadYolo(modelAsset, YOLOTask.detect),
        _loadYolo(foodSegModelAsset, YOLOTask.segment),
      ]);
      _coco = models[0];
      _foodSeg = models[1];
      _labelReader ??= LabelReader();

      // Even if both YOLO models fail, the label reader may still find milk,
      // cheese or bread from the package text.
      status = DetectorStatus.ready;
    } catch (error) {
      // We log for developers but never show this text to the child.
      debugPrint('Food finder could not start: $error');
      status = DetectorStatus.failed;
    } finally {
      _loading = false;
      _notify();
    }
  }

  void _notify() {
    if (!_disposed) {
      notifyListeners();
    }
  }

  void _setProgress(int done, int total) {
    if (!_disposed) {
      scanProgress.value = ScanProgress(done: done, total: total);
      _notify();
    }
  }

  Future<YOLO?> _loadYolo(String asset, YOLOTask task) async {
    YOLO? yolo;
    try {
      // useMultiInstance lets the COCO and FoodSeg models live side by side.
      // CPU keeps memory low and avoids GPU driver surprises on older tablets.
      yolo = YOLO(
        modelPath: asset,
        task: task,
        useGpu: false,
        useMultiInstance: true,
      );
      final bool loaded = await yolo.loadModel().timeout(
        const Duration(seconds: 40),
      );
      if (loaded) {
        return yolo;
      }
      await yolo.dispose();
      return null;
    } catch (error) {
      debugPrint('A food model could not start: $error');
      if (yolo != null) {
        try {
          await yolo.dispose();
        } catch (_) {
          // The engine may already be gone.
        }
      }
      return null;
    }
  }

  /// Looks at one photo and returns the food it found.
  ///
  /// This throws if the photo cannot be read or the model is not ready. It can
  /// take up to two minutes on a slow phone because it checks nine close-ups.
  Future<DetectionResult> detectFoods(Uint8List imageBytes) async {
    if (status != DetectorStatus.ready) {
      throw StateError('Food finder is not ready');
    }
    if (_scanning) {
      throw StateError('A food scan is already running');
    }

    _scanning = true;
    _cancelRequested = false;
    _DecodedPhoto? photo;

    try {
      try {
        photo = await _decodePhoto(imageBytes);
      } catch (error) {
        throw StateError('The photo could not be read: $error');
      }
      final _DecodedPhoto decoded = photo;

      final List<_ScanRegion> regions = _scanRegions();
      // One step for each photo area, and one for reading package labels.
      final int totalSteps = regions.length + 1;
      _setProgress(0, totalSteps);

      final Map<String, FoodDetection> best = <String, FoodDetection>{};
      int done = 0;

      for (final _ScanRegion region in regions) {
        _throwIfCancelled();

        Uint8List? cropBytes;
        if (region.isFull) {
          cropBytes = imageBytes;
        } else {
          try {
            cropBytes = await _cropToPng(decoded.image, region);
          } catch (error) {
            debugPrint('A close-up could not be prepared: $error');
          }
        }

        if (cropBytes != null) {
          if (region.isFull && _coco != null) {
            await _runCoco(cropBytes, region, best);
          }
          if (_foodSeg != null) {
            await _runFoodSeg(cropBytes, region, best);
          }
        }

        done++;
        _setProgress(done, totalSteps);
      }

      _throwIfCancelled();

      if (_labelReader != null) {
        try {
          final List<LabelFood> labels = await _labelReader!
              .readLabels(imageBytes, decoded.originalSize)
              .timeout(const Duration(seconds: 35));
          for (final LabelFood label in labels) {
            _merge(best, label.food, 0.78, label.box);
          }
        } on TimeoutException {
          debugPrint('The label reader took too long.');
        } catch (error) {
          debugPrint('The label reader had a problem: $error');
        }
      }

      done++;
      _setProgress(done, totalSteps);
      _throwIfCancelled();

      // A bottle is a generic drink. If the food segmenter found milk, the
      // child does not need a second "Juice or Drink" chip for the same carton.
      if (best.containsKey('milk')) {
        best.remove('drink');
      }

      final List<FoodDetection> foods = best.values.toList()
        ..sort(
          (FoodDetection a, FoodDetection b) =>
              b.confidence.compareTo(a.confidence),
        );

      // A very full fridge can produce lots of boxes. Keep the strongest ones
      // so the photo and the food list stay easy to read.
      return DetectionResult(foods.take(24).toList(growable: false));
    } finally {
      photo?.image.dispose();
      _scanning = false;
    }
  }

  /// Stops a scan between close-ups. The screen calls this when the child
  /// leaves or taps Stop.
  void cancelScan() {
    _cancelRequested = true;
  }

  void _throwIfCancelled() {
    if (_cancelRequested || _disposed) {
      throw const ScanCancelledException();
    }
  }

  Future<void> _runCoco(
    Uint8List bytes,
    _ScanRegion region,
    Map<String, FoodDetection> best,
  ) async {
    final YOLO? yolo = _coco;
    if (yolo == null) {
      return;
    }
    try {
      final Map<String, dynamic> raw = await yolo
          .predict(bytes, confidenceThreshold: 0.35, iouThreshold: 0.50)
          .timeout(const Duration(seconds: 25));
      final YOLODetectionResults results = YOLODetectionResults.fromMap(raw);
      for (final YOLOResult item in results.detections) {
        final Ingredient? food = findFoodFromCocoClass(item.className);
        if (food == null) {
          continue;
        }
        _merge(
          best,
          food,
          item.confidence,
          _mapBox(item.normalizedBox, region),
        );
      }
    } on TimeoutException {
      debugPrint('The COCO model took too long on one photo area.');
    } catch (error) {
      debugPrint('The COCO model had a problem: $error');
    }
  }

  Future<void> _runFoodSeg(
    Uint8List bytes,
    _ScanRegion region,
    Map<String, FoodDetection> best,
  ) async {
    final YOLO? yolo = _foodSeg;
    if (yolo == null) {
      return;
    }
    try {
      // Ask for low-confidence boxes, then use a per-food threshold below.
      // This finds milk and cheese that the model is less sure about.
      final Map<String, dynamic> raw = await yolo
          .predict(bytes, confidenceThreshold: 0.08, iouThreshold: 0.50)
          .timeout(const Duration(seconds: 35));
      final YOLODetectionResults results = YOLODetectionResults.fromMap(raw);
      for (final YOLOResult item in results.detections) {
        final String className = item.className.toLowerCase().trim();
        if (item.confidence < _foodSegThreshold(className)) {
          continue;
        }
        final Ingredient? food = findFoodFromFoodSegClass(className);
        if (food == null) {
          continue;
        }
        final ui.Rect? box = _mapBox(item.normalizedBox, region);
        if (box == null || !_isSaneBox(box)) {
          continue;
        }
        _merge(best, food, item.confidence, box);
      }
    } on TimeoutException {
      debugPrint('The food segmenter took too long on one photo area.');
    } catch (error) {
      debugPrint('The food segmenter had a problem: $error');
    }
  }

  /// Packaged foods are often small and partly hidden, so we accept a lower
  /// confidence for them. Thin shelf edges are filtered out by [_isSaneBox].
  double _foodSegThreshold(String className) {
    switch (className) {
      case 'milk':
      case 'cheese butter':
      case 'egg':
      case 'bread':
        return 0.08;
      default:
        return 0.22;
    }
  }

  bool _isSaneBox(ui.Rect box) {
    final double width = box.width;
    final double height = box.height;
    if (width <= 0.008 || height <= 0.008) {
      return false;
    }
    if (width * height < 0.0015) {
      return false;
    }
    final double ratio = math.max(width / height, height / width);
    return ratio <= 8;
  }

  ui.Rect? _mapBox(ui.Rect? box, _ScanRegion region) {
    if (box == null || box.width <= 0 || box.height <= 0) {
      return null;
    }
    final double regionWidth = region.right - region.left;
    final double regionHeight = region.bottom - region.top;
    final double left = region.left + box.left * regionWidth;
    final double top = region.top + box.top * regionHeight;
    final double right = region.left + box.right * regionWidth;
    final double bottom = region.top + box.bottom * regionHeight;
    if (right <= left || bottom <= top) {
      return null;
    }
    return ui.Rect.fromLTRB(
      left.clamp(0.0, 1.0),
      top.clamp(0.0, 1.0),
      right.clamp(0.0, 1.0),
      bottom.clamp(0.0, 1.0),
    );
  }

  /// Keeps the best box for each food. A box is more useful than no box, so a
  /// label-reader hit is replaced when a model can point at the food.
  void _merge(
    Map<String, FoodDetection> best,
    Ingredient food,
    double confidence,
    ui.Rect? box,
  ) {
    if (confidence <= 0) {
      return;
    }
    final FoodDetection? existing = best[food.id];
    if (existing == null) {
      best[food.id] = FoodDetection(
        food: food,
        confidence: confidence,
        box: box,
      );
      return;
    }

    final bool existingHasBox = existing.box != null;
    final bool newHasBox = box != null;
    final bool shouldReplace =
        newHasBox && !existingHasBox ||
        (newHasBox == existingHasBox && confidence > existing.confidence);

    if (shouldReplace) {
      best[food.id] = FoodDetection(
        food: food,
        confidence: confidence,
        box: box,
      );
    }
  }

  List<_ScanRegion> _scanRegions() {
    const double tile = 0.60;
    const double step = 0.20;
    final List<_ScanRegion> regions = <_ScanRegion>[const _ScanRegion.full()];

    for (int row = 0; row < 3; row++) {
      for (int column = 0; column < 3; column++) {
        final double left = column * step;
        final double top = row * step;
        final double right = (left + tile).clamp(0.0, 1.0);
        final double bottom = (top + tile).clamp(0.0, 1.0);
        if (right - left < 0.1 || bottom - top < 0.1) {
          continue;
        }
        regions.add(_ScanRegion(left, top, right, bottom));
      }
    }
    return regions;
  }

  Future<_DecodedPhoto> _decodePhoto(Uint8List bytes) async {
    final ui.Codec codec = await ui.instantiateImageCodec(bytes);
    final ui.FrameInfo frame = await codec.getNextFrame();
    codec.dispose();

    final ui.Image original = frame.image;
    final ui.Size originalSize = ui.Size(
      original.width.toDouble(),
      original.height.toDouble(),
    );

    // Very large phone photos use a lot of memory. 2600 pixels on the long
    // side is still much more detail than the models need.
    const int maxSide = 2600;
    if (original.width <= maxSide && original.height <= maxSide) {
      return _DecodedPhoto(original, originalSize);
    }

    final double scale = maxSide / math.max(original.width, original.height);
    final int width = (original.width * scale).round().clamp(1, maxSide);
    final int height = (original.height * scale).round().clamp(1, maxSide);
    final ui.Image resized = await _resizeImage(original, width, height);
    original.dispose();
    return _DecodedPhoto(resized, originalSize);
  }

  Future<ui.Image> _resizeImage(ui.Image image, int width, int height) async {
    final ui.PictureRecorder recorder = ui.PictureRecorder();
    final ui.Canvas canvas = ui.Canvas(recorder);
    canvas.drawImageRect(
      image,
      ui.Rect.fromLTWH(0, 0, image.width.toDouble(), image.height.toDouble()),
      ui.Rect.fromLTWH(0, 0, width.toDouble(), height.toDouble()),
      ui.Paint()..filterQuality = ui.FilterQuality.medium,
    );
    final ui.Picture picture = recorder.endRecording();
    final ui.Image resized = await picture.toImage(width, height);
    picture.dispose();
    return resized;
  }

  Future<Uint8List> _cropToPng(ui.Image image, _ScanRegion region) async {
    final double left = region.left * image.width;
    final double top = region.top * image.height;
    final double right = region.right * image.width;
    final double bottom = region.bottom * image.height;
    final int width = (right - left).round().clamp(1, image.width);
    final int height = (bottom - top).round().clamp(1, image.height);

    final ui.PictureRecorder recorder = ui.PictureRecorder();
    final ui.Canvas canvas = ui.Canvas(recorder);
    canvas.drawImageRect(
      image,
      ui.Rect.fromLTRB(left, top, right, bottom),
      ui.Rect.fromLTWH(0, 0, width.toDouble(), height.toDouble()),
      ui.Paint()..filterQuality = ui.FilterQuality.medium,
    );
    final ui.Picture picture = recorder.endRecording();
    final ui.Image crop = await picture.toImage(width, height);
    picture.dispose();

    try {
      final ByteData? data = await crop.toByteData(
        format: ui.ImageByteFormat.png,
      );
      if (data == null) {
        throw StateError('The close-up could not be encoded');
      }
      return data.buffer.asUint8List();
    } finally {
      crop.dispose();
    }
  }

  /// Frees the models when the app closes.
  @override
  void dispose() {
    _disposed = true;
    _cancelRequested = true;
    final YOLO? coco = _coco;
    _coco = null;
    if (coco != null) {
      unawaited(coco.dispose());
    }
    final YOLO? foodSeg = _foodSeg;
    _foodSeg = null;
    if (foodSeg != null) {
      unawaited(foodSeg.dispose());
    }
    _labelReader?.dispose();
    _labelReader = null;
    scanProgress.dispose();
    super.dispose();
  }
}

class _DecodedPhoto {
  const _DecodedPhoto(this.image, this.originalSize);

  final ui.Image image;
  final ui.Size originalSize;
}

class _ScanRegion {
  const _ScanRegion(this.left, this.top, this.right, this.bottom)
    : isFull = false;

  const _ScanRegion.full()
    : left = 0,
      top = 0,
      right = 1,
      bottom = 1,
      isFull = true;

  final double left;
  final double top;
  final double right;
  final double bottom;
  final bool isFull;
}
