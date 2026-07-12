class AppConstants {
  AppConstants._();

  static const String appName = 'InkBill AI';
  static const String version = '1.0.0';

  // Ink Engine
  static const double defaultStrokeWidth = 3.0;
  static const double minStrokeWidth = 1.0;
  static const double maxStrokeWidth = 12.0;
  static const double maxPressure = 1.0;
  static const int maxPointsPerStroke = 10000;
  static const Duration inkSampleRate = Duration(milliseconds: 8);

  // Canvas
  static const double canvasWidth = 800.0;
  static const double canvasHeight = 1000.0;
  static const double infiniteCanvasExtent = 100000.0;

  // AI Recognition
  static const double minConfidenceThreshold = 0.5;
  static const int recognitionDebounceMs = 300;
  static const int maxRecognitionRetries = 3;

  // Billing
  static const int maxLineItems = 100;
  static const double defaultTaxRate = 0.18;
  static const String currencySymbol = '₹';
  static const int decimalPlaces = 2;

  // Timeline
  static const double timelinePlaybackSpeed = 1.0;
  static const Duration timelineFrameStep = Duration(milliseconds: 16);

  // Database
  static const String databaseName = 'inkbill.db';
  static const int databaseVersion = 1;
}
