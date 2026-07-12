import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:inkbill_ai/core/theme/app_theme.dart';
import 'package:inkbill_ai/features/auth/presentation/providers/auth_provider.dart';
import 'package:inkbill_ai/features/auth/presentation/pages/terms_page.dart';
import 'package:inkbill_ai/features/auth/presentation/pages/privacy_page.dart';
import 'login_page.dart';

class SignupPage extends ConsumerStatefulWidget {
  const SignupPage({super.key});

  @override
  ConsumerState<SignupPage> createState() => _SignupPageState();
}

class _SignupPageState extends ConsumerState<SignupPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _shopCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  bool _obscurePassword = true;
  bool _obscureConfirm = true;
  bool _agreeToTerms = false;
  bool _isSubmitting = false;
  bool _termsTouched = false;

  double get _passwordStrength {
    final p = _passwordCtrl.text;
    if (p.length < 6) return 0.0;
    double score = 0.0;
    if (p.length >= 8) score += 0.25;
    if (RegExp(r'[A-Z]').hasMatch(p)) score += 0.2;
    if (RegExp(r'[a-z]').hasMatch(p)) score += 0.2;
    if (RegExp(r'[0-9]').hasMatch(p)) score += 0.2;
    if (RegExp(r'[!@#$%^&*(),.?":{}|<>]').hasMatch(p)) score += 0.15;
    return score.clamp(0.0, 1.0);
  }

  String get _strengthLabel {
    final s = _passwordStrength;
    if (s <= 0.2) return 'Weak';
    if (s <= 0.5) return 'Fair';
    if (s <= 0.75) return 'Good';
    return 'Strong';
  }

  Color get _strengthColor {
    final s = _passwordStrength;
    if (s <= 0.2) return Colors.red;
    if (s <= 0.5) return Colors.orange;
    if (s <= 0.75) return Colors.blue;
    return Colors.green;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _shopCtrl.dispose();
    _emailCtrl.dispose();
    _phoneCtrl.dispose();
    _passwordCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  InputDecoration _inputDecoration(String label, {bool required = true, Widget? prefixIcon}) {
    return InputDecoration(
      label: required
          ? RichText(
              text: TextSpan(
                text: label,
                style: TextStyle(color: Colors.grey.shade700),
                children: const [
                  TextSpan(
                    text: ' *',
                    style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            )
          : Text(label, style: TextStyle(color: Colors.grey.shade700)),
      prefixIcon: prefixIcon,
    );
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authStateProvider);
    final isButtonDisabled = _isSubmitting || authState.isLoading;
    final hasNetworkError = authState.error != null &&
        (authState.error!.contains('Unable to connect') ||
            authState.error!.contains('No internet'));

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Icon(Icons.edit_note, size: 64, color: AppTheme.primaryColor),
                  const SizedBox(height: 8),
                  Text(
                    'InkBill AI',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: AppTheme.primaryColor,
                        ),
                  ),
                  const SizedBox(height: 32),
                  Text(
                    'Create your account',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 24),
                  TextFormField(
                    controller: _nameCtrl,
                    textInputAction: TextInputAction.next,
                    textCapitalization: TextCapitalization.words,
                    decoration: _inputDecoration('Full Name', prefixIcon: const Icon(Icons.person_outlined)),
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) return 'Full name is required';
                      if (v.trim().length > 100) return 'Name is too long';
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _shopCtrl,
                    textInputAction: TextInputAction.next,
                    textCapitalization: TextCapitalization.words,
                    decoration: _inputDecoration('Shop Name', prefixIcon: const Icon(Icons.store_outlined)),
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) return 'Shop name is required';
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _emailCtrl,
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.next,
                    decoration: _inputDecoration('Email', prefixIcon: const Icon(Icons.email_outlined)),
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) return 'Email is required';
                      if (!v.contains('@') || !v.contains('.')) return 'Enter a valid email';
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _phoneCtrl,
                    keyboardType: TextInputType.phone,
                    textInputAction: TextInputAction.next,
                    decoration: _inputDecoration('Phone Number', required: false, prefixIcon: const Icon(Icons.phone_outlined)),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _passwordCtrl,
                    obscureText: _obscurePassword,
                    textInputAction: TextInputAction.next,
                    decoration: _inputDecoration('Password', prefixIcon: const Icon(Icons.lock_outlined)).copyWith(
                      suffixIcon: IconButton(
                        icon: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility),
                        onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                      ),
                    ),
                    validator: (v) {
                      if (v == null || v.length < 8) return 'At least 8 characters';
                      if (!RegExp(r'[A-Za-z]').hasMatch(v)) return 'Must contain a letter';
                      if (!RegExp(r'[0-9]').hasMatch(v)) return 'Must contain a number';
                      return null;
                    },
                    onChanged: (_) => setState(() {}),
                  ),
                  if (_passwordCtrl.text.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: _passwordStrength,
                        backgroundColor: Colors.grey.shade200,
                        valueColor: AlwaysStoppedAnimation(_strengthColor),
                        minHeight: 4,
                      ),
                    ),
                    Text(_strengthLabel, style: TextStyle(fontSize: 12, color: _strengthColor)),
                  ],
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _confirmCtrl,
                    obscureText: _obscureConfirm,
                    textInputAction: TextInputAction.done,
                    decoration: _inputDecoration('Confirm Password', prefixIcon: const Icon(Icons.lock_outlined)).copyWith(
                      suffixIcon: IconButton(
                        icon: Icon(_obscureConfirm ? Icons.visibility_off : Icons.visibility),
                        onPressed: () => setState(() => _obscureConfirm = !_obscureConfirm),
                      ),
                    ),
                    validator: (v) {
                      if (v != _passwordCtrl.text) return 'Passwords do not match';
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  InkWell(
                    onTap: () => setState(() {
                      _termsTouched = true;
                      _agreeToTerms = !_agreeToTerms;
                    }),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(top: 2, right: 12),
                            child: Icon(
                              _agreeToTerms ? Icons.check_box : Icons.check_box_outline_blank,
                              size: 22,
                              color: _agreeToTerms ? AppTheme.primaryColor : Colors.grey,
                            ),
                          ),
                          Expanded(
                            child: RichText(
                              text: TextSpan(
                                style: TextStyle(fontSize: 13, color: Colors.grey.shade700, height: 1.4),
                                children: [
                                  const TextSpan(text: 'I agree to the '),
                                  WidgetSpan(
                                    child: GestureDetector(
                                      onTap: () {
                                        Navigator.push(context, MaterialPageRoute(builder: (_) => const TermsPage()));
                                      },
                                      child: Text(
                                        'Terms of Service',
                                        style: TextStyle(
                                          color: AppTheme.primaryColor,
                                          decoration: TextDecoration.underline,
                                          fontSize: 13,
                                        ),
                                      ),
                                    ),
                                  ),
                                  const TextSpan(text: ' and acknowledge the '),
                                  WidgetSpan(
                                    child: GestureDetector(
                                      onTap: () {
                                        Navigator.push(context, MaterialPageRoute(builder: (_) => const PrivacyPage()));
                                      },
                                      child: Text(
                                        'Privacy Policy',
                                        style: TextStyle(
                                          color: AppTheme.primaryColor,
                                          decoration: TextDecoration.underline,
                                          fontSize: 13,
                                        ),
                                      ),
                                    ),
                                  ),
                                  TextSpan(
                                    text: ' *',
                                    style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 13),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  if (_termsTouched && !_agreeToTerms)
                    Padding(
                      padding: const EdgeInsets.only(left: 34, top: 4),
                      child: Text(
                        'You must agree to the terms to create an account.',
                        style: TextStyle(fontSize: 12, color: Colors.red.shade700),
                      ),
                    ),
                  if (authState.error != null) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.red.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.red.shade200),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              authState.error!,
                              style: TextStyle(color: Colors.red.shade700, fontSize: 13),
                            ),
                          ),
                          if (hasNetworkError)
                            TextButton(
                              onPressed: () {
                                ref.read(authStateProvider.notifier).clearError();
                                _submit();
                              },
                              child: const Text('Retry', style: TextStyle(fontSize: 12)),
                            ),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: 20),
                  SizedBox(
                    height: 48,
                    child: ElevatedButton(
                      onPressed: isButtonDisabled ? null : _submit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryColor,
                        foregroundColor: Colors.white,
                        disabledBackgroundColor: Colors.grey.shade300,
                      ),
                      child: isButtonDisabled
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Text('Create Account', style: TextStyle(fontSize: 16)),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextButton(
                    onPressed: () {
                      Navigator.of(context).pushReplacement(
                        MaterialPageRoute(builder: (_) => const LoginPage()),
                      );
                    },
                    child: const Text("Already have an account? Log in"),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _submit() async {
    setState(() => _termsTouched = true);

    if (!_agreeToTerms) return;

    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);

    final error = await ref.read(authStateProvider.notifier).signup(
          fullName: _nameCtrl.text.trim(),
          shopName: _shopCtrl.text.trim(),
          email: _emailCtrl.text.trim(),
          password: _passwordCtrl.text,
          phone: _phoneCtrl.text.trim(),
        );

    setState(() => _isSubmitting = false);

    if (error != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error),
          backgroundColor: Colors.red.shade700,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }
}
