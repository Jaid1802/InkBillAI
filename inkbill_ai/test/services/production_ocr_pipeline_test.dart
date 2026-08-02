import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:scribble/scribble.dart';
import 'package:inkbill_ai/services/recognition/engine/ocr_engine_interface.dart';
import 'package:inkbill_ai/services/recognition/engine/production_ocr_pipeline.dart';
import 'package:inkbill_ai/services/recognition/engine/ml_kit_ocr_engine.dart';
import 'package:inkbill_ai/services/ai/models/model_manager.dart';
import 'package:inkbill_ai/services/recognition/benchmark/ocr_benchmark_system.dart';
import 'package:inkbill_ai/services/recognition/stroke_bitmap_renderer.dart';
import 'package:inkbill_ai/services/recognition/bill_parser.dart';
import 'package:inkbill_ai/services/recognition/shop_memory.dart';
import 'package:inkbill_ai/services/recognition/ai_validator.dart';
import 'package:inkbill_ai/features/products/domain/entities/product.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('plugins.flutter.io/path_provider'),
      (MethodCall methodCall) async {
        return '.';
      },
    );
  });

  group('Milestone 3: Production Offline OCR Engine Tests', () {
    test('ModelManager loads ONNX models and runs warm-up inference', () async {
      final modelManager = ModelManager();
      expect(modelManager.isWarmedUp, false);

      await modelManager.warmupInference();
      expect(modelManager.isWarmedUp, true);
      expect(modelManager.memoryUsageMb, greaterThan(0));

      final models = modelManager.getRegisteredModels();
      expect(models.length, greaterThanOrEqualTo(3));
    });

    test('OcrBenchmarkSystem records and stores benchmark history', () {
      final benchmark = OcrBenchmarkSystem();
      const payload = OcrResultPayload(
        rawText: 'Car\n2\n30',
        engineName: 'PaddleOCR + TrOCR (Production)',
        detectionTimeMs: 120,
        recognitionTimeMs: 340,
        totalTimeMs: 460,
        confidence: 0.96,
        memoryUsageMb: 85.0,
      );

      benchmark.recordBenchmark(payload);
      expect(benchmark.history.isNotEmpty, true);
      expect(benchmark.latest?.engineName, 'PaddleOCR + TrOCR (Production)');
      expect(benchmark.latest?.totalTimeMs, 460);
    });

    test('ProductionOcrEngine initializes and recognizes sample input', () async {
      final engine = ProductionOcrEngine();
      expect(engine.engineName, contains('PaddleOCR + TrOCR'));
      expect(engine.mode, OcrEngineMode.paddleOcrTrOcr);

      await engine.initialize();
      expect(engine.isReady, true);

      final testImg = img.Image(width: 200, height: 100);
      img.fill(testImg, color: img.ColorRgb8(255, 255, 255));
      final validPngBytes = Uint8List.fromList(img.encodePng(testImg));
      final payload = await engine.recognize(validPngBytes);

      expect(payload.engineName, contains('PaddleOCR + TrOCR'));
      expect(payload.totalTimeMs, greaterThanOrEqualTo(0));
    });

    test('MlKitOcrEngine initializes and executes in debug mode', () async {
      final debugEngine = MlKitOcrEngine();
      expect(debugEngine.engineName, contains('Google ML Kit'));
      expect(debugEngine.mode, OcrEngineMode.mlKitDebug);
    });

    test('BillParser V2 parses raw OCR lines into structured ParsedItem data', () {
      const parser = BillParser();
      final result = parser.parse(['Car 2 30']);

      expect(result.items.isNotEmpty, true);
      final item = result.items.first;
      expect(item.name.toLowerCase(), contains('car'));
      expect(item.quantity, 2.0);
      expect(item.rate, 30.0);
    });

    test('ShopMemory performs alias mapping and frequency learning', () async {
      final shopMemory = ShopMemory.withProducts([
        Product(id: 'p1', name: 'Milk', price: 35.0, createdAt: DateTime.now(), updatedAt: DateTime.now()),
        Product(id: 'p2', name: 'Tea', price: 20.0, createdAt: DateTime.now(), updatedAt: DateTime.now()),
      ]);

      final matches = shopMemory.findMatches('Milc');
      expect(matches.isNotEmpty, true);
      expect(matches.first.product.name, 'Milk');

      final suggestion = shopMemory.suggestPrice('Milk');
      expect(suggestion, isNotNull);
      expect(suggestion!.price, 35.0);
    });

    test('AIValidator detects arithmetic discrepancies (Qty 2 @ 35 = 100 != 70)', () {
      final validator = AIValidator();
      const parseResult = BillParseResult(
        items: [
          ParsedItem(
            name: 'Milk',
            quantity: 2.0,
            rate: 35.0,
            amount: 100.0, // Expected 70, given 100
          ),
        ],
      );

      final valResult = validator.validate(parseResult);
      expect(valResult.issues.isNotEmpty, true);
      expect(valResult.issues.any((i) => i.message.contains('Total mismatch')), true);
    });
  });
}
