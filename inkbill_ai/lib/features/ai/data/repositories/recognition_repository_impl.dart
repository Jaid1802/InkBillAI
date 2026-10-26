import 'package:inkbill_ai/core/utils/result.dart';
import 'package:inkbill_ai/features/ai/domain/entities/recognition_result.dart';
import 'package:inkbill_ai/features/ai/domain/repositories/recognition_repository.dart';
import 'package:inkbill_ai/features/ai/data/datasources/paddle_ocr_datasource.dart';
import 'package:inkbill_ai/features/handwriting/domain/entities/ink_stroke.dart';

class RecognitionRepositoryImpl implements RecognitionRepository {
  final PaddleOcrDataSource _dataSource;

  RecognitionRepositoryImpl(this._dataSource);

  @override
  Future<Result<RecognitionResult>> recognizeStrokes(List<InkStroke> strokes) {
    return _dataSource.recognizeStrokes(strokes);
  }

  @override
  Future<Result<RecognitionResult>> recognizeText(String base64Image) {
    return _dataSource.recognizeText(base64Image);
  }

  @override
  Future<Result<LayoutRecognitionResult>> detectLayout(List<InkStroke> strokes) {
    return _dataSource.detectLayout(strokes);
  }

  @override
  Future<Result<BillStructureResult>> extractBillStructure(List<InkStroke> strokes) {
    return _dataSource.extractBillStructure(strokes);
  }

  @override
  Future<Result<double>> calculateConfidence(List<InkStroke> strokes) {
    return _dataSource.calculateConfidence(strokes);
  }
}
