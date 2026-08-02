import 'dart:async';
import 'dart:typed_data';
import 'package:inkbill_ai/core/utils/result.dart';
import 'package:inkbill_ai/core/errors/failures.dart';
import 'package:inkbill_ai/features/ai/domain/entities/recognition_result.dart';
import 'package:inkbill_ai/services/ai/models/ai_model_interfaces.dart';
import 'package:inkbill_ai/services/ai/models/paddle_ocr_detector.dart';
import 'package:inkbill_ai/services/ai/models/trocr_recognizer.dart';
import 'package:inkbill_ai/services/ai/models/model_downloader.dart';
import 'package:inkbill_ai/services/ai/preprocessing/preprocessing_pipeline.dart';
import 'package:inkbill_ai/services/ai/parsing/bill_parser.dart';
import 'package:inkbill_ai/services/ai/shop_memory/shop_memory.dart';
import 'package:inkbill_ai/services/recognition/recognition_logger.dart';
import 'package:inkbill_ai/features/handwriting/domain/entities/ink_stroke.dart';
import 'package:inkbill_ai/services/recognition/shop_memory.dart' as legacy;

class AiRecognitionPipelineConfig {
  final bool usePaddleOcr;
  final bool useTrocr;
  final bool useMlKitFallback;
  final double detectionConfidenceThreshold;
  final double recognitionConfidenceThreshold;
  final double lineOverlapThreshold;

  const AiRecognitionPipelineConfig({
    this.usePaddleOcr = true,
    this.useTrocr = true,
    this.useMlKitFallback = true,
    this.detectionConfidenceThreshold = 0.5,
    this.recognitionConfidenceThreshold = 0.4,
    this.lineOverlapThreshold = 0.3,
  });
}

class AiRecognitionPipeline {
  final AiRecognitionPipelineConfig config;
  final PreprocessingPipeline _preprocessing = PreprocessingPipeline();
  final PaddleOCRPpOcrV5Detector _textDetector = PaddleOCRPpOcrV5Detector();
  final TrOCRRecognizer _textRecognizer = TrOCRRecognizer();
  final BillParser _billParser = BillParser();
  final ModelDownloader _modelDownloader = ModelDownloader();
  final ShopMemory _shopMemory = ShopMemory();
  bool _initialized = false;

  AiRecognitionPipeline({AiRecognitionPipelineConfig? config})
      : config = config ?? AiRecognitionPipelineConfig();

  bool get isInitialized => _initialized;

  Future<Result<bool>> initialize({
    legacy.ShopMemory? legacyShopMemory,
  }) async {
    RecognitionLogger.stage('AI_PIPELINE', 'Initializing AI recognition pipeline');

    try {
      if (config.usePaddleOcr || config.useTrocr) {
        try {
          await _modelDownloader.downloadAll(
            onProgress: (progress) {
              RecognitionLogger.log(
                  'AI Pipeline: model download ${(progress * 100).toStringAsFixed(0)}%');
            },
            onModelChange: (name) {
              RecognitionLogger.log('AI Pipeline: downloading $name');
            },
          );
        } catch (e) {
          RecognitionLogger.log(
              'AI Pipeline: model download failed, using fallbacks: $e');
        }

        if (config.usePaddleOcr) {
          try {
            final detPath =
                await _modelDownloader.getModelPath('paddleocr/det_model.onnx');
            await _textDetector.load(detPath);
          } catch (_) {}
        }

        if (config.useTrocr) {
          try {
            final trocrPath =
                await _modelDownloader.getModelPath('trocr/model.onnx');
            await _textRecognizer.load(trocrPath);
          } catch (_) {}
        }
      }

      if (legacyShopMemory != null) {
        for (final productName in ['']) {
          final matches = legacyShopMemory.findMatches(productName);
          for (final match in matches) {
            _shopMemory.addProduct(
              productName: match.matchedName,
              price: match.product.price,
            );
          }
        }
      }

      _initialized = true;
      RecognitionLogger.stage(
          'AI_PIPELINE',
          'Pipeline ready: PaddleOCR=${_textDetector.isLoaded}, '
          'TrOCR=${_textRecognizer.isLoaded}');
      return Result.success(true);
    } catch (e, stack) {
      RecognitionLogger.error('AI_PIPELINE init', e, stack);
      return Result.error(
          RecognitionFailure(message: 'AI Pipeline initialization failed: $e'));
    }
  }

