import 'dart:async';
import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart' as mlkit;
import 'package:path_provider/path_provider.dart';
import 'package:image/image.dart' as img;
import 'package:inkbill_ai/core/utils/result.dart';
import 'package:inkbill_ai/core/errors/failures.dart';
import 'package:inkbill_ai/features/ai/domain/entities/recognition_result.dart';
import 'package:inkbill_ai/features/handwriting/domain/entities/ink_stroke.dart';
import 'package:inkbill_ai/services/handwriting/handwriting_engine.dart';
import 'package:inkbill_ai/services/handwriting/models/handwriting_line.dart';
import 'package:inkbill_ai/services/recognition/recognition_logger.dart';

class RecognitionLocalDataSource {
  final HandwritingEngine _handwritingEngine;
  mlkit.TextRecognizer? _cachedTextRecognizer;
  bool _textRecognizerInitialized = false;

  static const _knownItems = <String>{
    'tea', 'chai', 'coffee', 'milk', 'bread', 'butter', 'eggs', 'sugar',
    'rice', 'wheat', 'daal', 'pulses', 'oil', 'salt', 'spices', 'turmeric',
    'chilli', 'onion', 'potato', 'tomato', 'ginger', 'garlic', 'soap',
    'shampoo', 'paste', 'brush', 'detergent', 'noodles', 'biscuit',
    'cake', 'cold drink', 'water', 'juice', 'curd', 'paneer', 'ghee',
    'honey', 'jam', 'pickle', 'papad', 'chips', 'namkeen',
  };

  static const Duration _strokeRecognitionTimeout = Duration(seconds: 10);
  static const Duration _imageOcrTimeout = Duration(seconds: 10);

  RecognitionLocalDataSource({HandwritingEngine? handwritingEngine})
      : _handwritingEngine =
            handwritingEngine ?? HandwritingEngine();

  Future<mlkit.TextRecognizer> _getTextRecognizer() {
    if (_cachedTextRecognizer == null || !_textRecognizerInitialized) {
      _cachedTextRecognizer?.close();
      _cachedTextRecognizer =
          mlkit.TextRecognizer(script: mlkit.TextRecognitionScript.latin);
      _textRecognizerInitialized = true;
    }
    return Future.value(_cachedTextRecognizer);
  }

  void _disposeTextRecognizer() {
    if (_cachedTextRecognizer != null) {
      try {
        _cachedTextRecognizer!.close();
      } catch (_) {}
      _cachedTextRecognizer = null;
      _textRecognizerInitialized = false;
    }
  }

  Future<Result<bool>> initializeEngine() async {
    return _handwritingEngine.initialize();
  }

  Future<Result<RecognitionResult>> recognizeStrokes(
      List<InkStroke> strokes) async {
    try {
      final engineResult = await _handwritingEngine
          .recognize(strokes, timeout: _strokeRecognitionTimeout);
      final rawText = _handwritingEngine.toRawText(engineResult.recognition);

      final candidates = <RecognizedText>[];
      for (final line in engineResult.recognition.lines) {
        for (final field in line.fields) {
          if (field.text.isNotEmpty) {
            candidates.add(RecognizedText(
              text: field.text,
              confidence: field.confidence,
            ));
          }
        }
      }

      return Result.success(RecognitionResult(
        candidates: candidates,
        bestText: rawText.isNotEmpty ? rawText : null,
        confidence: engineResult.recognition.overallConfidence,
      ));
    } on TimeoutException {
      return Result.error(const RecognitionFailure(
          message: 'Handwriting recognition timed out'));
    } catch (e) {
      return Result.error(
          RecognitionFailure(message: 'Handwriting recognition failed: $e'));
    }
  }

