/// Everything we need to know about the one AI model the app can download.
///
/// The model is not inside the APK. It is downloaded once, then reused offline.
class ModelInfo {
  const ModelInfo._();

  /// The friendly name shown in the app.
  static const String name = 'Qwen2.5 0.5B Instruct';

  /// The real file name. flutter_edge_ai uses it as the installed model id.
  static const String fileName =
      'Qwen2.5-0.5B-Instruct_multi-prefill-seq_q8_ekv1280.task';

  /// A public, non-gated download. No Hugging Face token is needed.
  static const String downloadUrl =
      'https://huggingface.co/litert-community/Qwen2.5-0.5B-Instruct/resolve/main/$fileName';

  /// The exact size reported by Hugging Face, in bytes (about 521 MiB).
  static const int sizeBytes = 546660344;

  /// Apache 2.0 allows commercial use. See the model page for details.
  static const String licenseName = 'Apache License 2.0';
  static const String licenseUrl =
      'https://www.apache.org/licenses/LICENSE-2.0';
  static const String modelPageUrl =
      'https://huggingface.co/litert-community/Qwen2.5-0.5B-Instruct';

  /// A short size label such as "521 MB".
  static String get sizeLabel {
    final int megabytes = (sizeBytes / (1024 * 1024)).round();
    return '$megabytes MB';
  }

  /// The space we suggest keeping free so the download has room to finish.
  static String get recommendedFreeSpaceLabel {
    const int recommendedBytes = 750 * 1024 * 1024;
    final int megabytes = (recommendedBytes / (1024 * 1024)).round();
    return '$megabytes MB';
  }
}
