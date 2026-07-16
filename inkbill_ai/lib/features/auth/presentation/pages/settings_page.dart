import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:inkbill_ai/core/supabase/supabase_config.dart';
import 'package:inkbill_ai/features/auth/presentation/providers/auth_provider.dart';
import 'package:inkbill_ai/features/auth/presentation/pages/privacy_page.dart';
import 'package:inkbill_ai/core/database/database_provider.dart';
import 'package:inkbill_ai/features/auth/presentation/pages/terms_page.dart';
import 'package:share_plus/share_plus.dart';

class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Privacy & Security')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _SectionHeader(title: 'Information'),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.person),
                  title: Text(authState.user?.fullName ?? ''),
                  subtitle: Text(authState.user?.email ?? ''),
                ),
                if (authState.shop != null)
                  ListTile(
                    leading: const Icon(Icons.store),
                    title: Text(authState.shop!.shopName),
                    subtitle: const Text('Shop'),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          _SectionHeader(title: 'Account'),
          Card(
            child: Column(
              children: [
                if (!authState.isGuest)
                  ListTile(
                    leading: const Icon(Icons.lock_outline),
                    title: const Text('Change Password'),
                    onTap: () => _changePassword(context, ref),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          _SectionHeader(title: 'Privacy & Legal'),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.privacy_tip_outlined),
                  title: const Text('Privacy Policy'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PrivacyPage())),
                ),
                const Divider(height: 1, indent: 16, endIndent: 16),
                ListTile(
                  leading: const Icon(Icons.description_outlined),
                  title: const Text('Terms of Service'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const TermsPage())),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          _SectionHeader(title: 'Data'),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.download_outlined),
                  title: const Text('Export My Data'),
                  subtitle: const Text('Export all your data as JSON'),
                  onTap: () => _exportData(context),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          _SectionHeader(title: 'Session'),
          Card(
            child: Column(
              children: [
                if (authState.isGuest)
                  ListTile(
                    leading: const Icon(Icons.person_off_outlined),
                    title: const Text('Exit Guest Mode'),
                    onTap: () => _logout(context, ref),
                  )
                else ...[
                  ListTile(
                    leading: const Icon(Icons.logout),
                    title: const Text('Sign Out'),
                    onTap: () => _logout(context, ref),
                  ),
                  const Divider(height: 1, indent: 16, endIndent: 16),
                  ListTile(
                    leading: const Icon(Icons.delete_forever, color: Colors.red),
                    title: const Text('Delete Account', style: TextStyle(color: Colors.red)),
                    subtitle: const Text('Permanently delete your account and all data'),
                    onTap: () => _deleteAccount(context, ref),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Future<void> _changePassword(BuildContext context, WidgetRef ref) async {
    final newCtrl = TextEditingController();
    final confirmCtrl = TextEditingController();
    bool obscureNew = true;
    bool obscureConfirm = true;

    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('Change Password'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Enter your new password. You will be signed out after the update.'),
              const SizedBox(height: 16),
              TextField(
                controller: newCtrl,
                obscureText: obscureNew,
                decoration: InputDecoration(
                  labelText: 'New password',
                  border: const OutlineInputBorder(),
                  suffixIcon: IconButton(
                    icon: Icon(obscureNew ? Icons.visibility_off : Icons.visibility),
                    onPressed: () => setDialogState(() => obscureNew = !obscureNew),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: confirmCtrl,
                obscureText: obscureConfirm,
                decoration: InputDecoration(
                  labelText: 'Confirm new password',
                  border: const OutlineInputBorder(),
                  suffixIcon: IconButton(
                    icon: Icon(obscureConfirm ? Icons.visibility_off : Icons.visibility),
                    onPressed: () => setDialogState(() => obscureConfirm = !obscureConfirm),
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: newCtrl.text.length >= 8 && newCtrl.text == confirmCtrl.text
                  ? () => Navigator.pop(ctx, newCtrl.text)
                  : null,
              child: const Text('Update'),
            ),
          ],
        ),
      ),
    );

    if (result != null && result.isNotEmpty && context.mounted) {
      final error = await ref.read(authStateProvider.notifier).updatePassword(result);
      if (error != null && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error), backgroundColor: Colors.red));
      } else if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Password updated. Please sign in with your new password.')));
      }
    }
  }

  Future<void> _exportData(BuildContext context) async {
    final supabase = SupabaseConfig.client;
    final userId = supabase.auth.currentUser?.id;
    if (userId == null) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Data export requires a signed-in account.'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
      return;
    }

    String? shopId;
    try {
      final shop = await supabase.from('shop_members').select('shop_id').eq('user_id', userId).maybeSingle();
      shopId = shop?['shop_id'] as String?;
    } catch (_) {
      if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Failed to load shop info')));
      return;
    }
    if (shopId == null) return;

    if (!context.mounted) return;
    showDialog(context: context, barrierDismissible: false, builder: (_) => const Center(child: CircularProgressIndicator()));

    try {
      final [customers, products, bills] = await Future.wait([
        supabase.from('customers').select().eq('shop_id', shopId),
        supabase.from('products').select().eq('shop_id', shopId),
        supabase.from('bills').select().eq('shop_id', shopId),
      ]);

      if (context.mounted) Navigator.pop(context);

      final exportData = {
        'exportedAt': DateTime.now().toUtc().toIso8601String(),
        'customers': customers,
        'products': products,
        'bills': bills,
      };

      await Share.share(const JsonEncoder.withIndent('  ').convert(exportData), subject: 'InkBill Data Export');
    } catch (_) {
      if (context.mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Export failed. Please try again.'), backgroundColor: Colors.red));
      }
    }
  }

  Future<void> _logout(BuildContext context, WidgetRef ref) async {
    final authState = ref.read(authStateProvider);
    if (authState.isGuest) {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Exit Guest Mode'),
          content: const Text('Exit guest mode and return to the sign in screen?'),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
            TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Exit')),
          ],
        ),
      );
      if (confirmed == true) {
        ref.read(authStateProvider.notifier).disableGuestMode();
      }
    } else {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Sign Out'),
          content: const Text('Are you sure you want to sign out?'),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
            TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Sign Out')),
          ],
        ),
      );
      if (confirmed == true) {
        ref.read(authStateProvider.notifier).logout();
      }
    }
  }

  Future<void> _deleteAccount(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Account'),
        content: const Text('This will permanently delete your account and all associated data. This action cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), style: TextButton.styleFrom(foregroundColor: Colors.red), child: const Text('Delete')),
        ],
      ),
    );
    if (confirmed == true) {
      final db = ref.read(databaseProvider);
      final error = await ref.read(authStateProvider.notifier).deleteAccount(
        onBeforeSignOut: () => db.clearAllData(),
      );
      if (error != null && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error), backgroundColor: Colors.red));
      }
    }
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, left: 4),
      child: Text(title, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.grey.shade600, letterSpacing: 0.5)),
    );
  }
}
