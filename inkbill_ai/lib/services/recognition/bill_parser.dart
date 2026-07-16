import 'dart:math' as math;
import 'package:inkbill_ai/features/ai/domain/entities/recognition_result.dart';

class ParsedItem {
  final String name;
  final double? quantity;
  final double? rate;
  final double? amount;
  final double nameConfidence;
  final double quantityConfidence;
  final double rateConfidence;
  final double amountConfidence;

  const ParsedItem({
    required this.name,
    this.quantity,
    this.rate,
    this.amount,
    this.nameConfidence = 0.0,
    this.quantityConfidence = 0.0,
    this.rateConfidence = 0.0,
    this.amountConfidence = 0.0,
  });

  double get overallConfidence {
    double sum = nameConfidence;
    int count = 1;
    if (quantity != null) {
      sum += quantityConfidence;
      count++;
    }
    if (rate != null) {
      sum += rateConfidence;
      count++;
    }
    if (amount != null) {
      sum += amountConfidence;
      count++;
    }
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

  Map<String, dynamic> toJson() => {
        'name': name,
        'quantity': quantity,
        'rate': rate,
        'amount': amount,
        'nameConfidence': nameConfidence,
        'quantityConfidence': quantityConfidence,
        'rateConfidence': rateConfidence,
        'amountConfidence': amountConfidence,
      };
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
  static const _knownItems = <String>{
    'tea', 'chai', 'coffee', 'milk', 'bread', 'butter', 'eggs', 'sugar',
    'rice', 'wheat', 'daal', 'pulses', 'oil', 'salt', 'spices', 'turmeric',
    'chilli', 'chili', 'onion', 'potato', 'tomato', 'ginger', 'garlic',
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

    final itemName = _extractItemName(line);
    if (itemName == null) return null;

    final numbers = _extractNumbers(line);
    final nameConfidence = _nameConfidence(itemName, line);

    double? quantity;
    double? rate;
    double? amount;
    double quantityConf = 0.0;
    double rateConf = 0.0;
    double amountConf = 0.0;

    if (numbers.length == 1) {
      if (_looksLikeQuantity(line, numbers[0])) {
        quantity = numbers[0];
        quantityConf = 0.6;
        rateConf = 0.3;
      } else if (_looksLikeRate(line, numbers[0])) {
        rate = numbers[0];
        rateConf = 0.6;
        quantityConf = 0.3;
      } else {
        quantity = numbers[0];
        quantityConf = 0.5;
      }
    } else if (numbers.length >= 2) {
      final firstIsQty = _isFirstNumberQuantity(allLines, index, numbers);
      if (firstIsQty) {
        quantity = numbers[0];
        rate = numbers[1];
        quantityConf = 0.8;
        rateConf = 0.8;
        if (numbers.length >= 3) {
          amount = numbers[2];
          amountConf = 0.7;
        }
      } else {
        rate = numbers[0];
        amount = numbers[1];
        rateConf = 0.7;
        amountConf = 0.6;
      }
    }

    if (amount == null && quantity != null && rate != null) {
      amount = quantity * rate;
      amountConf = math.min(quantityConf, rateConf) * 0.9;
    }

    final hasEnoughInfo =
        itemName.isNotEmpty &&
        nameConfidence > 0.3 &&
        (quantity != null || rate != null);

    if (!hasEnoughInfo) {
      return ParsedItem(
        name: 'Unknown Item',
        nameConfidence: nameConfidence,
        quantityConfidence: quantityConf,
        rateConfidence: rateConf,
        amountConfidence: amountConf,
      );
    }

    return ParsedItem(
      name: itemName,
      quantity: quantity,
      rate: rate,
      amount: amount,
      nameConfidence: nameConfidence,
      quantityConfidence: quantityConf,
      rateConfidence: rateConf,
      amountConfidence: amountConf,
    );
  }

  String? _extractItemName(String line) {
    final cleaned = _cleanText(line);

    if (cleaned.isEmpty) return null;

    final item =
        _knownItems.firstWhere(
          (item) =>
              cleaned.contains(item) ||
              _levenshteinSimilar(cleaned.split(' ').first, item) > 0.75,
          orElse: () => '',
        );

    if (item.isNotEmpty) return _capitalize(item);

    final firstWord = cleaned.split(' ').first;
    if (firstWord.length >= 3 && !_isNumeric(firstWord)) {
      return _capitalize(firstWord);
    }

    return null;
  }

  String _cleanText(String text) {
    return text
        .toLowerCase()
        .replaceAll(RegExp(r'[0-9\s\.,/-]+'), ' ')
        .trim();
  }

  bool _isNumeric(String s) {
    return double.tryParse(s) != null;
  }

  List<double> _extractNumbers(String line) {
    final matches = RegExp(r'(\d+\.?\d*)').allMatches(line);
    return matches.map((m) => double.tryParse(m.group(1)!) ?? 0.0).toList();
  }

  double _nameConfidence(String name, String originalLine) {
    final cleaned = _cleanText(originalLine);
    final nameLower = name.toLowerCase();

    if (_knownItems.any((item) =>
        cleaned.contains(item) && item == nameLower)) {
      return 0.9;
    }

    final firstWord = cleaned.split(' ').first;
    for (final item in _knownItems) {
      if (_levenshteinSimilar(firstWord, item) > 0.8) {
        return 0.7;
      }
    }

    if (_knownItems.any((item) => cleaned.contains(item))) {
      return 0.6;
    }

    return 0.4;
  }

  bool _looksLikeQuantity(String line, double number) {
    final cleaned = line.toLowerCase();
    for (final word in _quantityWords) {
      if (cleaned.contains(word)) return true;
    }
    return number <= 100 && number == (number).roundToDouble();
  }

  bool _looksLikeRate(String line, double number) {
    return line.contains(RegExp(r'[₹Rs$]')) || number > 100;
  }

  bool _isFirstNumberQuantity(
      List<String> allLines, int index, List<double> numbers) {
    if (allLines.length <= 1) {
      return numbers[0] <= 20 && numbers[0] == numbers[0].roundToDouble();
    }

    if (index > 1 && index < allLines.length - 1) {
      final prevLine = allLines[index - 1];
      if (prevLine.isNotEmpty && !RegExp(r'\d').hasMatch(prevLine)) {
        return true;
      }
    }

    return numbers[0] <= 20 && numbers[0] == numbers[0].roundToDouble();
  }

  void _detectDuplicates(List<ParsedItem> items, List<String> warnings) {
    final nameCount = <String, int>{};
    for (final item in items) {
      final key = item.name.toLowerCase();
      nameCount[key] = (nameCount[key] ?? 0) + 1;
    }
    for (final entry in nameCount.entries) {
      if (entry.value > 1) {
        warnings.add(
            'Duplicate item detected: ${_capitalize(entry.key)} appears ${entry.value} times');
      }
    }
  }

  void _validateAmounts(List<ParsedItem> items, List<String> warnings) {
    for (final item in items) {
      if (item.amountMismatch) {
        warnings.add(
            'Amount mismatch for ${item.name}: calculated ${item.calculatedAmount!.toStringAsFixed(2)}, provided ${item.amount!.toStringAsFixed(2)}');
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

  double _levenshteinSimilar(String a, String b) {
    if (a.isEmpty || b.isEmpty) return 0.0;
    final distance = _levenshtein(a, b);
    final maxLen = math.max(a.length, b.length);
    return maxLen > 0 ? 1.0 - distance / maxLen : 1.0;
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
