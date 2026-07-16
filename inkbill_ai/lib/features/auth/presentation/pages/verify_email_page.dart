import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:inkbill_ai/core/theme/app_theme.dart';
import 'package:inkbill_ai/features/auth/presentation/providers/auth_provider.dart';
import 'signup_page.dart';

class VerifyEmailPage extends ConsumerStatefulWidget {
  final String email;

  const VerifyEmailPage({super.key, required this.email});

  @override
  ConsumerState<VerifyEmailPage> createState() => _VerifyEmailPageState();
}

class _VerifyEmailPageState extends ConsumerState<VerifyEmailPage> {
  final List<TextEditingController> _controllers = List.generate(6, (_) => TextEditingController());
  final List<FocusNode> _focusNodes = List.generate(6, (_) => FocusNode());
  bool _isVerifying = false;
  bool _isResending = false;
  int _cooldownSeconds = 0;

  @override
  void initState() {
    super.initState();
    for (int i = 0; i < 6; i++) {
      _controllers[i].addListener(_onDigitChanged);
    }
  }

  @override
  void dispose() {
    for (int i = 0; i < 6; i++) {
      _controllers[i].removeListener(_onDigitChanged);
      _controllers[i].dispose();
      _focusNodes[i].dispose();
    }
    super.dispose();
  }

  String get _otpCode => _controllers.map((c) => c.text).join();

  bool get _isComplete => _otpCode.length == 6 && _otpCode.contains(RegExp(r'^\d{6}$'));

  void _onDigitChanged() {
    setState(() {});
    if (_isComplete && !_isVerifying) {
      _verify();
    }
  }

  void _onDigitInput(int index, String value) {
    if (value.length > 1) {
      final pasted = value.replaceAll(RegExp(r'[^0-9]'), '');
      for (int i = 0; i < 6 && i < pasted.length; i++) {
        _controllers[i].text = pasted[i];
      }
      if (pasted.length >= 6) {
        _focusNodes[5].requestFocus();
      } else if (pasted.isNotEmpty) {
        _focusNodes[pasted.length.clamp(0, 5)].requestFocus();
      }
      return;
    }

    if (value.isNotEmpty) {
      if (index < 5) {
        _focusNodes[index + 1].requestFocus();
      }
    }
  }

