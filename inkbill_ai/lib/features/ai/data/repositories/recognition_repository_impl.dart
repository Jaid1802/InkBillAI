import 'dart:typed_data';
import 'package:inkbill_ai/core/utils/result.dart';
import 'package:inkbill_ai/features/ai/domain/entities/recognition_result.dart';
import 'package:inkbill_ai/features/ai/domain/repositories/recognition_repository.dart';
import 'package:inkbill_ai/features/ai/data/datasources/recognition_local_datasource.dart';
import 'package:inkbill_ai/features/handwriting/domain/entities/ink_stroke.dart';

class RecognitionRepositoryImpl implements RecognitionRepository {
  final RecognitionLocalDataSource _localDataSource;

  RecognitionRepositoryImpl(this._localDataSource);

  @override
  Future<Result<RecognitionResult>> recognizeStrokes(
      List<InkStroke> strokes) {
    return _localDataSource.recognizeStrokes(strokes);
  }

  @override
  Future<Result<RecognitionResult>> recognizeText(String base64Image) {
    throw UnimplementedError('Image recognition not yet implemented');
  }

  @override
  Future<Result<LayoutRecognitionResult>> detectLayout(
      List<InkStroke> strokes) {
    return _localDataSource.detectLayout(strokes);
  }

  @override
  Future<Result<BillStructureResult>> extractBillStructure(
      List<InkStroke> strokes) {
    return _localDataSource.extractBillStructure(strokes);
  }

  @override
  Future<Result<BillStructureResult>> extractBillStructureFromImage(
      Uint8List imageBytes) {
    return _localDataSource.extractBillStructureFromImage(imageBytes);
  }

  @override
  Future<Result<double>> calculateConfidence(List<InkStroke> strokes) {
    return _localDataSource.calculateConfidence(strokes);
  }
}
