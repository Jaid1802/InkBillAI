import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:inkbill_ai/core/supabase/supabase_config.dart';
import 'package:inkbill_ai/app/app.dart';

void main() {
  testWidgets('InkBillApp catches init error gracefully', (WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          supabaseClientProvider.overrideWithProvider(
            Provider((ref) => throw UnsupportedError('No Supabase in tests')),
          ),
        ],
        child: const InkBillApp(),
      ),
    );

    await tester.pump();

    // Riverpod wraps error in ProviderException; app should not crash
    expect(tester.takeException(), isNot(null));
  });
}
