// Basic Flutter widget test for InkBill AI.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:inkbill_ai/app/app.dart';

void main() {
  testWidgets('InkBillApp renders without crashing', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: InkBillApp(),
      ),
    );

    // Verify the app renders (MaterialApp is in the tree)
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
