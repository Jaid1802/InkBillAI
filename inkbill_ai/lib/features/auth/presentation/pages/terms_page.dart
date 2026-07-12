import 'package:flutter/material.dart';
import 'package:inkbill_ai/core/theme/app_theme.dart';

class TermsPage extends StatelessWidget {
  const TermsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Terms of Service')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: const [
          _Section(
            title: '1. Acceptance of Terms',
            body:
                'By creating an account and using InkBill AI, you agree to be bound by these Terms of Service. '
                'If you do not agree to these terms, do not use the application.',
          ),
          _Section(
            title: '2. Account Registration',
            body:
                'You must provide accurate and complete information when creating your account. '
                'You are responsible for maintaining the confidentiality of your account credentials '
                'and for all activities that occur under your account. You must notify us immediately '
                'of any unauthorized use of your account.',
          ),
          _Section(
            title: '3. Acceptable Use',
            body:
                'You agree to use InkBill AI only for lawful purposes and in accordance with these terms. '
                'You agree not to:\n\n'
                '• Use the application for any illegal or unauthorized purpose\n'
                '• Attempt to access another user\'s account or data\n'
                '• Interfere with or disrupt the application\'s security features\n'
                '• Attempt to bypass rate limits or access controls\n'
                '• Use the application to store or process illegal content\n'
                '• Reverse engineer, decompile, or disassemble the application',
          ),
          _Section(
            title: '4. Data Ownership',
            body:
                'You retain ownership of all data you enter into InkBill AI, including customer information, '
                'product catalogs, bills, invoices, and digital ink content. We claim no intellectual '
                'property rights over your data.',
          ),
          _Section(
            title: '5. Service Availability',
            body:
                'We strive to maintain high availability of our services but do not guarantee uninterrupted '
                'access. The application includes offline functionality that allows core features to work '
                'without an internet connection. Cloud synchronization requires an active internet connection.',
          ),
          _Section(
            title: '6. Limitation of Liability',
            body:
                'InkBill AI is provided "as is" without warranties of any kind. We are not liable for '
                'any damages arising from the use or inability to use the application, including but not '
                'limited to data loss, financial loss, or business interruption. You are responsible for '
                'maintaining backups of your important data.',
          ),
          _Section(
            title: '7. Termination',
            body:
                'You may delete your account at any time through the Settings > Privacy & Security section. '
                'We may suspend or terminate your account if you violate these terms. Upon termination, '
                'your data will be permanently deleted from our servers.',
          ),
          _Section(
            title: '8. Changes to Terms',
            body:
                'We reserve the right to modify these terms at any time. We will notify users of material '
                'changes through the application. Continued use of the application after changes constitutes '
                'acceptance of the new terms.',
          ),
          _Section(
            title: '9. Governing Law',
            body:
                'These terms shall be governed by and construed in accordance with applicable laws. '
                'Any disputes arising from these terms shall be resolved through binding arbitration.',
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
