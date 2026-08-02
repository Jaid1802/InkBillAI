import 'dart:typed_data';
import 'package:image/image.dart' as img;
import 'package:inkbill_ai/services/ai/preprocessing/crop_handler.dart';
import 'package:inkbill_ai/services/ai/preprocessing/noise_reducer.dart';
import 'package:inkbill_ai/services/ai/preprocessing/deskew_handler.dart';
import 'package:inkbill_ai/services/ai/preprocessing/line_segmenter.dart';
import 'package:inkbill_ai/services/ai/models/ai_model_interfaces.dart';
import 'package:inkbill_ai/services/recognition/recognition_logger.dart';

class PreprocessingResult {
  final Uint8List processedImage;
  final CropResult cropResult;
  final List<LineSegment> lines;
  final bool wasDeskewed;
  final Duration processingTime;

  const PreprocessingResult({
    required this.processedImage,
    required this.cropResult,
    this.lines = const [],
    this.wasDeskewed = false,
    this.processingTime = Duration.zero,
  });
}

class PreprocessingPipeline {
  final CropHandler _cropHandler = CropHandler();
  final NoiseReducer _noiseReducer = NoiseReducer();
  final DeskewHandler _deskewHandler = DeskewHandler();
  final LineSegmenter _lineSegmenter = LineSegmenter();

  static const double _maxDimension = 2048;

  PreprocessingResult process(Uint8List imageBytes) {
    final startTime = DateTime.now();
    RecognitionLogger.stage('PREPROCESS', 'Pipeline started');

    final resized = _resizeIfNeeded(imageBytes);

    final cropResult = _cropHandler.cropToContent(resized);

    final denoised = _noiseReducer.denoise(cropResult.croppedBytes);

    final deskewed = _deskewHandler.deskew(denoised);
    final wasDeskewed = deskewed != denoised;

    final lines = _lineSegmenter.segmentIntoLines(deskewed);

    final processingTime = DateTime.now().difference(startTime);
    RecognitionLogger.stage(
        'PREPROCESS',
        'Pipeline complete: ${lines.length} lines in ${processingTime.inMilliseconds}ms');

    return PreprocessingResult(
      processedImage: deskewed,
      cropResult: cropResult,
      lines: lines,
      wasDeskewed: wasDeskewed,
      processingTime: processingTime,
    );
  }

  Uint8List _resizeIfNeeded(Uint8List bytes) {
    final image = img.decodeImage(bytes);
    if (image == null) return bytes;

    int w = image.width;
    int h = image.height;

    if (w <= _maxDimension && h <= _maxDimension) return bytes;

    double scale;
    if (w > h) {
      scale = _maxDimension / w;
    } else {
      scale = _maxDimension / h;
    }

    final resized = img.copyResize(image,
        width: (w * scale).round(), height: (h * scale).round());
    RecognitionLogger.log(
        'Preprocess: resized ${w}x$h -> ${resized.width}x${resized.height}');

    return Uint8List.fromList(img.encodePng(resized));
  }
}
