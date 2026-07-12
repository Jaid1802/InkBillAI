import 'package:flutter_test/flutter_test.dart';
import 'package:inkbill_ai/core/utils/math_utils.dart';
import 'package:inkbill_ai/core/utils/result.dart';
import 'package:inkbill_ai/core/errors/failures.dart';

void main() {
  group('MathUtils', () {
    test('roundTo rounds correctly', () {
      expect(MathUtils.roundTo(1.2345, 2), 1.23);
      expect(MathUtils.roundTo(1.2355, 2), 1.24);
      expect(MathUtils.roundTo(1.0, 2), 1.0);
    });

    test('clampDouble clamps correctly', () {
      expect(MathUtils.clampDouble(5.0, 0.0, 10.0), 5.0);
      expect(MathUtils.clampDouble(-1.0, 0.0, 10.0), 0.0);
      expect(MathUtils.clampDouble(15.0, 0.0, 10.0), 10.0);
    });

    test('normalize works correctly', () {
      expect(MathUtils.normalize(5.0, 0.0, 10.0), 0.5);
      expect(MathUtils.normalize(0.0, 0.0, 10.0), 0.0);
      expect(MathUtils.normalize(10.0, 0.0, 10.0), 1.0);
    });

    test('calculateVelocity returns 0 for same point', () {
      expect(MathUtils.calculateVelocity(0, 0, 0, 0, 100), 0);
    });

    test('calculateVelocity returns positive for movement', () {
      final velocity = MathUtils.calculateVelocity(0, 0, 10, 10, 100);
      expect(velocity, greaterThan(0));
    });
  });

  group('Result', () {
    test('Success contains data', () {
      final result = Result<int>.success(42);
      expect(result.dataOrThrow, 42);
      expect(result.errorOrNull, isNull);
    });

    test('Error contains failure', () {
      final result = Result<int>.error(
          const ValidationFailure(message: 'test error'));
      expect(result.dataOrNull, isNull);
      expect(result.errorOrNull, isA<ValidationFailure>());
    });

    test('when on Success returns success value', () {
      final result = Result<int>.success(42);
      final output = result.when(
        success: (data) => 'Got $data',
        error: (f) => 'Error: ${f.message}',
      );
      expect(output, 'Got 42');
    });

    test('when on Error returns error value', () {
      final result = Result<int>.error(
          const ValidationFailure(message: 'fail'));
      final output = result.when(
        success: (data) => 'Got $data',
        error: (f) => 'Error: ${f.message}',
      );
      expect(output, 'Error: fail');
    });
  });
}
