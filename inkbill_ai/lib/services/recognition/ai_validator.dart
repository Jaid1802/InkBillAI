import 'package:inkbill_ai/features/ai/domain/entities/recognition_result.dart';
import 'package:inkbill_ai/services/recognition/bill_parser.dart';

enum ValidationSeverity { error, warning, info }

class ValidationIssue {
  final String field;
  final String message;
  final ValidationSeverity severity;
  final int? itemIndex;

  const ValidationIssue({
    required this.field,
    required this.message,
    this.severity = ValidationSeverity.warning,
    this.itemIndex,
  });

  Map<String, dynamic> toJson() => {
        'field': field,
        'message': message,
        'severity': severity.name,
        'itemIndex': itemIndex,
      };
}

class ValidationResult {
  final List<ValidationIssue> issues;
  final double overallConfidence;
  final bool isTrusted;

  const ValidationResult({
    this.issues = const [],
    this.overallConfidence = 0.0,
    this.isTrusted = false,
  });

  List<ValidationIssue> get errors =>
      issues.where((i) => i.severity == ValidationSeverity.error).toList();

  List<ValidationIssue> get warnings =>
      issues.where((i) => i.severity == ValidationSeverity.warning).toList();

  List<ValidationIssue> get infos =>
      issues.where((i) => i.severity == ValidationSeverity.info).toList();
}

class AIValidator {
  ValidationResult validate(BillParseResult parseResult) {
    final issues = <ValidationIssue>[];

    for (var i = 0; i < parseResult.items.length; i++) {
      final item = parseResult.items[i];
      _validateItem(item, i, issues);
    }

    _validateOverall(parseResult, issues);

    final overallConfidence = _computeOverallConfidence(
      parseResult,
      issues,
    );

    return ValidationResult(
      issues: issues,
      overallConfidence: overallConfidence,
      isTrusted: overallConfidence >= 0.7 && issues.isEmpty,
    );
  }

  void _validateItem(ParsedItem item, int index, List<ValidationIssue> issues) {
    if (item.nameConfidence < 0.5 || item.name == 'Unknown Item') {
      issues.add(ValidationIssue(
        field: 'name',
        message: 'Item name has low confidence, verify manually',
        severity: ValidationSeverity.error,
        itemIndex: index,
      ));
    }

    if (item.nameConfidence < 0.7 && item.nameConfidence >= 0.5) {
      issues.add(ValidationIssue(
        field: 'name',
        message: 'Item name may be incorrect (confidence: ${(item.nameConfidence * 100).round()}%)',
        severity: ValidationSeverity.warning,
        itemIndex: index,
      ));
    }

    if (item.isMissingQuantity) {
      issues.add(ValidationIssue(
        field: 'quantity',
        message: 'Missing quantity for ${item.name}',
        severity: ValidationSeverity.error,
        itemIndex: index,
      ));
    }

    if (item.quantity != null && item.quantityConfidence < 0.6) {
      issues.add(ValidationIssue(
        field: 'quantity',
        message: 'Quantity may be incorrect (${item.quantity})',
        severity: ValidationSeverity.warning,
        itemIndex: index,
      ));
    }

    if (item.isMissingRate) {
      issues.add(ValidationIssue(
        field: 'rate',
        message: 'Missing rate for ${item.name}',
        severity: ValidationSeverity.error,
        itemIndex: index,
      ));
    }

    if (item.rate != null && item.rateConfidence < 0.6) {
      issues.add(ValidationIssue(
        field: 'rate',
        message: 'Rate may be incorrect (${item.rate})',
        severity: ValidationSeverity.warning,
        itemIndex: index,
      ));
    }

    if (item.amountMismatch) {
      issues.add(ValidationIssue(
        field: 'amount',
        message: 'Total mismatch for ${item.name}: '
            'entered ${item.amount!.toStringAsFixed(2)}, '
            'should be ${item.calculatedAmount!.toStringAsFixed(2)}',
        severity: ValidationSeverity.error,
        itemIndex: index,
      ));
    }

    if (item.amount != null &&
        item.amountConfidence < 0.6 &&
        !item.amountMismatch) {
      issues.add(ValidationIssue(
        field: 'amount',
        message: 'Total may be incorrect (${item.amount})',
        severity: ValidationSeverity.warning,
        itemIndex: index,
      ));
    }
  }

  void _validateOverall(BillParseResult result, List<ValidationIssue> issues) {
    if (result.items.isEmpty) {
      issues.add(const ValidationIssue(
        field: 'general',
        message: 'No items were parsed from the handwritten content',
        severity: ValidationSeverity.error,
      ));
      return;
    }

    if (result.warnings.isNotEmpty) {
      for (final warning in result.warnings) {
        if (warning.contains('Duplicate')) {
          issues.add(ValidationIssue(
            field: 'duplicate',
            message: warning,
            severity: ValidationSeverity.warning,
          ));
        } else if (warning.contains('mismatch') || warning.contains('Mismatch')) {
          issues.add(ValidationIssue(
            field: 'amount',
            message: warning,
            severity: ValidationSeverity.error,
          ));
        }
      }
    }

    if (result.overallConfidence < 0.5) {
      issues.add(const ValidationIssue(
        field: 'general',
        message: 'Overall recognition confidence is low',
        severity: ValidationSeverity.warning,
      ));
    }

    final invalidItems = result.items.where((i) => i.isInvalid).length;
    if (invalidItems > result.items.length ~/ 2) {
      issues.add(const ValidationIssue(
        field: 'general',
        message: 'Most items could not be recognized clearly',
        severity: ValidationSeverity.error,
      ));
    }
  }

  double _computeOverallConfidence(
    BillParseResult parseResult,
    List<ValidationIssue> issues,
  ) {
    if (parseResult.items.isEmpty) return 0.0;

    final severityWeights = {
      ValidationSeverity.error: -0.15,
      ValidationSeverity.warning: -0.08,
      ValidationSeverity.info: -0.03,
    };

    double confidence = parseResult.overallConfidence;

    for (final issue in issues) {
      confidence += severityWeights[issue.severity] ?? 0.0;
    }

    return confidence.clamp(0.0, 1.0);
  }

  static String severityLabel(ValidationSeverity severity) {
    switch (severity) {
      case ValidationSeverity.error:
        return 'Error';
      case ValidationSeverity.warning:
        return 'Warning';
      case ValidationSeverity.info:
        return 'Info';
    }
  }
}
