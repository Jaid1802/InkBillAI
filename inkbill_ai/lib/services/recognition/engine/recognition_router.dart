import 'dart:typed_data';
import 'package:inkbill_ai/services/recognition/engine/handwriting_recognizer.dart';
import 'package:inkbill_ai/features/ai/domain/entities/recognition_result.dart';
import 'package:inkbill_ai/services/recognition/recognition_logger.dart';

enum DetectedScript {
  latin,
  devanagari,
  mixed,
  numeric,
}

class RecognitionRouter implements HandwritingRecognizer {
  RecognizerState _state = RecognizerState.uninitialized;
  final HandwritingRecognizer _latinRecognizer;
  final HandwritingRecognizer _devanagariRecognizer;

  RecognitionRouter({
    required HandwritingRecognizer latinRecognizer,
    required HandwritingRecognizer devanagariRecognizer,
  })  : _latinRecognizer = latinRecognizer,
        _devanagariRecognizer = devanagariRecognizer;

  @override
  RecognizerState get state => _state;

  @override
  Future<void> initialize() async {
    if (_state == RecognizerState.ready || _state == RecognizerState.initializing) return;
    _state = RecognizerState.initializing;
    RecognitionLogger.stage('ROUTER', 'Initializing RecognitionRouter adapters...');

    try {
      await Future.wait([
        _latinRecognizer.initialize(),
        _devanagariRecognizer.initialize(),
      ]);
      _state = RecognizerState.ready;
      RecognitionLogger.stage('ROUTER', 'RecognitionRouter ready.');
    } catch (e, stack) {
      _state = RecognizerState.error;
      RecognitionLogger.error('RecognitionRouter.initialize', e, stack);
      rethrow;
    }
  }

  DetectedScript detectScript(String text) {
    bool hasDevanagari = false;
    bool hasLatin = false;

    for (int i = 0; i < text.length; i++) {
      final code = text.codeUnitAt(i);
      // Unicode Devanagari range: 0x0900 - 0x097F
      if (code >= 0x0900 && code <= 0x097F) {
        hasDevanagari = true;
      } else if ((code >= 65 && code <= 90) || (code >= 97 && code <= 122)) {
        hasLatin = true;
      }
    }

    if (hasDevanagari && hasLatin) return DetectedScript.mixed;
    if (hasDevanagari) return DetectedScript.devanagari;
    if (hasLatin) return DetectedScript.latin;
    return DetectedScript.numeric;
  }

  @override
  Future<RecognitionResult> recognize(Uint8List imageBytes) async {
    if (_state != RecognizerState.ready) {
      throw StateError('RecognitionRouter is not READY (current state: $_state)');
    }

    _state = RecognizerState.processing;
    try {
      // Primary recognition routed to Devanagari/Multilingual model first
      final primaryResult = await _devanagariRecognizer.recognize(imageBytes);
      final detectedScript = detectScript(primaryResult.text);

      RecognitionResult finalResult = primaryResult;

      // If text is purely Latin/English, route line item to Latin HTR model (TrOCR)
      if (detectedScript == DetectedScript.latin) {
        RecognitionLogger.stage('ROUTER', 'Routing Latin script to TrOCR recognizer');
        final latinResult = await _latinRecognizer.recognize(imageBytes);
        if (latinResult.confidence > primaryResult.confidence) {
          finalResult = latinResult;
        }
      }

      _state = RecognizerState.ready;
      return finalResult;
    } catch (e, stack) {
      _state = RecognizerState.error;
      RecognitionLogger.error('RecognitionRouter.recognize', e, stack);
      rethrow;
    }
  }

  @override
  Future<void> dispose() async {
    _state = RecognizerState.disposed;
    await Future.wait([
      _latinRecognizer.dispose(),
      _devanagariRecognizer.dispose(),
    ]);
  }
}