  Future<Result<LayoutRecognitionResult>> detectLayout(
      List<InkStroke> strokes) async {
    try {
      final engineResult = await _handwritingEngine
          .recognize(strokes, timeout: _strokeRecognitionTimeout);
      final detectedRows = <DetectedRow>[];

      for (final line in engineResult.recognition.lines) {
        final cells = <DetectedCell>[];
        for (final field in line.fields) {
          cells.add(DetectedCell(
            text: RecognitionResult(
              confidence: field.confidence,
              bestText: field.text,
            ),
            fieldType: field.type == FieldType.number ? 'number' : 'word',
            x: field.x,
            y: field.y,
            width: field.width,
            height: field.height,
          ));
        }
        detectedRows.add(DetectedRow(cells: cells));
      }

      return Result.success(LayoutRecognitionResult(
        rows: detectedRows,
        confidence: engineResult.recognition.overallConfidence,
      ));
    } on TimeoutException {
      return Result.error(const RecognitionFailure(
          message: 'Layout detection timed out'));
    } catch (e) {
      return Result.error(
          RecognitionFailure(message: 'Layout detection failed: $e'));
    }
  }

  Future<Result<BillStructureResult>> extractBillStructure(
      List<InkStroke> strokes) async {
    try {
      final engineResult = await _handwritingEngine
          .recognize(strokes, timeout: _strokeRecognitionTimeout);
      final lineItems = <LineItemData>[];

      for (final line in engineResult.recognition.lines) {
        String itemName = '';
        double? quantity;
        double? rate;
        double nameConf = 0.0;
        double qtyConf = 0.0;
        double rateConf = 0.0;

        if (line.fields.isEmpty) continue;

        final words = line.fields
            .where((f) => f.type == FieldType.word && f.text.isNotEmpty)
            .toList();
        final numbers = line.fields
            .where((f) => f.type == FieldType.number && f.text.isNotEmpty)
            .toList();

        if (words.isNotEmpty) {
          itemName = _correctItemName(
              words.map((w) => w.text).join(' '));
          nameConf = words
              .map((w) => w.confidence)
              .reduce((a, b) => a < b ? a : b);
        }

        for (final numField in numbers) {
          final value = double.tryParse(numField.text);
          if (value == null) continue;

          if (_looksLikeQuantity(value, numField.text)) {
            quantity = value;
            qtyConf = numField.confidence;
          } else if (rate == null) {
            rate = value;
            rateConf = numField.confidence;
          }
        }

        if (words.isEmpty && numbers.isNotEmpty) {
          itemName = numbers.first.text;
          nameConf = numbers.first.confidence;
        }

        if (itemName.isNotEmpty || quantity != null || rate != null) {
          final amount = (quantity ?? 0) * (rate ?? 0);
          lineItems.add(LineItemData(
            name: itemName,
            quantity: quantity,
            rate: rate,
            amount: amount > 0 ? amount : null,
            confidence: (nameConf + qtyConf + rateConf) / 3.0,
            nameConfidence: nameConf,
            quantityConfidence: qtyConf,
            rateConfidence: rateConf,
            isMissingQuantity: quantity == null && rate != null,
            isMissingRate: rate == null && quantity != null,
          ));
        }
      }

      return Result.success(BillStructureResult(
        lineItems: lineItems,
        confidence: engineResult.recognition.overallConfidence,
        warnings: engineResult.recognition.warnings,
      ));
    } on TimeoutException {
      return Result.error(const RecognitionFailure(
          message: 'Bill structure extraction timed out'));
    } catch (e) {
      return Result.error(
          RecognitionFailure(message: 'Structure extraction failed: $e'));
    }
  }

