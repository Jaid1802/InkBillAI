import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide Provider;
import 'package:inkbill_ai/core/supabase/supabase_config.dart';
import 'package:inkbill_ai/features/auth/domain/entities/auth_user.dart';

final authStateProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  final supabase = ref.watch(supabaseClientProvider);
  return AuthNotifier(supabase);
});

class AuthNotifier extends StateNotifier<AuthState> {
  final SupabaseClient _supabase;

  AuthNotifier(this._supabase) : super(const AuthState(isLoading: true)) {
    _setupAuthListener();
  }

  void _setupAuthListener() {
    _supabase.auth.onAuthStateChange.listen((data) {
      final session = data.session;
      if (session != null) {
        _loadUserProfile(session);
      } else {
        state = const AuthState();
      }
    });

    _tryRestoreSession();
  }

  Future<void> _tryRestoreSession() async {
    final session = _supabase.auth.currentSession;
    if (session != null) {
      await _loadUserProfile(session);
    } else {
      state = const AuthState();
    }
  }

  Future<void> _loadUserProfile(Session session) async {
    try {
      final userId = session.user.id;
      final userMetadata = session.user.userMetadata;

      final fullName = userMetadata?['full_name'] as String? ?? '';
      final shopName = userMetadata?['shop_name'] as String? ?? '';
      final shopId = userMetadata?['shop_id'] as String? ?? '';

      if (fullName.isNotEmpty && shopId.isNotEmpty) {
        state = AuthState(
          user: AuthUser(
            id: userId,
            fullName: fullName,
            email: session.user.email ?? '',
            role: 'owner',
            shopId: shopId,
          ),
          shop: AuthShop(id: shopId, shopName: shopName),
          isAuthenticated: true,
        );
        return;
      }

      final profile = await _supabase
          .from('profiles')
          .select('*, shops!inner(*), shop_members!inner(*)')
          .eq('id', userId)
          .maybeSingle();

      if (profile != null) {
        final shop = profile['shops'] as Map<String, dynamic>?;
        final member = profile['shop_members'] as Map<String, dynamic>?;

        state = AuthState(
          user: AuthUser(
            id: userId,
            fullName: profile['full_name'] as String? ?? '',
            email: session.user.email ?? '',
            phone: profile['phone'] as String?,
            role: member?['role'] as String? ?? 'owner',
            shopId: shop?['id'] as String? ?? '',
          ),
          shop: shop != null
              ? AuthShop(
                  id: shop['id'] as String,
                  shopName: shop['name'] as String? ?? 'My Shop',
                )
              : null,
          isAuthenticated: true,
        );
      } else {
        state = AuthState(
          user: AuthUser(
            id: userId,
            fullName: fullName,
            email: session.user.email ?? '',
            role: 'owner',
            shopId: shopId,
          ),
          isAuthenticated: true,
        );
      }
    } catch (e) {
      debugPrint('AuthNotifier: failed to load profile: $e');
      state = const AuthState();
    }
  }

  Future<String?> signup({
    required String fullName,
    required String shopName,
    required String email,
    required String password,
    String? phone,
  }) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final response = await _supabase.auth.signUp(
        email: email.trim(),
        password: password,
        data: {
          'full_name': fullName.trim(),
          'shop_name': shopName.trim(),
          if (phone != null && phone.isNotEmpty) 'phone': phone.trim(),
        },
      );

      if (response.session != null) {
        await _createProfileAndShop(
          userId: response.user!.id,
          fullName: fullName.trim(),
          shopName: shopName.trim(),
          phone: phone?.trim(),
          email: email.trim(),
        );

        await _loadUserProfile(response.session!);
        return null;
      }