  Future<Result<BillStructureResult>> processImage(
    Uint8List imageBytes,
  ) async {
    if (!_initialized) {
      return Result.error(const RecognitionFailure(
          message: 'AI Pipeline not initialized'));
    }

    try {
      RecognitionLogger.stage('AI_PIPELINE', 'Processing image');

      final preprocessResult = _preprocessing.process(imageBytes);

      List<LineSegment> lines = preprocessResult.lines;

      if (lines.isEmpty) {
        lines = [LineSegment(
          croppedImage: preprocessResult.processedImage,
          y: 0,
          height: 0,
        )];
      }

      final recognizedItems = <ParsedBillItem>[];

      for (var i = 0; i < lines.length; i++) {
        final line = lines[i];
        final recognizedWords = <String>[];
        final recognizedNumbers = <String>[];

        if (_textRecognizer.isLoaded) {
          final result = await _textRecognizer.recognize(line.croppedImage);
          result.when(
            success: (text) {
              if (text.text.isNotEmpty) {
                final parts = text.text.trim().split(RegExp(r'\s+'));
                for (final part in parts) {
                  if (double.tryParse(part) != null ||
                      RegExp(r'^\d+\.?\d*$').hasMatch(part)) {
                    recognizedNumbers.add(part);
                  } else {
                    recognizedWords.add(part);
                  }
                }
              }
            },
            error: (_) {},
          );
        }

        final item = ParsedBillItem(
          originalText: '${recognizedWords.join(' ')} ${recognizedNumbers.join(' ')}',
          itemName: recognizedWords.join(' '),
          quantity: recognizedNumbers.isNotEmpty
              ? double.tryParse(recognizedNumbers.first)
              : null,
          rate: recognizedNumbers.length > 1
              ? double.tryParse(recognizedNumbers[1])
              : null,
          confidence: 0.6,
        );
        recognizedItems.add(item);
      }

      final parseResult = _billParser.parse(recognizedItems);

      final lineItems = parseResult.items.map((item) => LineItemData(
        name: item.itemName,
        quantity: item.quantity,
        rate: item.rate,
        amount: item.calculatedAmount ?? item.amount,
        confidence: item.confidence,
        nameConfidence: item.nameConfidence,
        quantityConfidence: item.quantityConfidence,
        rateConfidence: item.rateConfidence,
        isMissingQuantity: item.quantity == null && item.rate != null,
        isMissingRate: item.rate == null && item.quantity != null,
      )).toList();

      RecognitionLogger.stage(
          'AI_PIPELINE',
          'Completed: ${lineItems.length} items');

      return Result.success(BillStructureResult(
        lineItems: lineItems,
        confidence: parseResult.overallConfidence,
        warnings: parseResult.warnings,
      ));
    } catch (e, stack) {
      RecognitionLogger.error('AI_PIPELINE processImage', e, stack);
      return Result.error(
          RecognitionFailure(message: 'AI Pipeline processing failed: $e'));
    }
  }

  Future<Result<BillStructureResult>> processStrokes(
    List<InkStroke> strokes,
  ) async {
    return Result.error(RecognitionFailure(
        message: 'Stroke processing not supported in AI pipeline'));
  }

  ShopMemory get shopMemory => _shopMemory;

  Future<Result<void>> dispose() async {
    await _textDetector.unload();
    await _textRecognizer.unload();
    _initialized = false;
    RecognitionLogger.stage('AI_PIPELINE', 'Disposed');
    return Result.success(null);
  }
}
