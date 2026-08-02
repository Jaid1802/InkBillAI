import 'dart:math' as math;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:inkbill_ai/services/recognition/recognition_logger.dart';

class ProductRecord {
  final String productName;
  final double price;
  final String? unit;
  final int frequency;

  const ProductRecord({
    required this.productName,
    required this.price,
    this.unit,
    this.frequency = 0,
  });
}

class PriceSuggestion {
  final double price;
  final double confidence;

  const PriceSuggestion({
    required this.price,
    required this.confidence,
  });
}

class ShopMemory {
  final List<ProductRecord> _products = [];
  final Map<String, int> _frequency = {};

  void addProduct({
    required String productName,
    required double price,
    String? unit,
  }) {
    _products.add(ProductRecord(
      productName: productName,
      price: price,
      unit: unit,
    ));
  }

  ProductRecord? findBestMatch(String query) {
    if (query.isEmpty || _products.isEmpty) return null;

    final lower = query.toLowerCase().trim();
    ProductRecord? bestMatch;
    double bestScore = 0;

    for (final product in _products) {
      final nameLower = product.productName.toLowerCase();
      double score = _similarity(lower, nameLower);

      final freq = _frequency[product.productName] ?? 0;
      score += math.min(freq * 0.02, 0.1);

      if (score > bestScore) {
        bestScore = score;
        bestMatch = product;
      }
    }

    return bestScore > 0.5 ? bestMatch : null;
  }

  PriceSuggestion? suggestPrice(String productName) {
    final match = findBestMatch(productName);
    if (match == null) return null;

    return PriceSuggestion(
      price: match.price,
      confidence: match.frequency > 0 ? 0.8 : 0.6,
    );
  }

  Future<void> recordPurchase(String productName) async {
    _frequency[productName] = (_frequency[productName] ?? 0) + 1;
    final prefs = await SharedPreferences.getInstance();
    final data = _frequency.entries
        .map((e) => '${e.key}:${e.value}')
        .toList();
    await prefs.setStringList('ai_shop_frequency', data);
    RecognitionLogger.log('ShopMemory: recorded purchase of $productName');
  }

  Future<void> loadFromPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getStringList('ai_shop_frequency') ?? [];
    for (final entry in data) {
      final parts = entry.split(':');
      if (parts.length == 2) {
        _frequency[parts[0]] = int.tryParse(parts[1]) ?? 0;
      }
    }
  }

  void loadFromProductList(List<ProductRecord> products) {
    _products.clear();
    _products.addAll(products);
  }

  double _similarity(String a, String b) {
    if (a.isEmpty || b.isEmpty) return 0.0;

    if (a == b) return 1.0;
    if (b.startsWith(a) || a.startsWith(b)) return 0.85;
    if (b.contains(a) || a.contains(b)) return 0.7;

    final wordsA = a.split(RegExp(r'[\s/]+'));
    final wordsB = b.split(RegExp(r'[\s/]+'));

    for (final wa in wordsA) {
      for (final wb in wordsB) {
        if (wa == wb) return 0.8;
        if (wa.length > 2 && wb.length > 2 && (wb.startsWith(wa) || wa.startsWith(wb))) {
          return 0.7;
        }
        final sim = _levenshteinSimilarity(wa, wb);
        if (sim > 0.7) return sim * 0.85;
      }
    }

    return _levenshteinSimilarity(a, b);
  }

  double _levenshteinSimilarity(String a, String b) {
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
}
