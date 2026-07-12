import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:inkbill_ai/features/auth/presentation/providers/auth_provider.dart';
import 'package:inkbill_ai/features/auth/presentation/pages/settings_page.dart';
import 'package:inkbill_ai/features/billing/presentation/pages/billing_page.dart';
import 'package:inkbill_ai/features/customers/presentation/pages/customers_page.dart';
import 'package:inkbill_ai/features/products/presentation/pages/products_page.dart';
import 'package:inkbill_ai/features/reports/presentation/pages/dashboard_page.dart';
import 'package:inkbill_ai/features/handwriting/presentation/pages/ink_page.dart';

class AppShell extends ConsumerStatefulWidget {
  const AppShell({super.key});

  @override
  ConsumerState<AppShell> createState() => _AppShellState();
}

class _AppShellState extends ConsumerState<AppShell> {
  int _currentIndex = 0;

  final List<Widget> _pages = [
    const DashboardPage(),
    const BillingPage(),
    const InkNotePage(),
    const CustomersPage(),
    const ProductsPage(),
  ];

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authStateProvider);
    final shopName = authState.shop?.shopName ?? 'InkBill AI';

    return Scaffold(
      appBar: AppBar(
        title: Text(shopName),
        actions: [
            PopupMenuButton<String>(
            icon: const Icon(Icons.account_circle),
            onSelected: (value) async {
              if (value == 'settings') {
                Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsPage()));
              } else if (value == 'logout') {
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: const Text('Logout'),
                    content: const Text('Are you sure you want to logout?'),
                    actions: [
                      TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
                      TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Logout')),
                    ],
                  ),
                );
                if (confirm == true) {
                  ref.read(authStateProvider.notifier).logout();
                }
              }
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'profile',
                enabled: false,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(authState.user?.fullName ?? '', style: const TextStyle(fontWeight: FontWeight.bold)),
                    Text(authState.user?.email ?? '', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                  ],
                ),
              ),
              const PopupMenuDivider(),
              const PopupMenuItem(value: 'settings', child: ListTile(
                leading: Icon(Icons.settings, size: 20),
                title: Text('Privacy & Security'),
                dense: true,
                contentPadding: EdgeInsets.zero,
              )),
              const PopupMenuItem(value: 'logout', child: ListTile(
                leading: Icon(Icons.logout, size: 20),
                title: Text('Logout'),
                dense: true,
                contentPadding: EdgeInsets.zero,
              )),
            ],
          ),
        ],
      ),
      body: IndexedStack(
        index: _currentIndex,
        children: _pages,
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) {
          setState(() => _currentIndex = index);
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.dashboard_outlined),
            selectedIcon: Icon(Icons.dashboard),
            label: 'Dashboard',
          ),
          NavigationDestination(
            icon: Icon(Icons.receipt_long_outlined),
            selectedIcon: Icon(Icons.receipt_long),
            label: 'Bills',
          ),
          NavigationDestination(
            icon: Icon(Icons.edit_note_outlined),
            selectedIcon: Icon(Icons.edit_note),
            label: 'Ink',
          ),
          NavigationDestination(
            icon: Icon(Icons.people_outlined),
            selectedIcon: Icon(Icons.people),
            label: 'Customers',
          ),
          NavigationDestination(
            icon: Icon(Icons.inventory_2_outlined),
            selectedIcon: Icon(Icons.inventory_2),
            label: 'Products',
          ),
        ],
      ),
    );
  }
}
