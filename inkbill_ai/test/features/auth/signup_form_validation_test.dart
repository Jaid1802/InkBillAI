import 'package:flutter_test/flutter_test.dart';

bool validateEmail(String? v) {
  if (v == null || v.trim().isEmpty) return false;
  if (!v.contains('@') || !v.contains('.')) return false;
  return true;
}

bool validatePassword(String? v) {
  if (v == null || v.length < 8) return false;
  if (!RegExp(r'[A-Za-z]').hasMatch(v)) return false;
  if (!RegExp(r'[0-9]').hasMatch(v)) return false;
  return true;
}

bool validateRequired(String? v) {
  if (v == null || v.trim().isEmpty) return false;
  if (v.trim().length > 100) return false;
  return true;
}

bool validatePasswordMatch(String? confirm, String password) {
  return confirm == password;
}

double calculatePasswordStrength(String p) {
  if (p.length < 6) return 0.0;
  double score = 0.0;
  if (p.length >= 8) score += 0.25;
  if (RegExp(r'[A-Z]').hasMatch(p)) score += 0.2;
  if (RegExp(r'[a-z]').hasMatch(p)) score += 0.2;
  if (RegExp(r'[0-9]').hasMatch(p)) score += 0.2;
  if (RegExp(r'[!@#$%^&*(),.?":{}|<>]').hasMatch(p)) score += 0.15;
  return score.clamp(0.0, 1.0);
}

void main() {
  group('Signup Form Validation', () {
    group('Email', () {
      test('accepts valid email', () {
        expect(validateEmail('user@example.com'), true);
      });

      test('rejects empty email', () {
        expect(validateEmail(''), false);
        expect(validateEmail(null), false);
      });

      test('rejects email without @', () {
        expect(validateEmail('userexample.com'), false);
      });

      test('rejects email without domain', () {
        expect(validateEmail('user@'), false);
      });

      test('rejects email without dot', () {
        expect(validateEmail('user@example'), false);
      });
    });

    group('Password', () {
      test('accepts valid password (8+ chars, letter, number)', () {
        expect(validatePassword('Password123'), true);
      });

      test('rejects short password', () {
        expect(validatePassword('Ab1'), false);
      });

      test('rejects password without letter', () {
        expect(validatePassword('12345678'), false);
      });

      test('rejects password without number', () {
        expect(validatePassword('Password'), false);
      });

      test('rejects null password', () {
        expect(validatePassword(null), false);
      });
    });

    group('Required Fields', () {
      test('accepts non-empty string', () {
        expect(validateRequired('John Doe'), true);
      });

      test('rejects empty string', () {
        expect(validateRequired(''), false);
      });

      test('rejects whitespace-only string', () {
        expect(validateRequired('   '), false);
      });

      test('rejects null', () {
        expect(validateRequired(null), false);
      });

      test('rejects overly long string', () {
        expect(validateRequired('A' * 101), false);
      });
    });

    group('Password Match', () {
      test('passwords match', () {
        expect(validatePasswordMatch('Password123', 'Password123'), true);
      });

      test('passwords do not match', () {
        expect(validatePasswordMatch('Password123', 'Password456'), false);
      });
    });

    group('Password Strength', () {
      test('returns 0 for very short password', () {
        expect(calculatePasswordStrength('ab'), 0.0);
      });

      test('returns >0 for password with mixed chars', () {
        final strength = calculatePasswordStrength('Password123!');
        expect(strength, greaterThan(0.5));
      });

      test('returns 1.0 for very strong password', () {
        final strength = calculatePasswordStrength('Password123!@#');
        expect(strength, 1.0);
      });
    });
  });
}
