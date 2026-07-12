import 'package:inkbill_ai/features/handwriting/domain/entities/ink_stroke.dart';
import 'package:inkbill_ai/features/handwriting/domain/entities/ink_point.dart';

List<InkStroke> createSampleStrokes() {
  return [
    InkStroke(
      id: 'stroke_1',
      pageId: 'page_1',
      points: List.generate(50, (i) {
        return InkPoint(
          x: 100 + i * 2.0,
          y: 200 + (i % 10) * 3.0,
          pressure: 0.5 + (i / 100),
          tiltX: 0.1,
          tiltY: 0.05,
          timestampMs: i * 10,
          velocity: 2.0,
        );
      }),
      color: 0xFF212121,
      width: 3.0,
      createdAt: DateTime.now(),
    ),
    InkStroke(
      id: 'stroke_2',
      pageId: 'page_1',
      points: List.generate(30, (i) {
        return InkPoint(
          x: 200 + i * 3.0,
          y: 300 + (i % 8) * 4.0,
          pressure: 0.7,
          tiltX: 0.15,
          tiltY: 0.1,
          timestampMs: 500 + i * 12,
          velocity: 1.5,
        );
      }),
      color: 0xFF1565C0,
      width: 4.0,
      createdAt: DateTime.now(),
    ),
  ];
}

Map<String, dynamic> createSampleBillJson() {
  return {
    'id': 'bill_sample_001',
    'customerName': 'John Doe',
    'items': [
      {'id': 'item_1', 'name': 'Tea', 'quantity': 2, 'rate': 10, 'amount': 20},
      {'id': 'item_2', 'name': 'Coffee', 'quantity': 1, 'rate': 15, 'amount': 15},
      {'id': 'item_3', 'name': 'Sandwich', 'quantity': 1, 'rate': 45, 'amount': 45},
    ],
    'subtotal': 80,
    'taxRate': 0.18,
    'taxAmount': 14.4,
    'discount': 5,
    'total': 89.4,
    'status': 'draft',
  };
}
