import 'package:inkbill_ai/services/ai/shop_memory/shop_memory.dart';
import 'package:inkbill_ai/services/recognition/recognition_logger.dart';

class ParsedBillItem {
  final String originalText;
  String itemName;
  double? quantity;
  double? rate;
  double? amount;
  double confidence;
  double nameConfidence;
  double quantityConfidence;
  double rateConfidence;
  List<String> warnings;

  ParsedBillItem({
    required this.originalText,
    this.itemName = '',
    this.quantity,
    this.rate,
    this.amount,
    this.confidence = 0.0,
    this.nameConfidence = 0.0,
    this.quantityConfidence = 0.0,
    this.rateConfidence = 0.0,
    this.warnings = const [],
  });

  double? get calculatedAmount {
    if (quantity != null && rate != null) {
      return quantity! * rate!;
    }
    return amount;
  }

  bool get isComplete =>
      itemName.isNotEmpty && quantity != null && rate != null;
  bool get isValid => itemName.isNotEmpty || quantity != null || rate != null;
}

class BillParseResult {
  final List<ParsedBillItem> items;
  final double overallConfidence;
  final List<String> warnings;
  final double? total;
  final double? calculatedTotal;

  const BillParseResult({
    this.items = const [],
    this.overallConfidence = 0.0,
    this.warnings = const [],
    this.total,
    this.calculatedTotal,
  });
}

class BillParser {
  final ShopMemory? _shopMemory;

  const BillParser({ShopMemory? shopMemory}) : _shopMemory = shopMemory;

  static const _quantitySuffixes = [
    'kg', 'g', 'l', 'ml', 'pcs', 'pack', 'packet', 'dozen', 'dz', 'box', 'bottle', 'bag',
  ];

  BillParseResult parse(List<ParsedBillItem> rawItems) {
    final startTime = DateTime.now();
    RecognitionLogger.stage('BILL_PARSER', 'Parsing ${rawItems.length} items');

    final items = <ParsedBillItem>[];
    final warnings = <String>[];
    double calculatedTotal = 0;

    for (var i = 0; i < rawItems.length; i++) {
      final parsed = _parseSingleItem(rawItems[i], i, warnings);
      if (parsed.isValid) {
        items.add(parsed);
        if (parsed.calculatedAmount != null) {
          calculatedTotal += parsed.calculatedAmount!;
        }
      }
    }

    _validateItemNames(items, warnings);
    _detectDuplicates(items, warnings);
    _validatePrices(items, warnings);

    final overallConfidence = _computeOverallConfidence(items);

    final elapsed = DateTime.now().difference(startTime).inMilliseconds;
    RecognitionLogger.stage(
        'BILL_PARSER',
        'Parsed ${items.length} items in ${elapsed}ms, '
        'confidence: ${overallConfidence.toStringAsFixed(2)}');

    return BillParseResult(
      items: items,
      overallConfidence: overallConfidence,
      warnings: warnings,
      calculatedTotal: calculatedTotal,
    );
  }

  ParsedBillItem _parseSingleItem(ParsedBillItem raw, int index, List<String> warnings) {
    final text = raw.originalText.trim();
    if (text.isEmpty) {
      return ParsedBillItem(
        originalText: '',
        warnings: ['Line ${index + 1}: empty'],
      );
    }

    final corrected = _matchProductName(raw.itemName);
    final itemName = corrected ?? raw.itemName;
    final nameConf = corrected != null ? 0.85 : raw.nameConfidence;

    double? quantity = raw.quantity;
    double? rate = raw.rate;
    double qtyConf = raw.quantityConfidence;
    double rateConf = raw.rateConfidence;
    final warnings = <String>[];

    if (quantity == null && rate == null) {
      final extracted = _extractQuantityAndRate(text);
      quantity = extracted['quantity'];
      rate = extracted['rate'];
      qtyConf = extracted['quantityConfidence'];
      rateConf = extracted['rateConfidence'];
    }

    if (itemName.isEmpty && quantity == null && rate == null) {
      warnings.add('Line ${index + 1}: could not extract any fields');
    }

    double? amount;
    if (quantity != null && rate != null) {
      amount = quantity * rate;
    }

    final overallConf = (nameConf + qtyConf + rateConf) / 3.0;

    return ParsedBillItem(
      originalText: text,
      itemName: itemName,
      quantity: quantity,
      rate: rate,
      amount: amount,
      confidence: overallConf,
      nameConfidence: nameConf,
      quantityConfidence: qtyConf,
      rateConfidence: rateConf,
      warnings: warnings,
    );
  }

