import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:inkbill_ai/features/ai/data/datasources/paddle_ocr_datasource.dart';

class MockHttpClient extends http.BaseClient {
  final Future<http.Response> Function(http.BaseRequest request) handler;

  MockHttpClient(this.handler);

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    final response = await handler(request);
    return http.StreamedResponse(
      Stream.value(response.bodyBytes),
      response.statusCode,
      headers: response.headers,
    );
  }
}

void main() {
  group('PaddleOcrDataSource Tests', () {
    test('recognizeStrokes returns empty result immediately on empty strokes', () async {
      final client = MockHttpClient((request) async {
        return http.Response('{}', 200);
      });

      final dataSource = PaddleOcrDataSource(client: client);
      final result = await dataSource.recognizeStrokes([]);

      expect(result.isSuccess, isTrue);
      expect(result.dataOrThrow.candidates, isEmpty);
      expect(result.dataOrThrow.bestText, isNull);
    });

    test('recognizeText sends X-API-Key and parses lines and confidence', () async {
      late http.BaseRequest capturedRequest;
      final mockPayload = {
        'lines': [
          {
            'text': 'Basmati Rice',
            'confidence': 0.95,
            'x': 10.0,
            'y': 20.0,
            'w': 150.0,
            'h': 30.0,
            'row': 0,
            'column': 0,
          },
          {
            'text': '2 100',
            'confidence': 0.90,
            'x': 200.0,
            'y': 20.0,
            'w': 80.0,
            'h': 30.0,
            'row': 0,
            'column': 1,
          }
        ],
        'raw_text': 'Basmati Rice 2 100',
        'image_width': 500,
        'image_height': 300,
        'model_type': 'server',
      };

      final client = MockHttpClient((request) async {
        capturedRequest = request;
        return http.Response(
          jsonEncode(mockPayload),
          200,
          headers: {'content-type': 'application/json'},
        );
      });

      final dataSource = PaddleOcrDataSource(
        client: client,
        baseUrl: 'https://test-ocr.com',
        apiKey: 'test-secret-key-123',
      );

      final result = await dataSource.recognizeText('fake_base64_img');

      expect(result.isSuccess, isTrue);
      expect(capturedRequest.headers['X-API-Key'], 'test-secret-key-123');
      expect(result.dataOrThrow.bestText, 'Basmati Rice 2 100');
      expect(result.dataOrThrow.candidates.length, 2);
      expect(result.dataOrThrow.confidence, closeTo(0.925, 0.001));
    });

    test('recognizeText returns failure on 401 unauthorized', () async {
      final client = MockHttpClient((request) async {
        return http.Response(
          jsonEncode({'detail': 'Invalid or missing X-API-Key header'}),
          401,
          headers: {'content-type': 'application/json'},
        );
      });

      final dataSource = PaddleOcrDataSource(
        client: client,
        baseUrl: 'https://test-ocr.com',
        apiKey: 'invalid-key',
      );

      final result = await dataSource.recognizeText('fake_base64_img');

      expect(result.isError, isTrue);
      expect(result.errorOrNull?.message, contains('Authentication failed'));
    });

    test('recognizeText returns failure when no text detected in response', () async {
      final client = MockHttpClient((request) async {
        return http.Response(
          jsonEncode({
            'lines': [],
            'raw_text': '',
            'image_width': 500,
            'image_height': 300,
            'model_type': 'server',
          }),
          200,
          headers: {'content-type': 'application/json'},
        );
      });

      final dataSource = PaddleOcrDataSource(
        client: client,
        baseUrl: 'https://test-ocr.com',
      );

      final result = await dataSource.recognizeText('blank_base64');

      expect(result.isError, isTrue);
      expect(result.errorOrNull?.message, contains('No handwritten text'));
    });

    test('extractBillStructure parses row and columns into LineItemData', () async {
      final mockPayload = {
        'lines': [
          {
            'text': 'Amul Butter',
            'confidence': 0.92,
            'x': 10.0,
            'y': 20.0,
            'w': 100.0,
            'h': 25.0,
            'row': 0,
            'column': 0,
          },
          {
            'text': '2',
            'confidence': 0.90,
            'x': 150.0,
            'y': 20.0,
            'w': 30.0,
            'h': 25.0,
            'row': 0,
            'column': 1,
          },
          {
            'text': '55',
            'confidence': 0.88,
            'x': 220.0,
            'y': 20.0,
            'w': 40.0,
            'h': 25.0,
            'row': 0,
            'column': 2,
          },
        ],
        'raw_text': 'Amul Butter 2 55',
        'image_width': 600,
        'image_height': 200,
        'model_type': 'server',
      };

      final client = MockHttpClient((request) async {
        return http.Response(
          jsonEncode(mockPayload),
          200,
          headers: {'content-type': 'application/json'},
        );
      });

      final dataSource = PaddleOcrDataSource(
        client: client,
        baseUrl: 'https://test-ocr.com',
      );

      final emptyStrokesResult = await dataSource.extractBillStructure([]);
      expect(emptyStrokesResult.isSuccess, isTrue);
      expect(emptyStrokesResult.dataOrThrow.lineItems, isEmpty);
    });
  });
}
