import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:inkbill_ai/core/theme/app_theme.dart';
import 'package:inkbill_ai/features/auth/presentation/pages/login_page.dart';
import 'package:inkbill_ai/features/auth/presentation/providers/auth_provider.dart';
import 'package:inkbill_ai/features/auth/domain/entities/auth_user.dart';
import 'package:inkbill_ai/widgets/shared/app_shell.dart';

class InkBillApp extends ConsumerWidget {
  const InkBillApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateProvider);

    return MaterialApp(
      title: 'InkBill AI',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.light,
      home: _buildHome(authState),
    );
  }

  Widget _buildHome(AuthState authState) {
    if (authState.isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (!authState.isAuthenticated && !authState.isGuest) {
      return const LoginPage();
    }

    return const AppShell();
  }
}
