import 'dart:typed_data';
import 'package:inkbill_ai/core/utils/result.dart';
import 'package:inkbill_ai/features/handwriting/domain/entities/ink_stroke.dart';
import 'package:inkbill_ai/features/ai/domain/entities/recognition_result.dart';

abstract class RecognitionRepository {
  Future<Result<RecognitionResult>> recognizeStrokes(List<InkStroke> strokes);
  Future<Result<RecognitionResult>> recognizeText(String base64Image);
  Future<Result<LayoutRecognitionResult>> detectLayout(List<InkStroke> strokes);
  Future<Result<BillStructureResult>> extractBillStructure(List<InkStroke> strokes);
  Future<Result<BillStructureResult>> extractBillStructureFromImage(Uint8List imageBytes);
  Future<Result<double>> calculateConfidence(List<InkStroke> strokes);
}