  String? _matchProductName(String name) {
    if (name.isEmpty || _shopMemory == null) return null;
    final match = _shopMemory!.findBestMatch(name);
    return match != null ? match.productName : null;
  }

  Map<String, dynamic> _extractQuantityAndRate(String text) {
    double? quantity;
    double? rate;
    double qtyConf = 0.0;
    double rateConf = 0.0;

    final lower = text.toLowerCase();

    for (final suffix in _quantitySuffixes) {
      final pattern = RegExp(r'(\d+\.?\d*)\s*' + suffix);
      final match = pattern.firstMatch(lower);
      if (match != null) {
        quantity = double.tryParse(match.group(1)!);
        qtyConf = 0.7;
        break;
      }
    }

    final numbers = RegExp(r'(\d+\.?\d*)').allMatches(text).toList();
    final parsedNumbers = numbers
        .map((m) => double.tryParse(m.group(1)!))
        .where((n) => n != null)
        .cast<double>()
        .toList();

    if (quantity == null && parsedNumbers.isNotEmpty) {
      final firstNum = parsedNumbers.first;
      if (firstNum <= 100 && firstNum == firstNum.roundToDouble()) {
        quantity = firstNum;
        qtyConf = 0.5;
        if (parsedNumbers.length > 1) {
          rate = parsedNumbers[1];
          rateConf = 0.5;
        }
      } else if (parsedNumbers.length >= 2) {
        rate = parsedNumbers[0];
        quantity = parsedNumbers[1];
        qtyConf = 0.5;
        rateConf = 0.5;
      } else {
        rate = firstNum;
        rateConf = 0.5;
      }
    } else if (quantity != null && parsedNumbers.length >= 2) {
      final remaining = parsedNumbers.where((n) => n != quantity).toList();
      if (remaining.isNotEmpty) {
        rate = remaining.first;
        rateConf = 0.6;
      }
    }

    final hasRateIndicator = RegExp(r'[@₹Rs$/-]').hasMatch(text);
    if (hasRateIndicator && rate == null && parsedNumbers.isNotEmpty) {
      rate = parsedNumbers.last;
      rateConf = 0.5;
    }

    return {
      'quantity': quantity,
      'rate': rate,
      'quantityConfidence': qtyConf,
      'rateConfidence': rateConf,
    };
  }

  void _validateItemNames(List<ParsedBillItem> items, List<String> warnings) {
    for (var i = 0; i < items.length; i++) {
      if (items[i].itemName.isEmpty) {
        warnings.add('Item ${i + 1}: missing product name');
      } else if (items[i].nameConfidence < 0.4) {
        warnings.add(
            'Item ${i + 1}: "${items[i].itemName}" has low name confidence');
      }
    }
  }

  void _detectDuplicates(List<ParsedBillItem> items, List<String> warnings) {
    final nameCount = <String, int>{};
    for (final item in items) {
      if (item.itemName.isNotEmpty) {
        nameCount[item.itemName.toLowerCase()] =
            (nameCount[item.itemName.toLowerCase()] ?? 0) + 1;
      }
    }
    for (final entry in nameCount.entries) {
      if (entry.value > 1) {
        warnings.add(
            'Duplicate item: "${_capitalize(entry.key)}" appears ${entry.value} times');
      }
    }
  }

  void _validatePrices(List<ParsedBillItem> items, List<String> warnings) {
    for (var i = 0; i < items.length; i++) {
      final item = items[i];
      if (item.rate != null && _shopMemory != null) {
        final suggested = _shopMemory!.suggestPrice(item.itemName);
        if (suggested != null && suggested.price > 0) {
          final ratio = item.rate! / suggested.price;
          if (ratio > 3.0 || ratio < 0.3) {
            warnings.add(
                'Item ${i + 1}: rate ${item.rate} for "${item.itemName}" '
                'differs significantly from expected ${suggested.price}');
          }
        }
      }
    }
  }

  double _computeOverallConfidence(List<ParsedBillItem> items) {
    if (items.isEmpty) return 0.0;
    var sum = 0.0;
    var count = 0;
    for (final item in items) {
      if (item.isValid) {
        sum += item.confidence;
        count++;
      }
    }
    return count > 0 ? (sum / count).clamp(0.0, 1.0) : 0.3;
  }

  String _capitalize(String s) {
    if (s.isEmpty) return s;
    return s[0].toUpperCase() + s.substring(1);
  }
}
