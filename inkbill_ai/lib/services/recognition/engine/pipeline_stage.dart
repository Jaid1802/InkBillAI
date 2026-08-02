import 'dart:async';

abstract class PipelineStage<I, O> {
  final String name;

  const PipelineStage(this.name);

  Future<O> execute(I input, {CancellationToken? cancellationToken});
}

class CancellationToken {
  bool _isCancelled = false;
  bool get isCancelled => _isCancelled;

  void cancel() {
    _isCancelled = true;
  }

  void throwIfCancelled() {
    if (_isCancelled) {
      throw CancellationException('Operation cancelled');
    }
  }
}

class CancellationException implements Exception {
  final String message;
  CancellationException(this.message);

  @override
  String toString() => message;
}
