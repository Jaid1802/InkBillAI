import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:inkbill_ai/features/handwriting/domain/entities/ink_stroke.dart';
import 'package:inkbill_ai/features/handwriting/domain/entities/ink_point.dart';

class RecoveryData {
  final List<InkStroke>? pendingStrokes;
  final String? pendingPageId;
  final String? pendingBillJson;
  final String? pendingOcrJson;
  final DateTime? savedAt;

  const RecoveryData({
    this.pendingStrokes,
    this.pendingPageId,
    this.pendingBillJson,
    this.pendingOcrJson,
    this.savedAt,
  });

  bool get hasRecovery => pendingStrokes != null || pendingBillJson != null;
}

class RecoveryService {
  static const String _strokesKey = 'recovery_strokes';
  static const String _pageIdKey = 'recovery_page_id';
  static const String _billKey = 'recovery_bill';
  static const String _ocrKey = 'recovery_ocr';
  static const String _timestampKey = 'recovery_timestamp';

  static Future<void> saveCanvasState({
    required List<InkStroke> strokes,
    required String pageId,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final strokesJson = strokes.map((s) => _strokeToJson(s)).toList();
      await prefs.setString(_strokesKey, jsonEncode(strokesJson));
      await prefs.setString(_pageIdKey, pageId);
      await prefs.setString(
          _timestampKey, DateTime.now().toIso8601String());
    } catch (e) {
      debugPrint('Recovery save failed: $e');
    }
  }

  static Future<void> saveBillDraft(String billJson) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_billKey, billJson);
      await prefs.setString(
          _timestampKey, DateTime.now().toIso8601String());
    } catch (e) {
      debugPrint('Recovery bill save failed: $e');
    }
  }

  static Future<void> saveOcrResult(String ocrJson) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_ocrKey, ocrJson);
    } catch (e) {
      debugPrint('Recovery OCR save failed: $e');
    }
  }

  static Future<RecoveryData> checkForRecovery() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final strokesStr = prefs.getString(_strokesKey);
      final pageId = prefs.getString(_pageIdKey);
      final billJson = prefs.getString(_billKey);
      final ocrJson = prefs.getString(_ocrKey);
      final timestampStr = prefs.getString(_timestampKey);

      List<InkStroke>? strokes;
      if (strokesStr != null) {
        final strokesList = jsonDecode(strokesStr) as List;
        strokes = strokesList
            .map((s) => _strokeFromJson(s as Map<String, dynamic>))
            .toList();
      }

      DateTime? savedAt;
      if (timestampStr != null) {
        savedAt = DateTime.tryParse(timestampStr);
      }

      return RecoveryData(
        pendingStrokes: strokes,
        pendingPageId: pageId,
        pendingBillJson: billJson,
        pendingOcrJson: ocrJson,
        savedAt: savedAt,
      );
    } catch (e) {
      debugPrint('Recovery check failed: $e');
      return const RecoveryData();
    }
  }

  static Future<void> clearRecovery() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_strokesKey);
      await prefs.remove(_pageIdKey);
      await prefs.remove(_billKey);
      await prefs.remove(_ocrKey);
      await prefs.remove(_timestampKey);
    } catch (e) {
      debugPrint('Recovery clear failed: $e');
    }
  }

  static Map<String, dynamic> _strokeToJson(InkStroke stroke) {
    return {
      'id': stroke.id,
      'pageId': stroke.pageId,
      'color': stroke.color,
      'width': stroke.width,
      'createdAt': stroke.createdAt.millisecondsSinceEpoch,
      'points': stroke.points
          .map((p) => {
                'x': p.x,
                'y': p.y,
                'pressure': p.pressure,
                'timestampMs': p.timestampMs,
              })
          .toList(),
    };
  }

  static InkStroke _strokeFromJson(Map<String, dynamic> json) {
    final points = (json['points'] as List).map((p) {
      final pm = p as Map<String, dynamic>;
      return InkPoint(
        x: (pm['x'] as num).toDouble(),
        y: (pm['y'] as num).toDouble(),
        pressure: (pm['pressure'] as num?)?.toDouble() ?? 0.5,
        timestampMs: (pm['timestampMs'] as num).toInt(),
      );
    }).toList();

    return InkStroke(
      id: json['id'] as String,
      pageId: json['pageId'] as String,
      points: points,
      color: json['color'] as int? ?? 0xFF212121,
      width: (json['width'] as num?)?.toDouble() ?? 3.0,
      createdAt: DateTime.fromMillisecondsSinceEpoch(
          json['createdAt'] as int),
    );
  }
}
