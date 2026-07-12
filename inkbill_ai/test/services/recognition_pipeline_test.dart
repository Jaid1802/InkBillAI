import 'package:flutter_test/flutter_test.dart';
import 'package:inkbill_ai/core/utils/result.dart';
import 'package:inkbill_ai/features/ai/domain/entities/recognition_result.dart';
import 'package:inkbill_ai/features/ai/domain/repositories/recognition_repository.dart';
import 'package:inkbill_ai/features/handwriting/domain/entities/ink_stroke.dart';
import 'package:inkbill_ai/features/handwriting/domain/entities/ink_point.dart';
import 'package:inkbill_ai/services/recognition/recognition_pipeline.dart';

class _MockRecognitionRepository extends RecognitionRepository {
  @override
  Future<Result<RecognitionResult>> recognizeStrokes(
      List<InkStroke> strokes) async {
    return Result.success(const RecognitionResult(
      bestText: 'Tea',
      confidence: 0.85,
      candidates: [RecognizedText(text: 'Tea', confidence: 0.85)],
    ));
  }

  @override
  Future<Result<RecognitionResult>> recognizeText(String base64Image) async {
    return Result.success(const RecognitionResult());
  }

  @override
  Future<Result<LayoutRecognitionResult>> detectLayout(
      List<InkStroke> strokes) async {
    return Result.success(const LayoutRecognitionResult(confidence: 0.8));
  }

  @override
  Future<Result<BillStructureResult>> extractBillStructure(
      List<InkStroke> strokes) async {
    return Result.success(const BillStructureResult(
      lineItems: [LineItemData(name: 'Tea', quantity: 2, rate: 10, confidence: 0.8)],
      confidence: 0.8,
    ));
  }

  @override
  Future<Result<double>> calculateConfidence(
      List<InkStroke> strokes) async {
    return Result.success(0.85);
  }
}

void main() {
  group('RecognitionPipeline', () {
    late RecognitionPipeline pipeline;
    late _MockRecognitionRepository repository;

    setUp(() {
      repository = _MockRecognitionRepository();
      pipeline = RecognitionPipeline(repository: repository);
    });

    tearDown(() {
      pipeline.dispose();
    });

    test('starts in idle state', () {
      expect(pipeline.value.stage, PipelineStage.idle);
    });

    test('recognizeStrokes returns recognition result', () async {
      final strokes = [
        InkStroke(
          id: 's1',
          pageId: 'p1',
          points: const [InkPoint(x: 0, y: 0, timestampMs: 1)],
          createdAt: DateTime.now(),
        ),
      ];

      final result = await pipeline.recognizeStrokes(strokes);
      expect(result.isSuccess, true);
      expect(result.dataOrThrow.bestText, 'Tea');
      expect(result.dataOrThrow.confidence, 0.85);
    });

    test('extractBillStructure returns structure', () async {
      final strokes = [
        InkStroke(
          id: 's1',
          pageId: 'p1',
          points: const [InkPoint(x: 0, y: 0, timestampMs: 1)],
          createdAt: DateTime.now(),
        ),
      ];

      final result = await pipeline.extractBillStructure(strokes);
      expect(result.isSuccess, true);
      expect(result.dataOrThrow.lineItems.length, 1);
      expect(result.dataOrThrow.lineItems.first.name, 'Tea');
    });

    test('reset clears pipeline state', () async {
      final strokes = [
        InkStroke(
          id: 's1',
          pageId: 'p1',
          points: const [InkPoint(x: 0, y: 0, timestampMs: 1)],
          createdAt: DateTime.now(),
        ),
      ];

      await pipeline.recognizeStrokes(strokes);
      expect(pipeline.value.stage, PipelineStage.complete);

      pipeline.reset();
      expect(pipeline.value.stage, PipelineStage.idle);
      expect(pipeline.value.result, isNull);
    });

    test('recognizeStrokes updates pipeline stage', () async {
      final strokes = [
        InkStroke(
          id: 's1',
          pageId: 'p1',
          points: const [InkPoint(x: 0, y: 0, timestampMs: 1)],
          createdAt: DateTime.now(),
        ),
      ];

      final stageChanges = <PipelineStage>[];
      pipeline.addListener(() {
        stageChanges.add(pipeline.value.stage);
      });

      await pipeline.recognizeStrokes(strokes);
      expect(stageChanges, contains(PipelineStage.recognizing));
      expect(stageChanges, contains(PipelineStage.complete));
    });
  });
}
