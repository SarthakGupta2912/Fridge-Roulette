import 'dart:async';
import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:ultralytics_yolo/ultralytics_yolo.dart';

import '../data/ingredients.dart';

/// How the food finder is doing right now.
enum DetectorStatus { loading, ready, failed }

/// One object found in the photo.
class FoodDetection {
  const FoodDetection({required this.food, required this.confidence, this.box});

  final Ingredient food;
  final double confidence;

  /// A box from 0.0 to 1.0, so we can draw it on any size photo.
  final Rect? box;
}

/// Everything the food finder saw in one photo.
class DetectionResult {
  const DetectionResult(this.detections);

  final List<FoodDetection> detections;
}

/// Loads the bundled YOLO model once, then looks for food in one photo.
/// The model file is inside the app, so this works with no internet.
class DetectorService extends ChangeNotifier {
  static const String modelAsset = 'assets/models/food_detector.tflite';

  DetectorStatus status = DetectorStatus.loading;
  bool _loading = false;
  YOLO? _yolo;

  /// Loads the model. Safe to call again after a failure.
  Future<void> loadModel() async {
    if (_loading || status == DetectorStatus.ready) {
      return;
    }
    _loading = true;
    status = DetectorStatus.loading;
    notifyListeners();

    YOLO? newYolo;
    try {
      newYolo = YOLO(modelPath: modelAsset, task: YOLOTask.detect);
      final bool loaded = await newYolo.loadModel().timeout(
        const Duration(seconds: 25),
      );
      if (loaded) {
        _yolo = newYolo;
        status = DetectorStatus.ready;
      } else {
        status = DetectorStatus.failed;
        newYolo.dispose();
      }
    } on TimeoutException {
      status = DetectorStatus.failed;
      newYolo?.dispose();
    } catch (error) {
      // We log for developers but never show this text to the child.
      debugPrint('Food finder could not start: $error');
      status = DetectorStatus.failed;
      newYolo?.dispose();
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  /// Looks at one photo and returns the food it found.
  /// This throws if the photo cannot be read or the model is not ready.
  Future<DetectionResult> detectFoods(Uint8List imageBytes) async {
    final YOLO? yolo = _yolo;
    if (yolo == null || status != DetectorStatus.ready) {
      throw StateError('Food finder is not ready');
    }

    final Map<String, dynamic> raw = await yolo
        .predict(imageBytes, confidenceThreshold: 0.30, iouThreshold: 0.50)
        .timeout(const Duration(seconds: 15));

    final YOLODetectionResults results = YOLODetectionResults.fromMap(raw);
    final List<FoodDetection> foods = [];
    final Set<String> alreadyFound = {};

    for (final YOLOResult item in results.detections) {
      final Ingredient? food = findFoodFromCocoClass(item.className);
      if (food == null) {
        continue;
      }
      final Rect box = item.normalizedBox;
      Rect? safeBox;
      if (box.width > 0 && box.height > 0) {
        safeBox = Rect.fromLTRB(
          box.left.clamp(0.0, 1.0),
          box.top.clamp(0.0, 1.0),
          box.right.clamp(0.0, 1.0),
          box.bottom.clamp(0.0, 1.0),
        );
      }
      if (alreadyFound.contains(food.id)) {
        // Keep the first box for each food so the photo stays easy to read.
        continue;
      }
      alreadyFound.add(food.id);
      foods.add(
        FoodDetection(food: food, confidence: item.confidence, box: safeBox),
      );
    }

    return DetectionResult(foods);
  }

  /// Frees the model when the app closes.
  @override
  void dispose() {
    final YOLO? yolo = _yolo;
    _yolo = null;
    if (yolo != null) {
      yolo.dispose();
    }
    super.dispose();
  }
}
