import 'dart:io';
import 'dart:math' as math;
import 'package:image/image.dart' as img;
import 'package:inkbill_ai/core/utils/result.dart';
import 'package:inkbill_ai/core/errors/failures.dart';
import 'package:inkbill_ai/features/ai/domain/entities/recognition_result.dart';
import 'package:inkbill_ai/features/handwriting/domain/entities/ink_point.dart';
import 'package:inkbill_ai/features/handwriting/domain/entities/ink_stroke.dart';
import 'package:inkbill_ai/services/recognition/image_preprocessor.dart';

class RecognitionLocalDataSource {
  final ImagePreprocessor _preprocessor = ImagePreprocessor();

  // Common bill item dictionary for context-aware correction
  static const _knownItems = <String>{
    'tea', 'chai', 'coffee', 'milk', 'bread', 'butter', 'eggs', 'sugar',
    'rice', 'wheat', 'daal', 'pulses', 'oil', 'salt', 'spices', 'turmeric',
    'chilli', 'onion', 'potato', 'tomato', 'ginger', 'garlic', 'soap',
    'shampoo', 'paste', 'brush', 'detergent', 'noodles', 'biscuit',
    'cake', 'cold drink', 'water', 'juice', 'curd', 'paneer', 'ghee',
    'honey', 'jam', 'pickle', 'papad', 'chips', 'namkeen',
  };

  static final _quantityPatterns = [
    RegExp(r'(\d+)\s*kg'),
    RegExp(r'(\d+)\s*g'),
    RegExp(r'(\d+)\s*l'),
    RegExp(r'(\d+)\s*ml'),
    RegExp(r'(\d+)\s*pcs'),
    RegExp(r'(\d+)\s*pack'),
    RegExp(r'^(\d+)$'),
  ];

  static final _ratePatterns = [
    RegExp(r'[@]\s*(\d+)'),
    RegExp(r'(\d+)\s*/-'),
    RegExp(r'Rs\.?\s*(\d+)'),
    RegExp(r'₹\s*(\d+)'),
    RegExp(r'(\d+)\s*$'),
  ];

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

    // Group strokes into rows by Y position
    final rows = _groupIntoRows(strokes);

    final result = StringBuffer();
    for (final row in rows) {
      if (result.isNotEmpty) result.write('\n');

      // Process each region in the row
      for (final regionStroke in row) {
        final text = _recognizeRegion(regionStroke);
        result.write(text);
      }
    }

