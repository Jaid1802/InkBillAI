import 'dart:math' as math;
import 'package:inkbill_ai/features/ai/domain/entities/recognition_result.dart';
import 'package:inkbill_ai/features/products/domain/entities/product.dart';
import 'package:inkbill_ai/services/recognition/shop_memory.dart';

class ParsedItem {
  final String name;
  final double? quantity;
  final double? rate;
  final double? amount;
  final String? unit;
  final double nameConfidence;
  final double quantityConfidence;
  final double rateConfidence;
  final double amountConfidence;
  final String? matchedProductId;
  final PriceSuggestion? priceSuggestion;

  const ParsedItem({
    required this.name,
    this.quantity,
    this.rate,
    this.amount,
    this.unit,
    this.nameConfidence = 0.0,
    this.quantityConfidence = 0.0,
    this.rateConfidence = 0.0,
    this.amountConfidence = 0.0,
    this.matchedProductId,
    this.priceSuggestion,
  });

  double get overallConfidence {
    double sum = nameConfidence;
    int count = 1;
    if (quantity != null) { sum += quantityConfidence; count++; }
    if (rate != null) { sum += rateConfidence; count++; }
    if (amount != null) { sum += amountConfidence; count++; }
    return count > 0 ? sum / count : 0.0;
  }

  double? get calculatedAmount {
    if (quantity != null && rate != null) {
      return quantity! * rate!;
    }
    return null;
  }

  bool get amountMismatch {
    if (amount != null && calculatedAmount != null) {
      return (amount! - calculatedAmount!).abs() > 0.01;
    }
    return false;
  }

  bool get isMissingQuantity => quantity == null && rate != null;
  bool get isMissingRate => rate == null && quantity != null;
  bool get isInvalid => name.isEmpty || name == 'Unknown Item';
}

class BillParseResult {
  final List<ParsedItem> items;
  final double overallConfidence;
  final List<String> warnings;

  const BillParseResult({
    this.items = const [],
    this.overallConfidence = 0.0,
    this.warnings = const [],
  });
}

class BillParser {
  static const _fallbackItems = <String>{
    'tea', 'chai', 'coffee', 'milk', 'bread', 'butter', 'eggs', 'sugar',
    'rice', 'wheat', 'daal', 'pulses', 'oil', 'salt', 'spices', 'turmeric',
    'chilli', 'onion', 'potato', 'tomato', 'ginger', 'garlic',
    'soap', 'shampoo', 'paste', 'brush', 'detergent', 'noodles', 'biscuit',
    'cake', 'cold drink', 'water', 'juice', 'curd', 'paneer', 'ghee',
    'honey', 'jam', 'pickle', 'papad', 'chips', 'namkeen', 'apple',
    'banana', 'orange', 'mango', 'grapes', 'coconut', 'lemon',
    'cabbage', 'cauliflower', 'carrot', 'beans', 'peas', 'spinach',
    'chicken', 'fish', 'mutton', 'egg', 'prawns',
    'dal', 'atta', 'maida', 'sooji', 'dahi',
  };

  static const _quantityWords = <String>{
    'kg', 'kilogram', 'g', 'gram', 'l', 'liter', 'litre',
    'ml', 'milliliter', 'pcs', 'pieces', 'pack', 'packet',
    'dozen', 'dz', 'box', 'bottle', 'bag',
  };

  final ShopMemory? shopMemory;

  const BillParser({this.shopMemory});

  BillParseResult parse(List<String> rawLines) {
    if (rawLines.isEmpty) {
      return const BillParseResult(warnings: ['No text detected']);
    }

    final items = <ParsedItem>[];
    final warnings = <String>[];

    for (var i = 0; i < rawLines.length; i++) {
      final line = rawLines[i].trim();
      if (line.isEmpty) continue;

      final parsed = _parseLine(line, rawLines, i);
      if (parsed != null) {
        items.add(parsed);
      }
    }

    if (items.isEmpty) {
      warnings.add('Could not parse any bill items');
    }

    _detectDuplicates(items, warnings);
    _validateAmounts(items, warnings);

    final overallConfidence = _calculateOverallConfidence(items);

    return BillParseResult(
      items: items,
      overallConfidence: overallConfidence,
      warnings: warnings,
    );
  }