  Future<Result<BillStructureResult>> extractBillStructureFromImage(
      Uint8List imageBytes) async {
    File? tempOriginalFile;
    File? tempPreprocessedFile;
    File? tempThresholdFile;
    File? tempFinalInputFile;

    try {
      RecognitionLogger.stage('IMAGE_OCR', '==========================\nOCR PIPELINE START\n==========================');
      RecognitionLogger.log('Received PNG Bytes: ${imageBytes.lengthInBytes}');

      // TASK 2: Verify Image Decoding
      final img.Image? decoded = img.decodePng(imageBytes);
      if (decoded == null) {
        RecognitionLogger.error('IMAGE_OCR', 'IMAGE_DECODE_FAILED: img.decodePng returned null');
        return Result.success(const BillStructureResult(
          diagnosticCategory: OcrDiagnosticCategory.imageDecodeFailed,
          failureCode: 'IMAGE_DECODE_FAILED',
          warnings: ['IMAGE_DECODE_FAILED: Could not decode raw PNG bytes.'],
        ));
      }

      final w = decoded.width;
      final h = decoded.height;
      final numChannels = decoded.numChannels;
      final hasAlpha = decoded.hasAlpha;

      // TASK 9: Calculate Image Metrics (Brightness, Ink Density, Black/White %)
      int nonWhitePixels = 0;
      int blackPixels = 0;
      int whitePixels = 0;
      double totalLuminance = 0;
      final totalPixels = w * h;

      for (var y = 0; y < h; y++) {
        for (var x = 0; x < w; x++) {
          final pixel = decoded.getPixel(x, y);
          final lum = img.getLuminance(pixel).toInt();
          totalLuminance += lum;
          if (lum < 240) nonWhitePixels++;
          if (lum < 50) blackPixels++;
          if (lum > 220) whitePixels++;
        }
      }

      final inkDensity = totalPixels > 0 ? (nonWhitePixels / totalPixels) * 100.0 : 0.0;
      final avgBrightness = totalPixels > 0 ? (totalLuminance / (totalPixels * 255.0)) * 100.0 : 0.0;
      final whitePct = totalPixels > 0 ? (whitePixels / totalPixels) * 100.0 : 0.0;
      final blackPct = totalPixels > 0 ? (blackPixels / totalPixels) * 100.0 : 0.0;

      RecognitionLogger.log(
        'Image Decode Summary:\n'
        '  Width: ${w}px, Height: ${h}px\n'
        '  Channels: $numChannels, Has Alpha: $hasAlpha\n'
        '  Ink Density: ${inkDensity.toStringAsFixed(2)}%\n'
        '  Avg Brightness: ${avgBrightness.toStringAsFixed(2)}%\n'
        '  White: ${whitePct.toStringAsFixed(1)}%, Black: ${blackPct.toStringAsFixed(1)}%'
      );

      // TASK 3: Save Every Pipeline Stage (4 distinct artifacts)
      Directory tempDir;
      try {
        tempDir = await getTemporaryDirectory();
      } catch (_) {
        tempDir = await getApplicationCacheDirectory();
      }

      final timestamp = DateTime.now().millisecondsSinceEpoch;
      tempOriginalFile = File('${tempDir.path}/debug_original_$timestamp.png');
      await tempOriginalFile.writeAsBytes(imageBytes);

      // Stage 2: Preprocessed (Grayscale + contrast)
      final preprocessedImg = img.adjustColor(img.grayscale(img.Image.from(decoded)), contrast: 1.2);
      final preprocessedBytes = Uint8List.fromList(img.encodePng(preprocessedImg));
      tempPreprocessedFile = File('${tempDir.path}/debug_preprocessed_$timestamp.png');
      await tempPreprocessedFile.writeAsBytes(preprocessedBytes);

      // Stage 3: Thresholded Binarization
      final thresholdImg = img.Image.from(preprocessedImg);
      for (var y = 0; y < thresholdImg.height; y++) {
        for (var x = 0; x < thresholdImg.width; x++) {
          final p = thresholdImg.getPixel(x, y);
          final lum = img.getLuminance(p).toInt();
          if (lum < 200) {
            thresholdImg.setPixelRgb(x, y, 0, 0, 0);
          } else {
            thresholdImg.setPixelRgb(x, y, 255, 255, 255);
          }
        }
      }
      final thresholdBytes = Uint8List.fromList(img.encodePng(thresholdImg));
      tempThresholdFile = File('${tempDir.path}/debug_threshold_$timestamp.png');
      await tempThresholdFile.writeAsBytes(thresholdBytes);

      // Stage 4: Final Input File
      tempFinalInputFile = File('${tempDir.path}/debug_final_input_$timestamp.png');
      await tempFinalInputFile.writeAsBytes(imageBytes);

      // TASK 5: Log Actual OCR Engine Execution
      RecognitionLogger.stage(
        'OCR_ENGINE',
        '==========================\n'
        'OCR ENGINE\n'
        'Name: Google ML Kit TextRecognizer\n'
        'Script: Latin Script\n'
        'Package: google_mlkit_text_recognition\n'
        '=========================='
      );

      final textRecognizer = await _getTextRecognizer();

      // TASK 4: Test Path A (Raw Original PNG) vs Path B (Preprocessed PNG)
      final inputImageOriginal = mlkit.InputImage.fromFile(tempOriginalFile);
      final mlkit.RecognizedText resultOriginal = await textRecognizer
          .processImage(inputImageOriginal)
          .timeout(_imageOcrTimeout);

      mlkit.RecognizedText activeResult = resultOriginal;
      String activePathUsed = 'Path A (Original PNG)';

      if (resultOriginal.blocks.isEmpty) {
        RecognitionLogger.log('Path A (Original PNG) returned 0 blocks. Testing Path B (Preprocessed)...');
        final inputImagePreprocessed = mlkit.InputImage.fromFile(tempPreprocessedFile);
        final mlkit.RecognizedText resultPreprocessed = await textRecognizer
            .processImage(inputImagePreprocessed)
            .timeout(_imageOcrTimeout);

        if (resultPreprocessed.blocks.isNotEmpty) {
          activeResult = resultPreprocessed;
          activePathUsed = 'Path B (Preprocessed PNG)';
          RecognitionLogger.log('Path B succeeded with ${resultPreprocessed.blocks.length} blocks!');
        }
      }

      // TASK 6 & 11: Log Raw OCR Structure
      int totalLines = 0;
      int totalWords = 0;
      final rawLinesList = <String>[];
      final lineItems = <LineItemData>[];

      for (final block in activeResult.blocks) {
        for (final line in block.lines) {
          totalLines++;
          totalWords += line.elements.length;
          final lineText = line.text.trim();
          if (lineText.isNotEmpty) {
            rawLinesList.add(lineText);
            // TASK 7: Bypass Bill Parser - direct raw line mapping
            lineItems.add(LineItemData(
              name: lineText,
              confidence: line.confidence?.toDouble() ?? 0.9,
            ));
          }
        }
      }

      final rawTextCombined = rawLinesList.join('\n');

      RecognitionLogger.stage(
        'RAW_OCR_STRUCTURE',
        '==========================\n'
        'RAW OCR STRUCTURE ($activePathUsed)\n'
        'Blocks Found: ${activeResult.blocks.length}\n'
        'Lines Found: $totalLines\n'
        'Words/Elements Found: $totalWords\n'
        'Raw Text Length: ${rawTextCombined.length} chars\n'
        '==========================\n'
        'RAW TEXT:\n$rawTextCombined\n'
        '=========================='
      );

      // TASK 10: Failure Classification
      OcrDiagnosticCategory category = OcrDiagnosticCategory.none;
      String? failureCode;
      final warnings = <String>[];

      if (activeResult.blocks.isEmpty) {
        category = OcrDiagnosticCategory.ocrReturnedZeroBlocks;
        failureCode = 'OCR_RETURNED_ZERO_BLOCKS';
        warnings.add('OCR_RETURNED_ZERO_BLOCKS: ML Kit text recognizer found 0 text blocks in image.');
      } else if (rawTextCombined.isEmpty) {
        category = OcrDiagnosticCategory.ocrReturnedEmptyText;
        failureCode = 'OCR_RETURNED_EMPTY_TEXT';
        warnings.add('OCR_RETURNED_EMPTY_TEXT: ML Kit returned blocks but zero non-whitespace text.');
      }

      if (inkDensity < 0.1) {
        warnings.add('LOW_INK_DENSITY: Handwriting ink density is under 0.1% of canvas.');
      }

      return Result.success(BillStructureResult(
        lineItems: lineItems,
        confidence: 0.9,
        rawText: rawTextCombined,
        diagnosticCategory: category,
        failureCode: failureCode,
        warnings: warnings,
        nonWhitePixelPercentage: inkDensity,
        brightnessPercentage: avgBrightness,
        debugOriginalPath: tempOriginalFile.path,
        debugPreprocessedPath: tempPreprocessedFile.path,
        debugThresholdPath: tempThresholdFile.path,
        debugFinalInputPath: tempFinalInputFile.path,
        detectedLines: rawLinesList,
        recognizerName: 'Google ML Kit ($activePathUsed)',
        blocksCount: activeResult.blocks.length,
        linesCount: totalLines,
        wordsCount: totalWords,
        imageWidth: w,
        imageHeight: h,
      ));
    } on TimeoutException {
      RecognitionLogger.stage('IMAGE_OCR', 'Timeout Triggered');
      _disposeTextRecognizer();
      return Result.success(const BillStructureResult(
        diagnosticCategory: OcrDiagnosticCategory.timeout,
        failureCode: 'MODEL_INFERENCE_TIMEOUT',
        warnings: ['MODEL_INFERENCE_TIMEOUT: Image OCR timed out after 10s.'],
      ));
    } catch (e, stack) {
      RecognitionLogger.error('Image OCR', e, stack);
      _disposeTextRecognizer();
      return Result.success(BillStructureResult(
        diagnosticCategory: OcrDiagnosticCategory.modelInferenceFailed,
        failureCode: 'MODEL_INFERENCE_FAILED',
        warnings: ['MODEL_INFERENCE_FAILED: $e'],
      ));
    }
  }