      state = state.copyWith(
        isLoading: false,
        error: 'Please check your email to verify your account.',
      );
      return 'Please check your email to verify your account.';
    } on AuthException catch (e) {
      final msg = _mapAuthException(e);
      state = state.copyWith(isLoading: false, error: msg);
      return msg;
    } catch (e) {
      debugPrint('Signup error: $e');
      const msg = 'Something went wrong. Please try again.';
      state = state.copyWith(isLoading: false, error: msg);
      return msg;
    }
  }

  Future<void> _createProfileAndShop({
    required String userId,
    required String fullName,
    required String shopName,
    String? phone,
    required String email,
  }) async {
    try {
      await _supabase.rpc('onboard_new_user', params: {
        'p_user_id': userId,
        'p_full_name': fullName,
        'p_shop_name': shopName,
        'p_phone': phone ?? '',
        'p_email': email,
      });
    } catch (e) {
      debugPrint('RPC onboard_new_user failed (may need manual setup): $e');
      try {
        final shop = await _supabase
            .from('shops')
            .insert({'name': shopName, 'owner_id': userId})
            .select()
            .single();

        await _supabase.from('profiles').insert({
          'id': userId,
          'full_name': fullName,
          'phone': phone,
        });

        await _supabase.from('shop_members').insert({
          'shop_id': shop['id'],
          'user_id': userId,
          'role': 'owner',
        });
      } catch (insertError) {
        debugPrint('Direct insert fallback also failed: $insertError');
      }
    }
  }

  Future<String?> login({
    required String email,
    required String password,
  }) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final response = await _supabase.auth.signInWithPassword(
        email: email.trim(),
        password: password,
      );

      if (response.session != null) {
        await _loadUserProfile(response.session!);
        return null;
      }

      const msg = 'Invalid email or password.';
      state = state.copyWith(isLoading: false, error: msg);
      return msg;
    } on AuthException catch (e) {
      final msg = _mapAuthException(e);
      state = state.copyWith(isLoading: false, error: msg);
      return msg;
    } catch (e) {
      debugPrint('Login error: $e');
      const msg = 'Unable to connect. Check your internet connection and try again.';
      state = state.copyWith(isLoading: false, error: msg);
      return msg;
    }
  }

  Future<void> logout() async {
    try {
      await _supabase.auth.signOut();
    } catch (e) {
      debugPrint('Logout error: $e');
    }
    state = const AuthState();
  }

  Future<String?> deleteAccount() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) {
        const msg = 'No authenticated user.';
        state = state.copyWith(isLoading: false, error: msg);
        return msg;
      }

      await _supabase.from('profiles').delete().eq('id', userId);

      final shops = await _supabase
          .from('shops')
          .delete()
          .eq('owner_id', userId)
          .select();

      for (final shop in shops) {
        await _supabase.from('customers').delete().eq('shop_id', shop['id']);
        await _supabase.from('products').delete().eq('shop_id', shop['id']);
        await _supabase.from('bills').delete().eq('shop_id', shop['id']);
        await _supabase.from('ink_documents').delete().eq('shop_id', shop['id']);
        await _supabase.from('shop_members').delete().eq('shop_id', shop['id']);
      }

      await _supabase.auth.admin.deleteUser(userId);
      await _supabase.auth.signOut();
      state = const AuthState();
      return null;
    } catch (e) {
      debugPrint('Delete account error: $e');
      const msg = 'Failed to delete account. Please try again.';
      state = state.copyWith(isLoading: false, error: msg);
      return msg;
    }
  }

  Future<String?> resetPassword(String email) async {
    try {
      await _supabase.auth.resetPasswordForEmail(email.trim());
      return null;
    } on AuthException catch (e) {
      return _mapAuthException(e);
    } catch (e) {
      debugPrint('Reset password error: $e');
      return 'Something went wrong. Please try again.';
    }
  }

  Future<String?> updatePassword(String newPassword) async {
    try {
      await _supabase.auth.updateUser(UserAttributes(password: newPassword));
      return null;
    } on AuthException catch (e) {
      return _mapAuthException(e);
    } catch (e) {
      debugPrint('Update password error: $e');
      return 'Something went wrong. Please try again.';
    }
  }

  void clearError() {
    state = state.copyWith(error: null);
  }

  String _mapAuthException(AuthException e) {
    final msg = e.message.toLowerCase();
    if (msg.contains('email already registered') || msg.contains('already exists') || msg.contains('duplicate')) {
      return 'An account with this email already exists.';
    }
    if (msg.contains('invalid login credentials') || msg.contains('invalid credentials')) {
      return 'Invalid email or password.';
    }
    if (msg.contains('weak password')) {
      return 'Password is too weak. Use at least 8 characters with letters and numbers.';
    }
    if (msg.contains('network') || msg.contains('timeout') || msg.contains('connect')) {
      return 'Unable to connect. Check your internet connection and try again.';
    }
    if (msg.contains('email not confirmed') || msg.contains('email not verified')) {
      return 'Please verify your email before continuing.';
    }
    if (msg.contains('rate limit')) {
      return 'Too many attempts. Please wait and try again.';
    }
    debugPrint('Unmapped AuthException: ${e.message}');
    return 'Something went wrong. Please try again.';
  }
}