  ParsedItem? _parseLine(String line, List<String> allLines, int index) {
    if (line.length < 2) return null;

    final parsed = _extractItemAndNumbers(line);

    final nameConfidence = _nameConfidence(parsed.itemName, line);

    double? quantity;
    double? rate;
    double? amount;
    String? unit;
    double quantityConf = 0.0;
    double rateConf = 0.0;
    double amountConf = 0.0;
    PriceSuggestion? priceSuggestion;

    final numbers = _extractNumbers(line);
    final qtyInfo = _extractQuantityWithUnit(line);
    if (qtyInfo != null) {
      quantity = qtyInfo.$1;
      unit = qtyInfo.$2;
      quantityConf = 0.8;
    }

    if (numbers.length == 1) {
      if (quantity == null) {
        if (_looksLikeQuantity(line, numbers[0])) {
          quantity = numbers[0];
          quantityConf = 0.6;
        } else if (_looksLikeRate(line, numbers[0])) {
          rate = numbers[0];
          rateConf = 0.6;
        } else {
          quantity = numbers[0];
          quantityConf = 0.5;
        }
      }
    } else if (numbers.length >= 2) {
      if (quantity == null) {
        quantity = numbers[0];
        rate = numbers[1];
        quantityConf = 0.7;
        rateConf = 0.7;
      } else {
        final remaining = numbers.where((n) => n != quantity).toList();
        if (remaining.isNotEmpty) {
          rate = remaining[0];
          rateConf = 0.7;
          if (remaining.length >= 2) {
            amount = remaining[1];
            amountConf = 0.6;
          }
        } else {
          rate = numbers.length > 1 ? numbers[1] : numbers[0];
          rateConf = 0.6;
        }
      }
      if (numbers.length >= 3 && amount == null) {
        amount = numbers[2];
        amountConf = 0.6;
      }
    }

    if (quantity != null && rate == null && shopMemory != null) {
      priceSuggestion = shopMemory!.suggestPrice(parsed.itemName);
      if (priceSuggestion != null && priceSuggestion.confidence > 0.5) {
        rate = priceSuggestion.price;
        rateConf = priceSuggestion.confidence * 0.8;
      }
    }

    if (amount == null && quantity != null && rate != null) {
      amount = quantity * rate;
      amountConf = math.min(quantityConf, rateConf) * 0.9;
    }

    final hasEnoughInfo =
        parsed.itemName.isNotEmpty &&
        nameConfidence > 0.3 &&
        (quantity != null || rate != null);

    if (!hasEnoughInfo) {
      return ParsedItem(
        name: 'Unknown Item',
        nameConfidence: nameConfidence,
        quantityConfidence: quantityConf,
        rateConfidence: rateConf,
        amountConfidence: amountConf,
        priceSuggestion: priceSuggestion,
      );
    }

    return ParsedItem(
      name: parsed.itemName,
      quantity: quantity,
      rate: rate,
      amount: amount,
      unit: unit,
      nameConfidence: nameConfidence,
      quantityConfidence: quantityConf,
      rateConfidence: rateConf,
      amountConfidence: amountConf,
      matchedProductId: parsed.matchedProductId,
      priceSuggestion: priceSuggestion,
    );
  }

  _ItemResult _extractItemAndNumbers(String line) {
    final cleaned = _cleanText(line);
    if (cleaned.isEmpty) return _ItemResult('', null);

    if (shopMemory != null && shopMemory!.isLoaded) {
      for (final word in cleaned.split(' ')) {
        if (word.length >= 2) {
          final matches = shopMemory!.findMatches(word, maxResults: 1);
          if (matches.isNotEmpty && matches.first.confidence > 0.5) {
            return _ItemResult(
              matches.first.matchedName,
              matches.first.product.id,
            );
          }
        }
      }
    }

    for (final item in _fallbackItems) {
      if (cleaned.contains(item) ||
          _similarity(cleaned.split(' ').first, item) > 0.75) {
        return _ItemResult(_capitalize(item), null);
      }
    }

    final firstWord = cleaned.split(' ').first;
    if (firstWord.length >= 3 && !_isNumeric(firstWord)) {
      return _ItemResult(_capitalize(firstWord), null);
    }

    return _ItemResult('', null);
  }

  String _cleanText(String text) {
    return text
        .toLowerCase()
        .replaceAll(RegExp(r'[0-9\s\.,/-]+'), ' ')
        .trim();
  }

  bool _isNumeric(String s) => double.tryParse(s) != null;