  Future<Result<double>> calculateConfidence(
      List<InkStroke> strokes) async {
    try {
      final result = await _handwritingEngine
          .recognize(strokes, timeout: _strokeRecognitionTimeout);
      return Result.success(result.recognition.overallConfidence);
    } catch (e) {
      return Result.error(
          RecognitionFailure(message: 'Confidence calculation failed: $e'));
    }
  }

  String _correctItemName(String raw) {
    if (raw.isEmpty) return raw;
    final lower = raw.toLowerCase().trim();

    for (final item in _knownItems) {
      if (lower == item) return _capitalize(item);
    }
    for (final item in _knownItems) {
      if (lower.contains(item) || item.contains(lower)) {
        return _capitalize(item);
      }
    }

    String bestMatch = raw;
    int bestDist = 3;
    for (final item in _knownItems) {
      final dist = _levenshtein(lower, item);
      if (dist < bestDist) {
        bestDist = dist;
        bestMatch = item;
      }
    }

    if (bestDist < 3 && bestMatch != raw) {
      return _capitalize(bestMatch);
    }
    return _capitalize(raw);
  }

  bool _looksLikeQuantity(double value, String raw) {
    final lower = raw.toLowerCase();
    for (final word in ['kg', 'g', 'l', 'ml', 'pcs', 'pack']) {
      if (lower.contains(word)) return true;
    }
    return value <= 100 && value == value.roundToDouble();
  }

  int _levenshtein(String a, String b) {
    if (a.length < b.length) return _levenshtein(b, a);
    if (b.isEmpty) return a.length;
    var prev = List.generate(b.length + 1, (i) => i);
    var curr = List.filled(b.length + 1, 0);
    for (var i = 0; i < a.length; i++) {
      curr[0] = i + 1;
      for (var j = 0; j < b.length; j++) {
        final cost = a[i] == b[j] ? 0 : 1;
        curr[j + 1] = math.min(
          math.min(curr[j] + 1, prev[j + 1] + 1),
          prev[j] + cost,
        );
      }
      final temp = prev;
      prev = curr;
      curr = temp;
    }
    return prev[b.length];
  }

  String _capitalize(String s) {
    if (s.isEmpty) return s;
    return s[0].toUpperCase() + s.substring(1);
  }
}
