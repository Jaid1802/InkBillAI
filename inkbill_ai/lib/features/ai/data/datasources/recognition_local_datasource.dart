import 'package:inkbill_ai/core/utils/result.dart';
import 'package:inkbill_ai/core/errors/failures.dart';
import 'package:inkbill_ai/features/ai/domain/entities/recognition_result.dart';
import 'package:inkbill_ai/features/handwriting/domain/entities/ink_stroke.dart';

class RecognitionLocalDataSource {
  Future<Result<RecognitionResult>> recognizeStrokes(
      List<InkStroke> strokes) async {
    try {
      final text = await _runLocalRecognition(strokes);
      return Result.success(RecognitionResult(
        candidates: [RecognizedText(text: text, confidence: 0.6)],
        bestText: text,
        confidence: 0.6,
      ));
    } catch (e) {
      return Result.error(
          RecognitionFailure(message: 'Local recognition failed'));
    }
  }

  Future<String> _runLocalRecognition(List<InkStroke> strokes) async {
    if (strokes.isEmpty) return '';

    final points = strokes.expand((s) => s.points).toList();
    if (points.isEmpty) return '';

    final bounds = _calculateBounds(strokes);
    final width = bounds['width'] as double;
    final height = bounds['height'] as double;

    if (width < 10 && height < 10) return '';
    if (height > width * 3) return '1';
    if (width > height * 3) return '-';

    return '[recognized_ink]';
  }

  Map<String, double> _calculateBounds(List<InkStroke> strokes) {
    var minX = double.infinity, minY = double.infinity;
    var maxX = double.negativeInfinity, maxY = double.negativeInfinity;

    for (final stroke in strokes) {
      for (final point in stroke.points) {
        if (point.x < minX) minX = point.x;
        if (point.y < minY) minY = point.y;
        if (point.x > maxX) maxX = point.x;
        if (point.y > maxY) maxY = point.y;
      }
    }

    return {
      'x': minX,
      'y': minY,
      'width': maxX - minX,
      'height': maxY - minY,
    };
  }

  Future<Result<LayoutRecognitionResult>> detectLayout(
      List<InkStroke> strokes) async {
    return Result.success(const LayoutRecognitionResult(confidence: 0.3));
  }

  Future<Result<BillStructureResult>> extractBillStructure(
      List<InkStroke> strokes) async {
    return Result.success(const BillStructureResult(confidence: 0.3));
  }

  Future<Result<double>> calculateConfidence(
      List<InkStroke> strokes) async {
    return Result.success(0.5);
  }
}
