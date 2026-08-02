class PipelineConfig {
  static const String version = '2.0.0';

  final bool usePaddleOcr;
  final bool useTrocr;
  final bool useMlKitFallback;
  final double detectionConfidenceThreshold;
  final double recognitionConfidenceThreshold;
  final double shopMemoryMatchThreshold;
  final int maxImageDimension;
  final bool enablePreprocessingCrop;
  final bool enablePreprocessingDenoise;
  final bool enablePreprocessingDeskew;
  final bool enableLineSegmentation;
  final int recognitionTimeoutSeconds;
  final bool logDetailedTiming;

  const PipelineConfig({
    this.usePaddleOcr = true,
    this.useTrocr = true,
    this.useMlKitFallback = true,
    this.detectionConfidenceThreshold = 0.5,
    this.recognitionConfidenceThreshold = 0.4,
    this.shopMemoryMatchThreshold = 0.5,
    this.maxImageDimension = 2048,
    this.enablePreprocessingCrop = true,
    this.enablePreprocessingDenoise = true,
    this.enablePreprocessingDeskew = true,
    this.enableLineSegmentation = true,
    this.recognitionTimeoutSeconds = 10,
    this.logDetailedTiming = false,
  });

  PipelineConfig copyWith({
    bool? usePaddleOcr,
    bool? useTrocr,
    bool? useMlKitFallback,
    double? detectionConfidenceThreshold,
    double? recognitionConfidenceThreshold,
    double? shopMemoryMatchThreshold,
    int? maxImageDimension,
    bool? enablePreprocessingCrop,
    bool? enablePreprocessingDenoise,
    bool? enablePreprocessingDeskew,
    bool? enableLineSegmentation,
    int? recognitionTimeoutSeconds,
    bool? logDetailedTiming,
  }) {
    return PipelineConfig(
      usePaddleOcr: usePaddleOcr ?? this.usePaddleOcr,
      useTrocr: useTrocr ?? this.useTrocr,
      useMlKitFallback: useMlKitFallback ?? this.useMlKitFallback,
      detectionConfidenceThreshold:
          detectionConfidenceThreshold ?? this.detectionConfidenceThreshold,
      recognitionConfidenceThreshold:
          recognitionConfidenceThreshold ?? this.recognitionConfidenceThreshold,
      shopMemoryMatchThreshold:
          shopMemoryMatchThreshold ?? this.shopMemoryMatchThreshold,
      maxImageDimension: maxImageDimension ?? this.maxImageDimension,
      enablePreprocessingCrop:
          enablePreprocessingCrop ?? this.enablePreprocessingCrop,
      enablePreprocessingDenoise:
          enablePreprocessingDenoise ?? this.enablePreprocessingDenoise,
      enablePreprocessingDeskew:
          enablePreprocessingDeskew ?? this.enablePreprocessingDeskew,
      enableLineSegmentation:
          enableLineSegmentation ?? this.enableLineSegmentation,
      recognitionTimeoutSeconds:
          recognitionTimeoutSeconds ?? this.recognitionTimeoutSeconds,
      logDetailedTiming: logDetailedTiming ?? this.logDetailedTiming,
    );
  }

  static const PipelineConfig defaultConfig = PipelineConfig();

  static const PipelineConfig fastConfig = PipelineConfig(
    maxImageDimension: 1024,
    enablePreprocessingDeskew: false,
    recognitionTimeoutSeconds: 5,
  );

  static const PipelineConfig accurateConfig = PipelineConfig(
    maxImageDimension: 4096,
    recognitionTimeoutSeconds: 15,
  );
}
