import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:inkbill_ai/features/ai/presentation/providers/recognition_provider.dart';
import 'package:inkbill_ai/services/ai/models/model_manager.dart';
import 'package:inkbill_ai/services/recognition/benchmark/ocr_benchmark_system.dart';
import 'package:inkbill_ai/services/recognition/recognition_service.dart';

class DeveloperDashboardPage extends ConsumerWidget {
  const DeveloperDashboardPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final benchmark = OcrBenchmarkSystem();
    final modelManager = ModelManager();
    final service = ref.watch(recognitionServiceProvider);
    final latest = benchmark.latest;
    final models = modelManager.getRegisteredModels();

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        title: const Text('Developer Mode - OCR Engine Dashboard'),
        backgroundColor: const Color(0xFF1E293B),
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildMetricsGrid(service, latest, modelManager),
            const SizedBox(height: 16),
            _buildLoadedModelsCard(models),
            const SizedBox(height: 16),
            _buildBenchmarkHistoryCard(benchmark),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricsGrid(RecognitionService service, BenchmarkMetricEntry? latest, ModelManager modelManager) {
    return Card(
      color: const Color(0xFF1E293B),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('LIVE SYSTEM METRICS', style: TextStyle(color: Colors.greenAccent, fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(child: _metricTile('Active OCR Engine', service.activeEngineName, Colors.amberAccent)),
                Expanded(child: _metricTile('ONNX Runtime', 'v1.17.0 (Offline)', Colors.lightBlueAccent)),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(child: _metricTile('Total Inferences', '${OcrBenchmarkSystem().history.length}', Colors.white)),
                Expanded(child: _metricTile('RAM Usage', '${modelManager.memoryUsageMb.toStringAsFixed(1)} MB', Colors.lightGreenAccent)),
              ],
            ),
            if (latest != null) ...[
              const Divider(color: Colors.white24, height: 24),
              Row(
                children: [
                  Expanded(child: _metricTile('Detection Time', '${latest.detectionTimeMs} ms', Colors.orangeAccent)),
                  Expanded(child: _metricTile('Recognition Time', '${latest.recognitionTimeMs} ms', Colors.cyanAccent)),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(child: _metricTile('Total Latency', '${latest.totalTimeMs} ms', Colors.lightGreenAccent)),
                  Expanded(child: _metricTile('Bounding Boxes', '${latest.boundingBoxesCount}', Colors.purpleAccent)),
                ],
              ),
            ]
          ],
        ),
      ),
    );
  }

  Widget _metricTile(String label, String value, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: Colors.white70, fontSize: 12)),
        const SizedBox(height: 2),
        Text(value, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 15)),
      ],
    );
  }

  Widget _buildLoadedModelsCard(List<ModelInfo> models) {
    return Card(
      color: const Color(0xFF1E293B),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('REGISTERED ONNX MODELS', style: TextStyle(color: Colors.cyanAccent, fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 12),
            ...models.map((m) => ListTile(
              dense: true,
              leading: Icon(m.isLoaded ? Icons.check_circle : Icons.offline_pin, color: m.isLoaded ? Colors.green : Colors.grey),
              title: Text(m.name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              subtitle: Text('Version: ${m.version} | Path: ${m.relativePath}', style: const TextStyle(color: Colors.white70, fontSize: 11)),
              trailing: Text('${(m.sizeBytes / (1024 * 1024)).toStringAsFixed(1)} MB', style: const TextStyle(color: Colors.amberAccent, fontSize: 12)),
            )),
          ],
        ),
      ),
    );
  }

  Widget _buildBenchmarkHistoryCard(OcrBenchmarkSystem benchmark) {
    final history = benchmark.history.reversed.toList();
    return Card(
      color: const Color(0xFF1E293B),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('BENCHMARK HISTORY LOGS', style: TextStyle(color: Colors.amberAccent, fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 12),
            if (history.isEmpty)
              const Text('No benchmark runs recorded yet.', style: TextStyle(color: Colors.white54))
            else
              ...history.take(10).map((h) => ListTile(
                dense: true,
                title: Text('${h.engineName} - ${h.totalTimeMs}ms', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                subtitle: Text('Det: ${h.detectionTimeMs}ms | Rec: ${h.recognitionTimeMs}ms | Boxes: ${h.boundingBoxesCount} | Conf: ${(h.confidence * 100).toInt()}%', style: const TextStyle(color: Colors.white70, fontSize: 11)),
                trailing: Text('${h.charCount} chars', style: const TextStyle(color: Colors.greenAccent, fontSize: 12)),
              )),
          ],
        ),
      ),
    );
  }
}
