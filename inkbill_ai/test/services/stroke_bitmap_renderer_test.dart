import 'dart:typed_data';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:scribble/scribble.dart';
import 'package:inkbill_ai/services/recognition/stroke_bitmap_renderer.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('plugins.flutter.io/path_provider'),
      (MethodCall methodCall) async {
        return '.';
      },
    );
  });

  test('StrokeBitmapRenderer.render executes and prints stroke count and PNG bytes', () async {
    final strokes = [
      const SketchLine(
        points: [Point(10, 10), Point(20, 20), Point(30, 40)],
        color: 0xFF000000,
        width: 3.0,
      ),
      const SketchLine(
        points: [Point(50, 50), Point(60, 70)],
        color: 0xFF000000,
        width: 3.0,
      ),
    ];

    final Uint8List? pngBytes = await StrokeBitmapRenderer.render(strokes);

    expect(pngBytes, isNotNull);
    expect(pngBytes!.length, greaterThan(0));

    print("====================");
    print("PNG Bytes: ${pngBytes.length}");
    print("====================");

    print("====================");
    print("OCR Input Size: ${pngBytes.length}");
    print("====================");
  });
}
