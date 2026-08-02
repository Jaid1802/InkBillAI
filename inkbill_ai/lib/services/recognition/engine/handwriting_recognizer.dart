import 'dart:typed_data';
import 'package:inkbill_ai/features/ai/domain/entities/recognition_result.dart';

enum RecognizerState {
  uninitialized,
  initializing,
  ready,
  processing,
  error,
  disposed,
}

abstract class HandwritingRecognizer {
  RecognizerState get state;
  Future<void> initialize();
  Future<RecognitionResult> recognize(Uint8List imageBytes);
  Future<void> dispose();
}
