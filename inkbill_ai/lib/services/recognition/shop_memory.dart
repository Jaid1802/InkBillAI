import 'dart:math' as math;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:inkbill_ai/features/products/domain/entities/product.dart';

class ProductMatch {
  final Product product;
  final double confidence;
  final String matchedName;

  const ProductMatch({
    required this.product,
    required this.confidence,
    required this.matchedName,
  });
}

class PriceSuggestion {
  final double price;
  final double confidence;
  final String source;

  const PriceSuggestion({
    required this.price,
    required this.confidence,
    required this.source,
  });
}

class ShopMemory {
  final List<Product> _products;
  final Map<String, int> _frequency = {};
  bool _loaded = false;

  ShopMemory() : _products = [];

  ShopMemory.withProducts(this._products) {
    _loaded = true;
  }

  bool get isLoaded => _loaded;
  int get productCount => _products.length;

  Future<void> loadProducts(List<Product> products) async {
    _products.clear();
    _products.addAll(products);
    _loaded = true;
    await _loadFrequency();
  }

  List<ProductMatch> findMatches(String query, {int maxResults = 5}) {
    if (query.isEmpty || !_loaded) return [];

    final lower = query.toLowerCase().trim();
    final scored = <_ScoredProduct>[];

    for (final product in _products) {
      final nameLower = product.name.toLowerCase();
      double score = 0;

      if (nameLower == lower) {
        score = 1.0;
      } else if (nameLower.startsWith(lower)) {
        score = 0.9 - (nameLower.length - lower.length) * 0.01;
      } else if (nameLower.contains(lower)) {
        score = 0.7;
      } else {
        final similarity = _similarity(lower, nameLower);
        if (similarity > 0.5) {
          score = similarity;
        } else {
          final words = nameLower.split(RegExp(r'[\s/]+'));
          for (final word in words) {
            final wordSim = _similarity(lower, word);
            if (wordSim > 0.6) {
              score = wordSim * 0.85;
              break;
            }
          }
        }
      }

      if (score > 0) {
        final freq = _frequency[product.id] ?? 0;
        final freqBoost = freq > 0 ? math.min(freq * 0.02, 0.1) : 0;
        scored.add(_ScoredProduct(product, score + freqBoost));
      }
    }

    scored.sort((a, b) => b.score.compareTo(a.score));
    return scored.take(maxResults).map((s) => ProductMatch(
      product: s.product,
      confidence: s.score.clamp(0.0, 1.0),
      matchedName: s.product.name,
    )).toList();
  }

  PriceSuggestion? suggestPrice(String productName) {
    if (!_loaded) return null;

    final matches = findMatches(productName, maxResults: 1);
    if (matches.isEmpty) return null;

    final match = matches.first;
    if (match.confidence < 0.4) return null;

    return PriceSuggestion(
      price: match.product.price,
      confidence: match.confidence,
      source: 'Product catalog',
    );
  }

  Future<void> recordPurchase(String productId) async {
    _frequency[productId] = (_frequency[productId] ?? 0) + 1;
    await _saveFrequency();
  }

  Future<void> recordCorrection(String original, String corrected) async {
    final prefs = await SharedPreferences.getInstance();
    final corrections = prefs.getStringList('ocr_corrections') ?? [];
    corrections.add('$original|$corrected');
    await prefs.setStringList('ocr_corrections', corrections);
  }

  Future<String?> findCorrection(String text) async {
    final prefs = await SharedPreferences.getInstance();
    final corrections = prefs.getStringList('ocr_corrections') ?? [];
    final lower = text.toLowerCase().trim();

    for (final entry in corrections) {
      final parts = entry.split('|');
      if (parts.length == 2 && parts[0].toLowerCase() == lower) {
        return parts[1];
      }
    }
    return null;
  }

  Future<void> _loadFrequency() async {
    final prefs = await SharedPreferences.getInstance();
    final freqData = prefs.getStringList('product_frequency') ?? [];
    for (final entry in freqData) {
      final parts = entry.split(':');
      if (parts.length == 2) {
        _frequency[parts[0]] = int.tryParse(parts[1]) ?? 0;
      }
    }
  }

  Future<void> _saveFrequency() async {
    final prefs = await SharedPreferences.getInstance();
    final data = _frequency.entries
        .map((e) => '${e.key}:${e.value}')
        .toList();
    await prefs.setStringList('product_frequency', data);
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

class _ScoredProduct {
  final Product product;
  final double score;
  _ScoredProduct(this.product, this.score);
}
