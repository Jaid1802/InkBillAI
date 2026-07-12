import 'package:flutter/material.dart';
import 'package:inkbill_ai/core/theme/app_theme.dart';

class PrivacyPage extends StatelessWidget {
  const PrivacyPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Privacy Policy')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: const [
          _Section(
            title: 'Effective Date',
            body: 'July 12, 2026',
          ),
          _Section(
            title: 'Information We Collect',
            body:
                'When you create an account, we collect your full name, email address, phone number, '
                'and shop/organization name. When you use InkBill AI, we collect and store:\n\n'
                '• Customer information (name, phone, email, address, GSTIN)\n'
                '• Product information (name, SKU, barcode, price, stock)\n'
                '• Bill and invoice data (items, quantities, rates, taxes, totals)\n'
                '• Digital ink and handwriting data (strokes, points, pressure, timing)\n'
                '• Shop settings and receipt configuration',
          ),
          _Section(
            title: 'How We Store Your Data',
            body:
                'Your data is stored locally on your device using SQLite/Drift for offline access and '
                'fast performance. Data is also stored securely in Supabase (PostgreSQL) cloud databases '
                'for synchronization and backup across devices.\n\n'
                'Authentication is handled by Supabase Auth. Session data is stored securely using '
                'platform-specific secure storage (Android Keystore / iOS Keychain).',
          ),
          _Section(
            title: 'How We Use Your Data',
            body:
                'We use your data to:\n\n'
                '• Create and manage your account and shop\n'
                '• Generate bills, invoices, and receipts\n'
                '• Process and recognize digital handwriting input\n'
                '• Synchronize data across your devices\n'
                '• Provide cloud backup and restore\n'
                '• Improve application functionality\n'
                '• Comply with legal obligations',
          ),
          _Section(
            title: 'Data Sharing',
            body:
                'We do not sell your personal data. Your data is processed through:\n\n'
                '• Supabase (PostgreSQL) for cloud database storage and authentication\n'
                '• Supabase Storage for ink documents, receipts, and images\n'
                '• Google ML Kit (on-device handwriting recognition — no data leaves your device)\n\n'
                'We may disclose data if required by law or to protect our legal rights.',
          ),
          _Section(
            title: 'Security',
            body:
                'We implement industry-standard security measures:\n\n'
                '• Passwords are hashed using bcrypt (never stored in plaintext)\n'
                '• API communications use HTTPS/TLS encryption\n'
                '• JWT tokens with short expiration and secure refresh flow\n'
                '• Session tracking and revocation capability\n'
                '• Database credentials never exposed to client devices\n'
                '• Input validation and rate limiting on all API endpoints',
          ),
          _Section(
            title: 'Data Retention',
            body:
                'We retain your account data for as long as your account is active. '
                'You can delete your account and associated data at any time through the '
                'Settings > Privacy & Security section. When you delete your account, '
                'your personal information, shop data, customers, products, bills, and '
                'ink documents are permanently deleted from our servers.',
          ),
          _Section(
            title: 'Your Rights',
            body:
                'You have the right to:\n\n'
                '• Access your personal data\n'
                '• Export/download your data\n'
                '• Correct inaccurate data\n'
                '• Delete your account and data\n'
                '• Withdraw consent at any time\n'
                '• Log out of all active sessions',
          ),
          _Section(
            title: 'Contact',
            body:
                'For privacy-related inquiries, please contact the application developer '
                'through the support channels provided in the application.',
          ),
        ],
      ),
    );
  }
}

class _Section extends StatelessWidget {
  final String title;
  final String body;

  const _Section({required this.title, required this.body});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppTheme.primaryColor,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            body,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade800,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}
