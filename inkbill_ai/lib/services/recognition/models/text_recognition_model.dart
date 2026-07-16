import 'dart:io';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:inkbill_ai/core/utils/result.dart';
import 'package:inkbill_ai/core/errors/failures.dart';

class TextRecognitionModel {
  late TextRecognizer _recognizer;
  bool _initialized = false;

  Future<Result<bool>> initialize() async {
    try {
      _recognizer = TextRecognizer(script: TextRecognitionScript.latin);
      _initialized = true;
      return Result.success(true);
    } catch (e) {
      return Result.error(RecognitionFailure(message: 'Text Recognizer init failed: $e'));
    }
  }

  Future<Result<String>> recognizeImage(File imageFile) async {
    if (!_initialized) {
      return Result.error(const RecognitionFailure(message: 'Text Recognizer not initialized'));
    }

    try {
      final inputImage = InputImage.fromFile(imageFile);
      final recognizedText = await _recognizer.processImage(inputImage);
      
      if (recognizedText.text.isEmpty) {
        return Result.error(const RecognitionFailure(message: 'No text recognized in image'));
      }
      
      return Result.success(recognizedText.text);
    } catch (e) {
      return Result.error(RecognitionFailure(message: 'Text recognition failed: $e'));
    }
  }

  Future<Result<void>> dispose() async {
    if (_initialized) {
      await _recognizer.close();
      _initialized = false;
    }
    return Result.success(null);
  }
}