  KeyEventResult _onKeyEvent(int index, KeyEvent event) {
    if (event is KeyDownEvent &&
        event.logicalKey == LogicalKeyboardKey.backspace &&
        _controllers[index].text.isEmpty) {
      if (index > 0) {
        setState(() {
          _focusNodes[index - 1].requestFocus();
        });
      }
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  Future<void> _verify() async {
    if (!_isComplete || _isVerifying) return;

    setState(() => _isVerifying = true);

    final error = await ref.read(authStateProvider.notifier).verifyOtp(
      email: widget.email,
      otp: _otpCode,
    );

    if (!mounted) return;
    setState(() => _isVerifying = false);

    if (error == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Email verified successfully!'),
          backgroundColor: AppTheme.successColor,
          behavior: SnackBarBehavior.floating,
        ),
      );
      Navigator.of(context).popUntil((route) => route.isFirst);
    } else {
      if (!mounted) return;
      final hasExpired = error.contains('expired');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error),
          backgroundColor: Colors.red.shade700,
          behavior: SnackBarBehavior.floating,
          action: hasExpired
              ? SnackBarAction(
                  label: 'Resend',
                  textColor: Colors.white,
                  onPressed: _resend,
                )
              : null,
        ),
      );
      if (!hasExpired) {
        for (final c in _controllers) {
          c.clear();
        }
        _focusNodes[0].requestFocus();
      }
    }
  }

  Future<void> _resend() async {
    if (_isResending || _cooldownSeconds > 0) return;

    setState(() => _isResending = true);

    final error = await ref.read(authStateProvider.notifier).resendOtp(widget.email);

    if (!mounted) return;
    setState(() => _isResending = false);

    if (error == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('A new verification code has been sent.'),
          backgroundColor: AppTheme.successColor,
          behavior: SnackBarBehavior.floating,
        ),
      );
      _startCooldown();
      for (final c in _controllers) {
        c.clear();
      }
      _focusNodes[0].requestFocus();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error),
          backgroundColor: Colors.red.shade700,
          behavior: SnackBarBehavior.floating,
        ),
      );
      if (error.contains('rate limit') || error.contains('Too many')) {
        _startCooldown();
      }
    }
  }

  void _startCooldown() {
    _cooldownSeconds = 60;
    Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      setState(() {
        _cooldownSeconds--;
        if (_cooldownSeconds <= 0) {
          timer.cancel();
        }
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Icon(Icons.email_outlined, size: 64, color: AppTheme.primaryColor),
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
                  'Verify your email',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 12),
                Text(
                  "We've sent a 6-digit verification code to",
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
                ),
                const SizedBox(height: 4),
                Text(
                  widget.email,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.primaryColor,
                  ),
                ),
                const SizedBox(height: 32),
                LayoutBuilder(
                  builder: (context, constraints) {
                    final gap = 6.0;
                    final totalGaps = gap * 5;
                    final boxSize = ((constraints.maxWidth - totalGaps) / 6).floorToDouble().clamp(36.0, 56.0);
                    final fontSize = boxSize > 44 ? 22.0 : 18.0;

                    return AutofillGroup(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(6, (index) {
                          return Padding(
                            padding: EdgeInsets.only(right: index < 5 ? gap : 0),
                            child: SizedBox(
                              width: boxSize,
                              height: boxSize + 4,
                              child: Focus(
                                focusNode: _focusNodes[index],
                                onKeyEvent: (node, event) => _onKeyEvent(index, event),
                                child: TextField(
                                  controller: _controllers[index],
                                  autofillHints: index == 0 ? const [AutofillHints.oneTimeCode] : null,
                                  keyboardType: TextInputType.number,
                                  textAlign: TextAlign.center,
                                  maxLength: index == 0 ? 6 : 1,
                                  style: TextStyle(
                                    fontSize: fontSize,
                                    fontWeight: FontWeight.w600,
                                  ),
                                  inputFormatters: [
                                    FilteringTextInputFormatter.digitsOnly,
                                    LengthLimitingTextInputFormatter(index == 0 ? 6 : 1),
                                  ],
                                  decoration: InputDecoration(
                                    counterText: '',
                                    filled: true,
                                    fillColor: AppTheme.surface,
                                    contentPadding: EdgeInsets.zero,
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8),
                                      borderSide: BorderSide(color: Colors.grey.shade300),
                                    ),
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8),
                                      borderSide: BorderSide(color: Colors.grey.shade300),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8),
                                      borderSide: BorderSide(color: AppTheme.primaryColor, width: 2),
                                    ),
                                  ),
                                  onChanged: (value) => _onDigitInput(index, value),
                                ),
                              ),
                            ),
                          );
                        }),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 28),
                SizedBox(
                  height: 48,
                  child: ElevatedButton(
                    onPressed: (_isComplete && !_isVerifying) ? _verify : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryColor,
                      foregroundColor: Colors.white,
                      disabledBackgroundColor: Colors.grey.shade300,
                    ),
                    child: _isVerifying
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Text('Verify Email', style: TextStyle(fontSize: 16)),
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      "Didn't receive the code?",
                      style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Center(
                  child: _cooldownSeconds > 0
                      ? Text(
                          'Resend code in ${_cooldownSeconds}s',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey.shade500,
                          ),
                        )
                      : TextButton(
                          onPressed: _isResending ? null : _resend,
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                          ),
                          child: _isResending
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                )
                              : Text(
                                  'Resend code',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: AppTheme.primaryColor,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                        ),
                ),
                const SizedBox(height: 24),
                TextButton(
                  onPressed: () {
                    ref.read(authStateProvider.notifier).clearPendingVerification();
                    Navigator.of(context).pushReplacement(
                      MaterialPageRoute(builder: (_) => const SignupPage()),
                    );
                  },
                  child: Text(
                    'Change email or back to sign up',
                    style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
