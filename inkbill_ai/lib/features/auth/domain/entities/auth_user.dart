import 'package:equatable/equatable.dart';

class AuthUser extends Equatable {
  final String id;
  final String fullName;
  final String email;
  final String? phone;
  final String role;
  final String shopId;

  const AuthUser({
    required this.id,
    required this.fullName,
    required this.email,
    this.phone,
    required this.role,
    required this.shopId,
  });

  AuthUser copyWith({
    String? id,
    String? fullName,
    String? email,
    String? phone,
    String? role,
    String? shopId,
  }) {
    return AuthUser(
      id: id ?? this.id,
      fullName: fullName ?? this.fullName,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      role: role ?? this.role,
      shopId: shopId ?? this.shopId,
    );
  }

  @override
  List<Object?> get props => [id, fullName, email, phone, role, shopId];
}

class AuthShop extends Equatable {
  final String id;
  final String shopName;

  const AuthShop({required this.id, required this.shopName});

  @override
  List<Object?> get props => [id, shopName];
}

class AuthState extends Equatable {
  final AuthUser? user;
  final AuthShop? shop;
  final bool isLoading;
  final String? error;
  final bool isAuthenticated;

  const AuthState({
    this.user,
    this.shop,
    this.isLoading = false,
    this.error,
    this.isAuthenticated = false,
  });

  AuthState copyWith({
    AuthUser? user,
    AuthShop? shop,
    bool? isLoading,
    String? error,
    bool? isAuthenticated,
  }) {
    return AuthState(
      user: user ?? this.user,
      shop: shop ?? this.shop,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
    );
  }

  @override
  List<Object?> get props => [user, shop, isLoading, error, isAuthenticated];
}
