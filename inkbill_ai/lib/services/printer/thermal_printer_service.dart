import 'package:inkbill_ai/core/utils/result.dart';
import 'package:inkbill_ai/core/errors/failures.dart';
import 'package:inkbill_ai/services/receipt_generator/receipt_generator.dart';

abstract class ThermalPrinterService {
  Future<Result<bool>> isConnected();
  Future<Result<void>> connect(String address);
  Future<Result<void>> disconnect();
  Future<Result<void>> printReceipt(ReceiptData data);
  Future<Result<void>> printText(String text);
  Future<Result<void>> printRaw(List<int> bytes);
}

class ThermalPrinterServiceImpl implements ThermalPrinterService {
  bool _connected = false;

  @override
  Future<Result<bool>> isConnected() async {
    return Result.success(_connected);
  }

  @override
  Future<Result<void>> connect(String address) async {
    try {
      _connected = true;
      return Result.success(null);
    } catch (e) {
      return Result.error(
          const StorageFailure(message: 'Failed to connect to printer'));
    }
  }

  @override
  Future<Result<void>> disconnect() async {
    _connected = false;
    return Result.success(null);
  }

  @override
  Future<Result<void>> printReceipt(ReceiptData data) async {
    if (!_connected) {
      return Result.error(
          const StorageFailure(message: 'Printer not connected'));
    }
    try {
      final text = ReceiptGenerator.generateTextReceipt(data);
      return printText(text);
    } catch (e) {
      return Result.error(
          const StorageFailure(message: 'Failed to print receipt'));
    }
  }

  @override
  Future<Result<void>> printText(String text) async {
    return Result.success(null);
  }

  @override
  Future<Result<void>> printRaw(List<int> bytes) async {
    return Result.success(null);
  }
}
