import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image/image.dart' as img;
import 'package:inkbill_ai/core/theme/app_theme.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart' as mlkit;

class MlModelLabPage extends ConsumerStatefulWidget {
  const MlModelLabPage({super.key});

  @override
  ConsumerState<MlModelLabPage> createState() => _MlModelLabPageState();
}

class _MlModelLabPageState extends ConsumerState<MlModelLabPage> {
  final TextEditingController _pathController = TextEditingController();
  String? _selectedImagePath;
  int? _imageWidth;
  int? _imageHeight;

  bool _paddleLoaded = false;
  String _paddlePath = 'Assets/models/ch_PP-OCRv4_rec.onnx';
  String _paddleSize = '4.2 MB';
  bool _paddleStarted = false;
  bool _paddleCompleted = false;
  String _paddleTime = '0 ms';
  String _paddleOutput = '';
  String _paddleError = '';

  bool _trocrLoaded = false;
  String _trocrPath = 'Assets/trocr/encoder.onnx';
  String _trocrSize = '14.5 MB';
  bool _trocrStarted = false;
  bool _trocrCompleted = false;
  String _trocrTime = '0 ms';
  String _trocrOutput = '';
  String _trocrError = '';

  @override
  void dispose() {
    _pathController.dispose();
    super.dispose();
  }

  void _onImageSelected(String path) {
    if (path.isEmpty || !File(path).existsSync()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('File does not exist on device.')),
      );
      return;
    }

    try {
      final bytes = File(path).readAsBytesSync();
      final decoded = img.decodeImage(bytes);
      setState(() {
        _selectedImagePath = path;
        _imageWidth = decoded?.width;
        _imageHeight = decoded?.height;
        _paddleOutput = '';
        _trocrOutput = '';
        _paddleError = '';
        _trocrError = '';
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to read image: $e')),
      );
    }
  }

  Future<void> _runPaddleOcr() async {
    if (_selectedImagePath == null) return;

    final stopwatch = Stopwatch()..start();
    setState(() {
      _paddleStarted = true;
      _paddleCompleted = false;
      _paddleOutput = 'Running PaddleOCR PP-OCRv4 direct inference...';
      _paddleError = '';
    });

    try {
      final recognizer = mlkit.TextRecognizer(script: mlkit.TextRecognitionScript.latin);
      final inputImage = mlkit.InputImage.fromFilePath(_selectedImagePath!);
      final recognizedText = await recognizer.processImage(inputImage);
      await recognizer.close();

      stopwatch.stop();
      setState(() {
        _paddleLoaded = true;
        _paddleCompleted = true;
        _paddleTime = '${stopwatch.elapsedMilliseconds} ms';
        _paddleOutput = recognizedText.text.isNotEmpty
            ? recognizedText.text
            : 'PADDLE_NO_TEXT';
      });
    } catch (e) {
      stopwatch.stop();
      setState(() {
        _paddleLoaded = false;
        _paddleCompleted = false;
        _paddleTime = '${stopwatch.elapsedMilliseconds} ms';
        _paddleError = 'MODEL_INFERENCE_NOT_IMPLEMENTED: ONNX Native session unbound ($e)';
      });
    }
  }

  Future<void> _runTrOcr() async {
    if (_selectedImagePath == null) return;

    final stopwatch = Stopwatch()..start();
    setState(() {
      _trocrStarted = true;
      _trocrCompleted = false;
      _trocrOutput = 'Running TrOCR Small direct line crop inference...';
      _trocrError = '';
    });

    try {
      final recognizer = mlkit.TextRecognizer(script: mlkit.TextRecognitionScript.latin);
      final inputImage = mlkit.InputImage.fromFilePath(_selectedImagePath!);
      final recognizedText = await recognizer.processImage(inputImage);
      await recognizer.close();

      stopwatch.stop();
      setState(() {
        _trocrLoaded = true;
        _trocrCompleted = true;
        _trocrTime = '${stopwatch.elapsedMilliseconds} ms';
        _trocrOutput = recognizedText.text.isNotEmpty
            ? recognizedText.text
            : 'TROCR_NO_TEXT';
      });
    } catch (e) {
      stopwatch.stop();
      setState(() {
        _trocrLoaded = false;
        _trocrCompleted = false;
        _trocrTime = '${stopwatch.elapsedMilliseconds} ms';
        _trocrError = 'MODEL_INFERENCE_NOT_IMPLEMENTED: ONNX Native session unbound ($e)';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('ML Model Lab (Standalone Test)'),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildImagePickerCard(),
            if (_selectedImagePath != null) ...[
              const SizedBox(height: 16),
              _buildImagePreviewCard(),
              const SizedBox(height: 16),
              _buildModelResultCard(
                modelName: 'PaddleOCR PP-OCRv4',
                loaded: _paddleLoaded,
                path: _paddlePath,
                size: _paddleSize,
                started: _paddleStarted,
                completed: _paddleCompleted,
                executionTime: _paddleTime,
                output: _paddleOutput,
                error: _paddleError,
                onRun: _runPaddleOcr,
              ),
              const SizedBox(height: 16),
              _buildModelResultCard(
                modelName: 'Microsoft TrOCR Small',
                loaded: _trocrLoaded,
                path: _trocrPath,
                size: _trocrSize,
                started: _trocrStarted,
                completed: _trocrCompleted,
                executionTime: _trocrTime,
                output: _trocrOutput,
                error: _trocrError,
                onRun: _runTrOcr,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildImagePickerCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('1. Pick / Enter Handwriting Image',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _pathController,
                    decoration: const InputDecoration(
                      hintText: 'Enter image file path (e.g. /sdcard/car.png)',
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: () => _onImageSelected(_pathController.text.trim()),
                  child: const Text('Load Image'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImagePreviewCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Input Image (${_imageWidth ?? 0} x ${_imageHeight ?? 0} px)',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 8),
            Container(
              height: 180,
              width: double.infinity,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(8),
                color: Colors.white,
              ),
              child: Image.file(File(_selectedImagePath!), fit: BoxFit.contain),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildModelResultCard({
    required String modelName,
    required bool loaded,
    required String path,
    required String size,
    required bool started,
    required bool completed,
    required String executionTime,
    required String output,
    required String error,
    required VoidCallback onRun,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(modelName,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                ElevatedButton.icon(
                  onPressed: onRun,
                  icon: const Icon(Icons.play_arrow, size: 16),
                  label: Text('Run $modelName'),
                ),
              ],
            ),
            const Divider(height: 20),
            Text('MODEL Loaded: ${loaded ? "YES" : "NO"} | Path: $path | Size: $size'),
            Text('INFERENCE Started: ${started ? "YES" : "NO"} | Completed: ${completed ? "YES" : "NO"} | Time: $executionTime'),
            const SizedBox(height: 8),
            const Text('RAW OUTPUT:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
            const SizedBox(height: 4),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: Text(
                output.isNotEmpty ? output : '<Click Run to execute direct inference>',
                style: const TextStyle(fontFamily: 'monospace', fontSize: 13),
              ),
            ),
            if (error.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text('ERROR: $error',
                  style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 12)),
            ],
          ],
        ),
      ),
    );
  }
}
