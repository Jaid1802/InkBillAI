import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide AuthState, AuthUser;
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
      debugPrint('[AUTH_STATE] event=${data.event.name} session=${session != null}');
      if (session != null) {
        state = state.copyWith(pendingVerificationEmail: null);
        _loadUserProfile(session);
      } else {
        state = const AuthState();
      }
    }, onError: (e) {
      debugPrint('[AUTH_STATE] listener error: $e');
    });

    _tryRestoreSession();
  }

  Future<void> _tryRestoreSession() async {
    final session = _supabase.auth.currentSession;
    debugPrint('[AUTH_INIT] currentSession=${session != null}');
    if (session != null) {
      await _loadUserProfile(session);
    } else {
      state = const AuthState();
    }
  }

  Future<void> _loadUserProfile(Session session) async {
    try {
      final userId = session.user.id;

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
        final userMetadata = session.user.userMetadata;
        state = AuthState(
          user: AuthUser(
            id: userId,
            fullName: userMetadata?['full_name'] as String? ?? '',
            email: session.user.email ?? '',
            role: 'owner',
            shopId: userMetadata?['shop_id'] as String? ?? '',
          ),
          isAuthenticated: true,
        );
      }
    } catch (e) {
      debugPrint('[AUTH_STATE] failed to load profile: $e');
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
    final normalizedEmail = email.trim().toLowerCase();
    debugPrint('[AUTH_SIGNUP] started email=$normalizedEmail');

    state = state.copyWith(isLoading: true, error: null, pendingVerificationEmail: null);

    try {
      final response = await _supabase.auth.signUp(
        email: normalizedEmail,
        password: password,
        data: {
          'full_name': fullName.trim(),
          'shop_name': shopName.trim(),
          if (phone != null && phone.isNotEmpty) 'phone': phone.trim(),
        },
      );

      debugPrint('[AUTH_SIGNUP] user=${response.user?.id} session=${response.session != null}');

      if (response.session != null) {
        await _createProfileAndShop(
          userId: response.user!.id,
          fullName: fullName.trim(),
          shopName: shopName.trim(),
          phone: phone?.trim(),
          email: normalizedEmail,
        );

        await _loadUserProfile(response.session!);
        return null;
      }

      state = state.copyWith(
        isLoading: false,
        pendingVerificationEmail: normalizedEmail,
      );
      return null;
    } on AuthException catch (e) {
      debugPrint('[AUTH_SIGNUP] AuthException status=${e.statusCode} message=${e.message}');
      state = state.copyWith(isLoading: false, error: e.message);
      return e.message;
    } catch (e) {
      debugPrint('[AUTH_SIGNUP] error: $e');
      const msg = 'Something went wrong. Please try again.';
      state = state.copyWith(isLoading: false, error: msg);
      return msg;
    }
  }

  Future<String?> verifyOtp({
    required String email,
    required String otp,
  }) async {
    final normalizedEmail = email.trim().toLowerCase();
    debugPrint('[AUTH_VERIFY_OTP] started email=$normalizedEmail otp.length=${otp.length}');

    state = state.copyWith(isLoading: true, error: null);

    try {
      final response = await _supabase.auth.verifyOTP(
        email: normalizedEmail,
        token: otp,
        type: OtpType.email,
      );

      debugPrint('[AUTH_VERIFY_OTP] session=${response.session != null} user=${response.user?.id}');

      if (response.session != null) {
        final userId = response.user?.id ?? response.session!.user.id;
        await _createProfileAndShop(
          userId: userId,
          fullName: response.session!.user.userMetadata?['full_name'] as String? ?? '',
          shopName: response.session!.user.userMetadata?['shop_name'] as String? ?? '',
          phone: response.session!.user.userMetadata?['phone'] as String?,
          email: normalizedEmail,
        );

        await _loadUserProfile(response.session!);
        state = state.copyWith(
          isLoading: false,
          pendingVerificationEmail: null,
        );
        return null;
      }

      const msg = 'The verification code is incorrect. Please check the code and try again.';
      state = state.copyWith(isLoading: false, error: msg);
      return msg;
    } on AuthException catch (e) {
      debugPrint('[AUTH_VERIFY_OTP] AuthException status=${e.statusCode} message=${e.message}');
      String msg;
      final lower = e.message.toLowerCase();
      if (lower.contains('token') && (lower.contains('invalid') || lower.contains('incorrect') || lower.contains('wrong'))) {
        msg = 'The verification code is incorrect. Please check the code and try again.';
      } else if (lower.contains('expired')) {
        msg = 'This verification code has expired. Request a new code to continue.';
      } else if (lower.contains('already') && (lower.contains('used') || lower.contains('verified') || lower.contains('confirmed'))) {
        msg = 'This code has already been used. Please try logging in.';
      } else if (lower.contains('rate limit') || lower.contains('too many')) {
        msg = 'Too many attempts. Please wait a moment before trying again.';
      } else if (lower.contains('network') || lower.contains('timeout') || lower.contains('connect')) {
        msg = 'Unable to connect. Check your internet connection and try again.';
      } else {
        msg = 'Something went wrong. Please try again.';
      }
      state = state.copyWith(isLoading: false, error: msg);
      return msg;
    } catch (e) {
      debugPrint('[AUTH_VERIFY_OTP] error: $e');
      const msg = 'Unable to connect. Check your internet connection and try again.';
      state = state.copyWith(isLoading: false, error: msg);
      return msg;
    }
  }

  Future<String?> resendOtp(String email) async {
    final normalizedEmail = email.trim().toLowerCase();
    debugPrint('[AUTH_RESEND] started email=$normalizedEmail');

    try {
      await _supabase.auth.resend(
        type: OtpType.signup,
        email: normalizedEmail,
      );

      debugPrint('[AUTH_RESEND] success');
      return null;
    } on AuthException catch (e) {
      debugPrint('[AUTH_RESEND] AuthException status=${e.statusCode} message=${e.message}');
      final lower = e.message.toLowerCase();
      if (lower.contains('rate limit') || lower.contains('too many')) {
        return 'Too many attempts. Please wait a moment before trying again.';
      }
      if (lower.contains('network') || lower.contains('timeout') || lower.contains('connect')) {
        return 'Unable to connect. Check your internet connection and try again.';
      }
      return 'Something went wrong. Please try again.';
    } catch (e) {
      debugPrint('[AUTH_RESEND] error: $e');
      return 'Unable to connect. Check your internet connection and try again.';
    }
  }

  void setPendingVerificationEmail(String email) {
    state = state.copyWith(pendingVerificationEmail: email.trim().toLowerCase());
  }

  void clearPendingVerification() {
    state = state.copyWith(pendingVerificationEmail: null);
  }

  void enableGuestMode() {
    debugPrint('[AUTH_STATE] enableGuestMode');
    state = AuthState(
      isGuest: true,
      user: const AuthUser(
        id: 'guest-local-user',
        fullName: 'Guest',
        email: 'guest@inkbill.app',
        role: 'guest',
        shopId: '',
      ),
    );
  }

  void disableGuestMode() {
    debugPrint('[AUTH_STATE] disableGuestMode');
    state = const AuthState();
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
      debugPrint('[AUTH_SIGNUP] onboard_new_user succeeded');
    } catch (e) {
      debugPrint('[AUTH_SIGNUP] RPC onboard_new_user failed: $e');
      rethrow;
    }
  }

  Future<String?> login({
    required String email,
    required String password,
  }) async {
    final normalizedEmail = email.trim().toLowerCase();
    debugPrint('[AUTH_LOGIN] started email=$normalizedEmail');

    state = state.copyWith(isLoading: true, error: null);

    try {
      final response = await _supabase.auth.signInWithPassword(
        email: normalizedEmail,
        password: password,
      );

      debugPrint('[AUTH_LOGIN] session=${response.session != null} user=${response.user?.id}');

      if (response.session != null) {
        await _loadUserProfile(response.session!);
        return null;
      }

      const msg = 'Invalid email or password.';
      state = state.copyWith(isLoading: false, error: msg);
      return msg;
    } on AuthException catch (e) {
      debugPrint('[AUTH_LOGIN] AuthException status=${e.statusCode} message=${e.message}');
      final msg = e.message;
      final lower = msg.toLowerCase();
      if (lower.contains('email not confirmed') || lower.contains('email not verified')) {
        state = state.copyWith(
          isLoading: false,
          error: 'Please verify your email before signing in.',
          pendingVerificationEmail: normalizedEmail,
        );
        return 'Please verify your email before signing in.';
      }
      state = state.copyWith(isLoading: false, error: msg);
      return msg;
    } catch (e) {
      debugPrint('[AUTH_LOGIN] error: $e');
      const msg = 'Unable to connect. Check your internet connection and try again.';
      state = state.copyWith(isLoading: false, error: msg);
      return msg;
    }
  }

  Future<void> logout() async {
    debugPrint('[AUTH_STATE] logout');
    try {
      await _supabase.auth.signOut();
    } catch (e) {
      debugPrint('[AUTH_STATE] logout error: $e');
    }
    state = const AuthState();
  }

  Future<String?> deleteAccount({Future<void> Function()? onBeforeSignOut}) async {
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

      if (onBeforeSignOut != null) {
        await onBeforeSignOut();
      }

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
      debugPrint('[AUTH_LOGIN] resetPassword error: ${e.message}');
      return e.message;
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
      debugPrint('Update password error: ${e.message}');
      return e.message;
    } catch (e) {
      debugPrint('Update password error: $e');
      return 'Something went wrong. Please try again.';
    }
  }

  void clearError() {
    state = state.copyWith(error: null);
  }
}
