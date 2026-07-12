import 'package:inkbill_ai/features/handwriting/domain/entities/ink_stroke.dart';
import 'ink_engine.dart';

class InkEngineFactory {
  static InkEngine create(String pageId) {
    return InkEngine(pageId: pageId);
  }

  static InkEngine createWithStrokes(String pageId, List<InkStroke> strokes) {
    final engine = InkEngine(pageId: pageId);
    engine.loadStrokes(strokes);
    return engine;
  }
}
