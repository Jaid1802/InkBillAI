import 'package:flutter_test/flutter_test.dart';
import 'package:inkbill_ai/services/recovery_service.dart';
import 'package:inkbill_ai/features/handwriting/domain/entities/ink_stroke.dart';
import 'package:inkbill_ai/features/handwriting/domain/entities/ink_point.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('RecoveryService', () {
    test('saves and retrieves canvas state', () async {
      final strokes = [
        InkStroke(
          id: 'str_1',
          pageId: 'page_1',
          points: [
            InkPoint(x: 10, y: 20, timestampMs: 1000),
            InkPoint(x: 20, y: 30, timestampMs: 1001),
          ],
          color: 0xFF212121,
          width: 3.0,
          createdAt: DateTime.now(),
        ),
      ];

      await RecoveryService.saveCanvasState(
        strokes: strokes,
        pageId: 'page_1',
      );

      final recovery = await RecoveryService.checkForRecovery();

      expect(recovery.hasRecovery, isTrue);
      expect(recovery.pendingStrokes, isNotNull);
      expect(recovery.pendingStrokes!.length, 1);
      expect(recovery.pendingPageId, 'page_1');
    });

    test('clears recovery data', () async {
      await RecoveryService.saveCanvasState(
        strokes: [],
        pageId: 'page_1',
      );

      await RecoveryService.clearRecovery();

      final recovery = await RecoveryService.checkForRecovery();
      expect(recovery.hasRecovery, isFalse);
    });

    test('returns empty when no recovery data exists', () async {
      final recovery = await RecoveryService.checkForRecovery();
      expect(recovery.hasRecovery, isFalse);
      expect(recovery.pendingStrokes, isNull);
      expect(recovery.pendingPageId, isNull);
    });

    test('saves and retrieves bill draft', () async {
      const billJson = '{"id":"bill_1","total":100.0}';
      await RecoveryService.saveBillDraft(billJson);

      final recovery = await RecoveryService.checkForRecovery();
      expect(recovery.pendingBillJson, billJson);
    });

    test('saves and retrieves OCR result', () async {
      const ocrJson = '{"text":"test","confidence":0.8}';
      await RecoveryService.saveOcrResult(ocrJson);

      final recovery = await RecoveryService.checkForRecovery();
      expect(recovery.pendingOcrJson, ocrJson);
    });
  });
}
