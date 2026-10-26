import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:inkbill_ai/core/utils/result.dart';
import 'package:inkbill_ai/core/errors/failures.dart';
import 'package:inkbill_ai/features/ai/domain/entities/recognition_result.dart';
import 'package:inkbill_ai/features/ai/domain/repositories/recognition_repository.dart';
import 'package:inkbill_ai/features/handwriting/domain/entities/ink_stroke.dart';
import 'package:inkbill_ai/services/recognition/bill_parser.dart';
import 'package:inkbill_ai/services/recognition/image_preprocessor.dart';
import 'package:inkbill_ai/services/recognition/layout_analyzer.dart';

class PaddleOcrRawLine {
  final String text;
  final double confidence;
  final double x;
  final double y;
  final double w;
  final double h;
  final int row;
  final int column;

  const PaddleOcrRawLine({
    required this.text,
    required this.confidence,
    required this.x,
    required this.y,
    required this.w,
    required this.h,
    required this.row,
    required this.column,
  });

  factory PaddleOcrRawLine.fromJson(Map<String, dynamic> json) {
    return PaddleOcrRawLine(
      text: (json['text'] as String?)?.trim() ?? '',
      confidence: (json['confidence'] as num?)?.toDouble() ?? 0.0,
      x: (json['x'] as num?)?.toDouble() ?? 0.0,
      y: (json['y'] as num?)?.toDouble() ?? 0.0,
      w: (json['w'] as num?)?.toDouble() ?? 0.0,
      h: (json['h'] as num?)?.toDouble() ?? 0.0,
      row: (json['row'] as num?)?.toInt() ?? 0,
      column: (json['column'] as num?)?.toInt() ?? 0,
    );
  }
}

class PaddleOcrApiResponse {
  final List<PaddleOcrRawLine> lines;
  final String rawText;
  final int imageWidth;
  final int imageHeight;

  const PaddleOcrApiResponse({
    required this.lines,
    required this.rawText,
    required this.imageWidth,
    required this.imageHeight,
  });

  factory PaddleOcrApiResponse.fromJson(Map<String, dynamic> json) {
    final rawLines = json['lines'] as List<dynamic>? ?? [];
    final parsedLines = rawLines
        .whereType<Map<String, dynamic>>()
        .map(PaddleOcrRawLine.fromJson)
        .toList();

    return PaddleOcrApiResponse(
      lines: parsedLines,
      rawText: json['raw_text'] as String? ?? '',
      imageWidth: (json['image_width'] as num?)?.toInt() ?? 0,
      imageHeight: (json['image_height'] as num?)?.toInt() ?? 0,
    );
  }
}

class PaddleOcrDataSource implements RecognitionRepository {
  final http.Client _client;
  final String baseUrl;
  final String apiKey;
  final ImagePreprocessor _preprocessor;
  final LayoutAnalyzer _layoutAnalyzer;
  final BillParser _billParser;

  PaddleOcrDataSource({
    http.Client? client,
    String? baseUrl,
    String? apiKey,
    ImagePreprocessor? preprocessor,
    LayoutAnalyzer? layoutAnalyzer,
    BillParser? billParser,
  })  : _client = client ?? http.Client(),
        baseUrl = baseUrl ??
            const String.fromEnvironment(
              'OCR_BASE_URL',
              defaultValue: 'https://inkbill-ocr-backend.onrender.com',
            ),
        apiKey = apiKey ??
            const String.fromEnvironment('OCR_API_KEY', defaultValue: ''),
        _preprocessor = preprocessor ?? ImagePreprocessor(),
        _layoutAnalyzer = layoutAnalyzer ?? LayoutAnalyzer(),
        _billParser = billParser ?? BillParser();

  http.Client get client => _client;

  String get _normalizedBaseUrl {
    var url = baseUrl.trim();
    if (url.endsWith('/')) {
      url = url.substring(0, url.length - 1);
    }
    return url;
  }

