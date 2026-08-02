import 'dart:typed_data';
import 'package:image/image.dart' as img;
import 'package:inkbill_ai/services/recognition/recognition_logger.dart';

class CropResult {
  final Uint8List croppedBytes;
  final int originalWidth;
  final int originalHeight;
  final int cropX, cropY, cropWidth, cropHeight;

  const CropResult({
    required this.croppedBytes,
    required this.originalWidth,
    required this.originalHeight,
    required this.cropX,
    required this.cropY,
    required this.cropWidth,
    required this.cropHeight,
  });

  double get cropRatio =>
      (cropWidth * cropHeight) / (originalWidth * originalHeight);
}

class CropHandler {
  static const double _paddingRatio = 0.02;
  static const int _contentThreshold = 10;

  CropResult cropToContent(Uint8List imageBytes) {
    final image = img.decodeImage(imageBytes);
    if (image == null) {
      RecognitionLogger.error('CropHandler', 'Failed to decode image');
      return CropResult(
        croppedBytes: imageBytes,
        originalWidth: 0,
        originalHeight: 0,
        cropX: 0, cropY: 0,
        cropWidth: 0, cropHeight: 0,
      );
    }

    final gray = img.grayscale(image);
    final w = gray.width;
    final h = gray.height;

    int minX = w, minY = h, maxX = 0, maxY = 0;
    bool hasContent = false;

    for (var y = 0; y < h; y++) {
      for (var x = 0; x < w; x++) {
        final pixel = gray.getPixel(x, y);
        final luminance = img.getLuminance(pixel);
        if (luminance < 255 - _contentThreshold) {
          if (x < minX) minX = x;
          if (y < minY) minY = y;
          if (x > maxX) maxX = x;
          if (y > maxY) maxY = y;
          hasContent = true;
        }
      }
    }

    if (!hasContent) {
      return CropResult(
        croppedBytes: imageBytes,
        originalWidth: w,
        originalHeight: h,
        cropX: 0, cropY: 0,
        cropWidth: w, cropHeight: h,
      );
    }

    final padX = (w * _paddingRatio).round().clamp(5, 50);
    final padY = (h * _paddingRatio).round().clamp(5, 50);

    minX = (minX - padX).clamp(0, w);
    minY = (minY - padY).clamp(0, h);
    maxX = (maxX + padX).clamp(0, w);
    maxY = (maxY + padY).clamp(0, h);

    final cropW = maxX - minX;
    final cropH = maxY - minY;

    if (cropW <= 0 || cropH <= 0) {
      return CropResult(
        croppedBytes: imageBytes,
        originalWidth: w,
        originalHeight: h,
        cropX: 0, cropY: 0,
        cropWidth: w, cropHeight: h,
      );
    }

    final cropped = img.copyCrop(image, x: minX, y: minY, width: cropW, height: cropH);
    final outputBytes = Uint8List.fromList(img.encodePng(cropped));

    RecognitionLogger.log(
        'Crop: ${w}x$h -> ${cropW}x$cropH (removed ${((1 - (cropW * cropH) / (w * h)) * 100).toStringAsFixed(0)}%)');

    return CropResult(
      croppedBytes: outputBytes,
      originalWidth: w,
      originalHeight: h,
      cropX: minX, cropY: minY,
      cropWidth: cropW, cropHeight: cropH,
    );
  }
}
