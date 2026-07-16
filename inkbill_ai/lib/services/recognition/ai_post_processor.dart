import 'dart:convert';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:inkbill_ai/core/utils/result.dart';
import 'package:inkbill_ai/core/errors/failures.dart';
import 'package:inkbill_ai/features/ai/domain/entities/recognition_result.dart';

class AIPostProcessor {
  final GenerativeModel _model;

  final String _apiKey;

  AIPostProcessor({String? apiKey}) 
      : _apiKey = apiKey ?? const String.fromEnvironment('GEMINI_API_KEY', defaultValue: ''),
        _model = GenerativeModel(
          model: 'gemini-1.5-flash',
          apiKey: apiKey ?? const String.fromEnvironment('GEMINI_API_KEY', defaultValue: ''),
          generationConfig: GenerationConfig(
            responseMimeType: 'application/json',
          ),
        );

  Future<Result<BillStructureResult>> processRawText(String rawText) async {
    if (_apiKey.isEmpty) {
      return Result.error(const RecognitionFailure(message: 'Gemini API key is not configured. Pass it via --dart-define=GEMINI_API_KEY="..."'));
    }

    try {
      final prompt = '''
You are an expert AI assisting a billing application. 
The following text is the raw OCR output from a handwritten bill.
It may contain spelling errors (e.g., 'Bred' instead of 'Bread', 'M!lk' instead of 'Milk').

Your task is to:
1. Parse the items into a structured list.
2. Correct spelling mistakes for common billing and grocery items.
3. Extract the item name, quantity (number), and rate (price).
4. Assign a confidence score (0.0 to 1.0) to each item. If you had to heavily correct the spelling or infer the numbers, lower the confidence score (e.g., 0.5 or 0.6). If it was perfectly clear, use 0.9 or 1.0.

Output MUST be exactly valid JSON in this format:
{
  "items": [
    {
      "name": "Bread",
      "quantity": 2,
      "rate": 10.0,
      "confidence": 0.85
    }
  ],
  "overallConfidence": 0.9
}

Raw Text:
$rawText
''';

      final content = [Content.text(prompt)];
      final response = await _model.generateContent(content);
      
      final text = response.text;
      if (text == null || text.isEmpty) {
        return Result.error(const RecognitionFailure(message: 'AI returned empty response.'));
      }

      final jsonMap = jsonDecode(text) as Map<String, dynamic>;
      final itemsJson = jsonMap['items'] as List<dynamic>? ?? [];
      final overallConfidence = (jsonMap['overallConfidence'] as num?)?.toDouble() ?? 0.5;

      final lineItems = itemsJson.map((e) {
        final map = e as Map<String, dynamic>;
        return LineItemData(
          name: map['name'] as String? ?? 'Item',
          quantity: (map['quantity'] as num?)?.toDouble() ?? 1.0,
          rate: (map['rate'] as num?)?.toDouble() ?? 0.0,
          confidence: (map['confidence'] as num?)?.toDouble() ?? 1.0,
        );
      }).toList();

      return Result.success(BillStructureResult(
        lineItems: lineItems,
        confidence: overallConfidence,
      ));

    } catch (e) {
      return Result.error(RecognitionFailure(message: 'AI post-processing failed: $e'));
    }
  }
}
