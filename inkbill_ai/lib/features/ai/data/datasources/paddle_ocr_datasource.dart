import 'package:http/http.dart' as http;
import 'package:inkbill_ai/core/utils/result.dart';
import 'package:inkbill_ai/features/ai/domain/entities/recognition_result.dart';
import 'package:inkbill_ai/features/ai/domain/repositories/recognition_repository.dart';
import 'package:inkbill_ai/features/handwriting/domain/entities/ink_stroke.dart';

class PaddleOcrDataSource implements RecognitionRepository {
  final http.Client _client;
  final String baseUrl;
  final String apiKey;

  PaddleOcrDataSource({
    http.Client? client,
    String? baseUrl,
    String? apiKey,
  })  : _client = client ?? http.Client(),
        baseUrl = baseUrl ?? const String.fromEnvironment('OCR_BASE_URL', defaultValue: ''),
        apiKey = apiKey ?? const String.fromEnvironment('OCR_API_KEY', defaultValue: '');

  http.Client get client => _client;

  @override
  Future<Result<RecognitionResult>> recognizeStrokes(List<InkStroke> strokes) async {
    return Result.success(const RecognitionResult());
  }

  @override
  Future<Result<RecognitionResult>> recognizeText(String base64Image) async {
    return Result.success(const RecognitionResult());
  }

  @override
  Future<Result<LayoutRecognitionResult>> detectLayout(List<InkStroke> strokes) async {
    return Result.success(const LayoutRecognitionResult());
  }

  @override
  Future<Result<BillStructureResult>> extractBillStructure(List<InkStroke> strokes) async {
    return Result.success(const BillStructureResult());
  }

  @override
  Future<Result<double>> calculateConfidence(List<InkStroke> strokes) async {
    return Result.success(0.9);
  }
}