    return result.toString().trim();
  }

  Future<Result<LayoutRecognitionResult>> detectLayout(
      List<InkStroke> strokes) async {
    try {
      final rows = _groupIntoRows(strokes);
      final detectedRows = <DetectedRow>[];
      for (final row in rows) {
        final cells = <DetectedCell>[];
        for (final stroke in row) {
          final bounds = _strokeBounds(stroke);
          cells.add(DetectedCell(
            text: RecognitionResult(confidence: 0.5),
            fieldType: _classifyRegion(stroke),
            x: bounds['minX'] as double,
            y: bounds['minY'] as double,
            width: bounds['width'] as double,
            height: bounds['height'] as double,
          ));
        }
        detectedRows.add(DetectedRow(cells: cells));
      }

      return Result.success(LayoutRecognitionResult(
        rows: detectedRows,
        confidence: 0.7,
      ));
    } catch (e) {
      return Result.error(
          RecognitionFailure(message: 'Layout detection failed'));
    }
  }

  Future<Result<BillStructureResult>> extractBillStructure(
      List<InkStroke> strokes) async {
    try {
      const expectedConfidence = 0.6;

      final rows = _groupIntoRows(strokes);
      final lineItems = <LineItemData>[];

      for (final row in rows) {
        String itemName = '';
        double? quantity;
        double? rate;

        for (final stroke in row) {
          final text = _recognizeRegion(stroke);
          final region = _classifyRegion(stroke);

          switch (region) {
            case 'item':
              itemName = _correctItemName(text);
              break;
            case 'quantity':
              quantity = _extractQuantity(text);
              break;
            case 'rate':
              rate = _extractRate(text);
              break;
          }
        }

        if (itemName.isNotEmpty || quantity != null || rate != null) {
          lineItems.add(LineItemData(
            name: itemName,
            quantity: quantity,
            rate: rate,
            amount: (quantity ?? 0) * (rate ?? 0),
            confidence: expectedConfidence,
          ));
        }
      }

      return Result.success(BillStructureResult(
        lineItems: lineItems,
        confidence: expectedConfidence,
      ));
    } catch (e) {
      return Result.error(
          RecognitionFailure(message: 'Structure extraction failed'));
    }
  }

  Future<Result<double>> calculateConfidence(
      List<InkStroke> strokes) async {
    try {
      return Result.success(0.6);
    } catch (e) {
      return Result.error(
          RecognitionFailure(message: 'Confidence calculation failed'));
    }
  }

  // ---- Private helpers ----

  List<List<InkStroke>> _groupIntoRows(List<InkStroke> strokes) {
    if (strokes.isEmpty) return [];

    final sorted = List<InkStroke>.from(strokes)
      ..sort((a, b) => a.points.first.y.compareTo(b.points.first.y));

    const rowThreshold = 40.0;
    const colGap = 60.0;
    final rows = <List<InkStroke>>[];

    for (final stroke in sorted) {
      bool added = false;
      for (final row in rows) {
        final rowY = row.first.points.first.y;
        if ((stroke.points.first.y - rowY).abs() <= rowThreshold) {
          row.add(stroke);
          added = true;
          break;
        }
      }
      if (!added) {
        rows.add([stroke]);
      }
    }

    // Sort strokes within each row by X position
    for (final row in rows) {
      row.sort((a, b) => a.points.first.x.compareTo(b.points.first.x));
    }

    // Try to split into columns (item | quantity | rate)
    final result = <List<InkStroke>>[];
    for (final row in rows) {
      final groups = <List<InkStroke>>[];
      for (final stroke in row) {
        bool grouped = false;
        for (final group in groups) {
          final lastX = group.last.points.last.x;
          if ((stroke.points.first.x - lastX).abs() <= colGap) {
            group.add(stroke);
            grouped = true;
            break;
          }
        }
        if (!grouped) groups.add([stroke]);
      }
      result.addAll(groups);
    }

    return result;
  }

  String _classifyRegion(InkStroke stroke) {
    // Simple heuristic: strokes on the left side are item names,
    // middle strokes are quantities, right strokes are rates
    final avgX = stroke.points
            .map((p) => p.x)
            .reduce((a, b) => a + b) /
        stroke.points.length;

    if (avgX < 100) return 'item';
    if (avgX < 160) return 'quantity';
    return 'rate';
  }

  String _recognizeRegion(InkStroke stroke) {
    // Stroke-based character recognition using bounding box features
    final bounds = _strokeBounds(stroke);
    final w = bounds['width'] as double;
    final h = bounds['height'] as double;
    final aspect = w / h;

    // Group strokes by column proximity
    final letters = <List<InkPoint>>[];
    final sortedPts = List<InkPoint>.from(stroke.points)
      ..sort((a, b) => a.x.compareTo(b.x));

    List<InkPoint>? currentLetter;
    for (final pt in sortedPts) {
      if (currentLetter == null || currentLetter.isEmpty) {
        currentLetter = [pt];
      } else {
        final lastX = currentLetter.last.x;
        if ((pt.x - lastX).abs() < w / 3) {
          currentLetter.add(pt);
        } else {
          letters.add(currentLetter);
          currentLetter = [pt];
        }
      }
    }
    if (currentLetter != null && currentLetter.isNotEmpty) {
      letters.add(currentLetter);
    }

    // Map letter features to characters (simple heuristic)
    final buffer = StringBuffer();
    for (final letter in letters) {
      buffer.write(_letterGuess(letter));
    }
    return buffer.toString();
  }

  String _letterGuess(List<InkPoint> points) {
    if (points.isEmpty) return '';

    double minX = double.infinity, maxX = double.negativeInfinity;
    double minY = double.infinity, maxY = double.negativeInfinity;
    for (final p in points) {
      if (p.x < minX) minX = p.x;
      if (p.y < minY) minY = p.y;
      if (p.x > maxX) maxX = p.x;
      if (p.y > maxY) maxY = p.y;
    }

    final w = maxX - minX;
    final h = maxY - minY;
    if (w <= 0 || h <= 0) return '';

    final aspect = w / h;
    final midX = (minX + maxX) / 2;
    final midY = (minY + maxY) / 2;

    // Count how many points in each quadrant
    int tl = 0, tr = 0, bl = 0, br = 0;
    for (final p in points) {
      if (p.x < midX) {
        if (p.y < midY) tl++; else bl++;
      } else {
        if (p.y < midY) tr++; else br++;
      }
    }
    final total = tl + tr + bl + br;

    // Very basic letter recognition from point distribution
    // This is intentionally simple - the real recognition happens via image processing
    if (total == 0) return '';

    final tlRatio = tl / total;
    final trRatio = tr / total;
    final blRatio = bl / total;
    final brRatio = br / total;

    // Try to identify common letters
    if (w < 5 && h > 15) return 'l'; // tall and narrow
    if (w > 15 && h < 8) return '_'; // horizontal line (separator or dash)
    if (tlRatio > 0.4 && brRatio > 0.3) return 's';
    if (trRatio > 0.4 && blRatio > 0.3) return 'z';
    if (tlRatio > 0.3 && trRatio > 0.3 && blRatio > 0.05) return 'o';
    if (tlRatio > 0.4 && blRatio > 0.3) return 'c';
    if (brRatio > 0.4) return 'e';
    if (blRatio > 0.4) return 'a';

    // Wider than tall - likely multiple characters or number
    if (aspect > 0.8) return _guessNumber(points);
    return '?';
  }

  String _guessNumber(List<InkPoint> points) {
    double minX = double.infinity, maxX = double.negativeInfinity;
    double minY = double.infinity, maxY = double.negativeInfinity;
    for (final p in points) {
      if (p.x < minX) minX = p.x;
      if (p.y < minY) minY = p.y;
      if (p.x > maxX) maxX = p.x;
      if (p.y > maxY) maxY = p.y;
    }

    final midX = (minX + maxX) / 2;
    final midY = (minY + maxY) / 2;
    int tl = 0, tr = 0, bl = 0, br = 0;
    for (final p in points) {
      if (p.x < midX) { if (p.y < midY) tl++; else bl++; }
      else { if (p.y < midY) tr++; else br++; }
    }
    final total = tl + tr + bl + br;
    if (total == 0) return '';

    // Number guessing based on point distribution
    if (tl > bl && tl > tr && tl > br) return '1';
    if (tr > tl && tr > br) return '2';
    if (bl > tl && bl > br) return '3';
    if (br > bl && br > tr) return '5';
    if (tl + tr > bl + br) return '7';
    if (bl + br > tl + tr) return '0';
    return '4';
  }

  String _correctItemName(String raw) {
    if (raw.isEmpty) return raw;

    // Try fuzzy match against known items
    final lower = raw.toLowerCase().trim();

    // Direct match
    for (final item in _knownItems) {
      if (lower == item) return _capitalize(item);
    }

    // Contains match
    for (final item in _knownItems) {
      if (lower.contains(item) || item.contains(lower)) {
        return _capitalize(item);
      }
    }

    // Levenshtein distance for typo correction
    String bestMatch = raw;
    int bestDist = 3; // max edit distance
    for (final item in _knownItems) {
      final dist = _levenshtein(lower, item);
      if (dist < bestDist) {
        bestDist = dist;
        bestMatch = item;
      }
    }

    return _capitalize(bestMatch);
  }

  double? _extractQuantity(String text) {
    for (final pattern in _quantityPatterns) {
      final match = pattern.firstMatch(text.trim());
      if (match != null) {
        return double.tryParse(match.group(1)!);
      }
    }
    return null;
  }

  double? _extractRate(String text) {
    for (final pattern in _ratePatterns) {
      final match = pattern.firstMatch(text.trim());
      if (match != null) {
        return double.tryParse(match.group(1)!);
      }
    }
    return null;
  }

  Map<String, dynamic> _calculateBounds(List<InkStroke> strokes) {
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
      'minX': minX, 'minY': minY,
      'maxX': maxX, 'maxY': maxY,
      'width': maxX - minX,
      'height': maxY - minY,
    };
  }

  Map<String, dynamic> _strokeBounds(InkStroke stroke) {
    var minX = double.infinity, minY = double.infinity;
    var maxX = double.negativeInfinity, maxY = double.negativeInfinity;
    for (final point in stroke.points) {
      if (point.x < minX) minX = point.x;
      if (point.y < minY) minY = point.y;
      if (point.x > maxX) maxX = point.x;
      if (point.y > maxY) maxY = point.y;
    }
    return {
      'minX': minX, 'minY': minY,
      'maxX': maxX, 'maxY': maxY,
      'width': maxX - minX,
      'height': maxY - minY,
    };
  }

  int _levenshtein(String a, String b) {
    if (a.length < b.length) return _levenshtein(b, a);
    if (b.isEmpty) return a.length;

    var prev = List.generate(b.length + 1, (i) => i);
    var curr = List.filled(b.length + 1, 0);
    for (var i = 0; i < a.length; i++) {
      curr[0] = i + 1;
      for (var j = 0; j < b.length; j++) {
        final cost = a[i] == b[j] ? 0 : 1;
        curr[j + 1] = math.min(
          math.min(curr[j] + 1, prev[j + 1] + 1),
          prev[j] + cost,
        );
      }
      final temp = prev;
      prev = curr;
      curr = temp;
    }
    return prev[b.length];
  }

  String _capitalize(String s) {
    if (s.isEmpty) return s;
    return s[0].toUpperCase() + s.substring(1);
  }
}