  Map<String, String> get _requestHeaders {
    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      if (apiKey.isNotEmpty) 'X-API-Key': apiKey,
    };
  }

  Future<Result<PaddleOcrApiResponse>> _callOcrBackend(
    String base64Image, {
    Duration initialTimeout = const Duration(seconds: 30),
    Duration maxWakeUpTimeout = const Duration(seconds: 90),
  }) async {
    final endpoint = Uri.parse('$_normalizedBaseUrl/ocr');
    final payload = jsonEncode({'image': base64Image});
    final stopwatch = Stopwatch()..start();

    int attempt = 0;
    while (true) {
      attempt++;
      try {
        final timeout = (attempt == 1) ? initialTimeout : const Duration(seconds: 25);
        final response = await _client
            .post(
              endpoint,
              headers: _requestHeaders,
              body: payload,
            )
            .timeout(timeout);

        if (response.statusCode == 200) {
          final decoded = jsonDecode(response.body) as Map<String, dynamic>;
          return Result.success(PaddleOcrApiResponse.fromJson(decoded));
        }

        if (response.statusCode == 401 || response.statusCode == 403) {
          return Result.error(
            const RecognitionFailure(
              message:
                  'Authentication failed (401). Please verify the OCR_API_KEY setting.',
            ),
          );
        }

        if (response.statusCode == 413) {
          return Result.error(
            const RecognitionFailure(
              message:
                  'Image payload is too large. Please crop or reduce the canvas area.',
            ),
          );
        }

        // 502/503/504 typically indicate Render service is still waking up from sleep
        if (response.statusCode == 502 ||
            response.statusCode == 503 ||
            response.statusCode == 504) {
          if (stopwatch.elapsed < maxWakeUpTimeout) {
            await Future.delayed(const Duration(seconds: 3));
            continue;
          }
          return Result.error(
            const RecognitionFailure(
              message:
                  'The OCR server is waking up from idle state. Please tap Retry in a few seconds.',
            ),
          );
        }

        return Result.error(
          RecognitionFailure(
            message: 'OCR service returned error: ${response.statusCode} ${response.body}',
          ),
        );
      } on TimeoutException {
        if (stopwatch.elapsed < maxWakeUpTimeout) {
          await Future.delayed(const Duration(seconds: 2));
          continue;
        }
        return Result.error(
          const RecognitionFailure(
            message:
                'Connection timed out. Render free tier takes ~60-90s to wake up on first call. Please tap Retry.',
          ),
        );
      } on SocketException catch (e) {
        if (stopwatch.elapsed < maxWakeUpTimeout) {
          await Future.delayed(const Duration(seconds: 3));
          continue;
        }
        return Result.error(
          RecognitionFailure(
            message:
                'Unable to connect to OCR backend ($endpoint). Please verify internet connection: $e',
          ),
        );
      } catch (e) {
        return Result.error(
          RecognitionFailure(message: 'OCR communication error: $e'),
        );
      }
    }
  }

  @override
  Future<Result<RecognitionResult>> recognizeStrokes(List<InkStroke> strokes) async {
    if (strokes.isEmpty) {
      return Result.success(const RecognitionResult());
    }

    try {
      final imageFile = await _preprocessor.preprocessStrokesToImage(strokes);
      final bytes = await imageFile.readAsBytes();
      final base64Image = base64Encode(bytes);

      return recognizeText(base64Image);
    } catch (e) {
      return Result.error(
        RecognitionFailure(message: 'Failed to preprocess strokes: $e'),
      );
    }
  }

  @override
  Future<Result<RecognitionResult>> recognizeText(String base64Image) async {
    final apiResult = await _callOcrBackend(base64Image);
    return apiResult.when(
      success: (data) {
        if (data.lines.isEmpty) {
          return Result.error(
            const RecognitionFailure(
              message: 'No handwritten text was detected on the canvas.',
            ),
          );
        }

        final candidates = data.lines
            .map((l) => RecognizedText(text: l.text, confidence: l.confidence))
            .toList();

        final avgConfidence = data.lines
                .map((l) => l.confidence)
                .reduce((a, b) => a + b) /
            data.lines.length;

        final bestText = data.rawText.isNotEmpty
            ? data.rawText
            : data.lines.map((l) => l.text).join(' ');

        return Result.success(
          RecognitionResult(
            candidates: candidates,
            bestText: bestText,
            confidence: avgConfidence.clamp(0.0, 1.0),
          ),
        );
      },
      error: (failure) => Result.error(failure),
    );
  }

  @override
  Future<Result<LayoutRecognitionResult>> detectLayout(List<InkStroke> strokes) async {
    final layoutResult = _layoutAnalyzer.analyze(strokes);
    final rows = layoutResult.lines.map((line) {
      final cells = line.strokes.map((s) {
        return DetectedCell(
          text: const RecognitionResult(),
          x: s.points.isNotEmpty ? s.points.first.x : 0,
          y: s.points.isNotEmpty ? s.points.first.y : 0,
        );
      }).toList();
      return DetectedRow(cells: cells);
    }).toList();

    return Result.success(
      LayoutRecognitionResult(
        rows: rows,
        confidence: layoutResult.confidence,
      ),
    );
  }

  @override
  Future<Result<BillStructureResult>> extractBillStructure(List<InkStroke> strokes) async {
    if (strokes.isEmpty) {
      return Result.success(const BillStructureResult());
    }

    try {
      final imageFile = await _preprocessor.preprocessStrokesToImage(strokes);
      final bytes = await imageFile.readAsBytes();
      final base64Image = base64Encode(bytes);

      final apiResult = await _callOcrBackend(base64Image);
      return apiResult.when(
        success: (data) {
          if (data.lines.isEmpty) {
            return Result.error(
              const RecognitionFailure(
                message:
                    'No handwriting detected on canvas. Please write clearly and retry.',
              ),
            );
          }

          // Group lines by row index
          final rowsMap = <int, List<PaddleOcrRawLine>>{};
          for (final line in data.lines) {
            rowsMap.setdefault(line.row, []).add(line);
          }

          final rawLines = <String>[];
          for (final rowEntry in rowsMap.entries) {
            final sortedCols = List<PaddleOcrRawLine>.from(rowEntry.value)
              ..sort((a, b) => a.x.compareTo(b.x));
            final rowText = sortedCols.map((c) => c.text).join(' ');
            if (rowText.trim().isNotEmpty) {
              rawLines.add(rowText.trim());
            }
          }

          // Parse using BillParser
          final parseResult = _billParser.parse(rawLines);
          final lineItems = <LineItemData>[];

          if (parseResult.items.isNotEmpty) {
            for (final item in parseResult.items) {
              lineItems.add(
                LineItemData(
                  name: item.name,
                  quantity: item.quantity,
                  rate: item.rate,
                  amount: item.amount ?? item.calculatedAmount,
                  confidence: item.overallConfidence,
                  nameConfidence: item.nameConfidence,
                  quantityConfidence: item.quantityConfidence,
                  rateConfidence: item.rateConfidence,
                  isMissingQuantity: item.isMissingQuantity,
                  isMissingRate: item.isMissingRate,
                  amountMismatch: item.amountMismatch,
                ),
              );
            }
          } else {
            // Fallback: per-row positional interpretation
            for (final rowEntry in rowsMap.entries) {
              final cols = List<PaddleOcrRawLine>.from(rowEntry.value)
                ..sort((a, b) => a.x.compareTo(b.x));
              if (cols.isEmpty) continue;

              final nameText = cols[0].text;
              double? qty;
              double? rate;

              if (cols.length > 1) {
                qty = double.tryParse(cols[1].text.replaceAll(RegExp(r'[^\d.]'), ''));
              }
              if (cols.length > 2) {
                rate = double.tryParse(cols[2].text.replaceAll(RegExp(r'[^\d.]'), ''));
              }

              final amount = (qty != null && rate != null) ? qty * rate : null;
              final rowConf = cols.map((c) => c.confidence).reduce((a, b) => a + b) / cols.length;

              lineItems.add(
                LineItemData(
                  name: nameText,
                  quantity: qty,
                  rate: rate,
                  amount: amount,
                  confidence: rowConf,
                  isMissingQuantity: qty == null,
                  isMissingRate: rate == null,
                ),
              );
            }
          }

          final overallConfidence = lineItems.isNotEmpty
              ? lineItems.map((e) => e.confidence).reduce((a, b) => a + b) / lineItems.length
              : 0.0;

          return Result.success(
            BillStructureResult(
              lineItems: lineItems,
              confidence: overallConfidence,
              rawText: data.rawText,
              warnings: parseResult.warnings,
            ),
          );
        },
        error: (failure) => Result.error(failure),
      );
    } catch (e) {
      return Result.error(
        RecognitionFailure(message: 'Failed to extract bill structure: $e'),
      );
    }
  }

  @override
  Future<Result<double>> calculateConfidence(List<InkStroke> strokes) async {
    if (strokes.isEmpty) return Result.success(0.0);
    return Result.success(0.85);
  }
}

extension _MapDefault<K, V> on Map<K, V> {
  V setdefault(K key, V defaultValue) {
    if (!containsKey(key)) {
      this[key] = defaultValue;
    }
    return this[key]!;
  }
}
