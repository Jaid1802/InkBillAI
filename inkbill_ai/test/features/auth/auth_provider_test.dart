import 'package:flutter_test/flutter_test.dart';
import 'package:inkbill_ai/features/auth/domain/entities/auth_user.dart';
import 'package:inkbill_ai/features/auth/presentation/providers/auth_provider.dart';

void main() {
  group('AuthState', () {
    test('initial state has isLoading=true', () {
      const state = AuthState();
      expect(state.isLoading, true);
      expect(state.isAuthenticated, false);
      expect(state.user, null);
      expect(state.error, null);
    });

    test('copyWith updates correctly', () {
      const state = AuthState();
      final updated = state.copyWith(isLoading: false, isAuthenticated: true);
      expect(updated.isLoading, false);
      expect(updated.isAuthenticated, true);
    });

    test('props include key fields', () {
      const state = AuthState();
      expect(state.props.length, 5);
    });

    test('default isAuthenticated is false', () {
      const state = AuthState();
      expect(state.isAuthenticated, false);
    });

    test('error can be set via copyWith', () {
      const state = AuthState();
      final withError = state.copyWith(error: 'Test error');
      expect(withError.error, 'Test error');
    });

    test('copyWith preserves user when not overridden', () {
      final user = AuthUser(
        id: 'u1',
        fullName: 'Test',
        email: 'test@test.com',
        role: 'owner',
        shopId: 's1',
      );
      const state = AuthState();
      final withUser = state.copyWith(user: user);
      expect(withUser.user?.fullName, 'Test');

      final withIsLoading = withUser.copyWith(isLoading: true);
      expect(withIsLoading.user?.fullName, 'Test');
      expect(withIsLoading.isLoading, true);
    });

    test('AuthUser copyWith works correctly', () {
      final user = AuthUser(
        id: 'u1',
        fullName: 'Original',
        email: 'test@test.com',
        role: 'owner',
        shopId: 's1',
      );
      final updated = user.copyWith(fullName: 'Updated', phone: '123');
      expect(updated.fullName, 'Updated');
      expect(updated.phone, '123');
      expect(updated.id, 'u1');
    });
  });
}
