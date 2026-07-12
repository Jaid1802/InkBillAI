import 'package:equatable/equatable.dart';

abstract class Failure extends Equatable {
  final String message;
  final int? code;

  const Failure({required this.message, this.code});

  @override
  List<Object?> get props => [message, code];
}

class StorageFailure extends Failure {
  const StorageFailure({required super.message, super.code});
}

class DatabaseFailure extends Failure {
  const DatabaseFailure({required super.message, super.code});
}

class RecognitionFailure extends Failure {
  const RecognitionFailure({required super.message, super.code});
}

class InkCaptureFailure extends Failure {
  const InkCaptureFailure({required super.message, super.code});
}

class CalculationFailure extends Failure {
  const CalculationFailure({required super.message, super.code});
}

class ValidationFailure extends Failure {
  const ValidationFailure({required super.message, super.code});
}

class ExportFailure extends Failure {
  const ExportFailure({required super.message, super.code});
}

class NetworkFailure extends Failure {
  const NetworkFailure({required super.message, super.code});
}

class AuthFailure extends Failure {
  const AuthFailure({required super.message, super.code});
}