  static String normalizeDevanagariNumerals(String text) {
    const devanagariDigits = ['०', '१', '२', '३', '४', '५', '६', '७', '८', '९'];
    String result = text;
    for (int i = 0; i < devanagariDigits.length; i++) {
      result = result.replaceAll(devanagariDigits[i], '$i');
    }
    return result;
  }

  List<double> _extractNumbers(String line) {
    final normalized = normalizeDevanagariNumerals(line);
    final matches = RegExp(r'(\d+\.?\d*)').allMatches(normalized);
    return matches.map((m) => double.tryParse(m.group(1)!) ?? 0.0).toList();
  }

  (double, String)? _extractQuantityWithUnit(String line) {
    final lower = line.toLowerCase();
    for (final pattern in [
      RegExp(r'(\d+\.?\d*)\s*(kg|kilogram|g|gram|l|liter|litre|ml|milliliter|pcs|pieces|pack|packet|dozen|dz|box|bottle|bag)\b'),
      RegExp(r'\b(kg|kilogram|g|gram|l|liter|litre|ml|milliliter|pcs|pack)\s*(\d+\.?\d*)'),
    ]) {
      final match = pattern.firstMatch(lower);
      if (match != null) {
        final g1Num = double.tryParse(match.group(1)!);
        final g2Num = double.tryParse(match.group(2)!);
        final quantity = g1Num ?? g2Num;
        final unitStr = g1Num != null ? match.group(2) : match.group(1);
        if (quantity != null && unitStr != null && _quantityWords.contains(unitStr)) {
          return (quantity, unitStr);
        }
      }
    }
    return null;
  }

  double _nameConfidence(String name, String originalLine) {
    final cleaned = _cleanText(originalLine);
    final nameLower = name.toLowerCase();

    if (shopMemory != null && shopMemory!.isLoaded) {
      final matches = shopMemory!.findMatches(nameLower, maxResults: 1);
      if (matches.isNotEmpty) {
        return 0.7 + matches.first.confidence * 0.3;
      }
    }

    if (_fallbackItems.any((item) => cleaned == item)) return 0.9;
    if (_fallbackItems.any((item) => cleaned.contains(item))) return 0.7;
    if (_fallbackItems.any((item) => _similarity(cleaned.split(' ').first, item) > 0.8)) return 0.6;

    return 0.4;
  }

  bool _looksLikeQuantity(String line, double number) {
    final cleaned = line.toLowerCase();
    for (final word in _quantityWords) {
      if (cleaned.contains(word)) return true;
    }
    return number <= 100 && number == number.roundToDouble();
  }

  bool _looksLikeRate(String line, double number) {
    return line.contains(RegExp(r'[₹Rs$]')) || number > 100;
  }

  void _detectDuplicates(List<ParsedItem> items, List<String> warnings) {
    final nameCount = <String, int>{};
    for (final item in items) {
      final key = item.name.toLowerCase();
      nameCount[key] = (nameCount[key] ?? 0) + 1;
    }
    for (final entry in nameCount.entries) {
      if (entry.value > 1) {
        warnings.add('Duplicate item detected: ${_capitalize(entry.key)} appears ${entry.value} times');
      }
    }
  }

  void _validateAmounts(List<ParsedItem> items, List<String> warnings) {
    for (final item in items) {
      if (item.amountMismatch) {
        warnings.add('Amount mismatch for ${item.name}: calculated ${item.calculatedAmount!.toStringAsFixed(2)}, provided ${item.amount!.toStringAsFixed(2)}');
      }
    }
  }

  double _calculateOverallConfidence(List<ParsedItem> items) {
    if (items.isEmpty) return 0.0;
    var sum = 0.0;
    var count = 0;
    for (final item in items) {
      if (!item.isInvalid) {
        sum += item.overallConfidence;
        count++;
      }
    }
    return count > 0 ? sum / count : 0.3;
  }

  double _similarity(String a, String b) {
    if (a.isEmpty || b.isEmpty) return 0.0;
    final maxLen = math.max(a.length, b.length);
    if (maxLen == 0) return 1.0;
    return 1.0 - _levenshtein(a, b) / maxLen;
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
        curr[j + 1] = math.min(math.min(curr[j] + 1, prev[j + 1] + 1), prev[j] + cost);
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

class _ItemResult {
  final String itemName;
  final String? matchedProductId;
  _ItemResult(this.itemName, this.matchedProductId);
}
