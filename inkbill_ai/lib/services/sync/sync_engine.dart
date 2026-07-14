import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide Provider;
import 'package:inkbill_ai/core/supabase/supabase_config.dart';

enum SyncStatus { idle, syncing, online, offline, error }

class SyncEngine {
  final SupabaseClient _supabase;
  Timer? _retryTimer;
  bool _isSyncing = false;
  int _retryCount = 0;
  static const int _maxRetries = 5;
  static const Duration _baseDelay = Duration(seconds: 2);

  final _statusController = StreamController<SyncStatus>.broadcast();
  Stream<SyncStatus> get statusStream => _statusController.stream;

  SyncStatus _status = SyncStatus.idle;
  SyncStatus get status => _status;

  SyncEngine(this._supabase) {
    _updateStatus(SyncStatus.idle);
  }

  void _updateStatus(SyncStatus newStatus) {
    _status = newStatus;
    _statusController.add(newStatus);
  }

  Future<void> syncAll(String shopId) async {
    if (_isSyncing) return;
    _isSyncing = true;
    _updateStatus(SyncStatus.syncing);

    try {
      await Future.wait([
        _syncCustomers(shopId),
        _syncProducts(shopId),
        _syncBills(shopId),
        _syncInkDocuments(shopId),
      ]);

      _retryCount = 0;
      _updateStatus(SyncStatus.online);
    } catch (e) {
      debugPrint('Sync failed: [REDACTED]');
      _retryCount++;
      _updateStatus(SyncStatus.error);
      _scheduleRetry(shopId);
    } finally {
      _isSyncing = false;
    }
  }

  Future<List<Map<String, dynamic>>> syncCustomers(String shopId) async {
    try {
      final data = await _supabase
          .from('customers')
          .select()
          .eq('shop_id', shopId)
          .is_('deleted_at', null);
      return data as List<Map<String, dynamic>>;
    } catch (e) {
      debugPrint('Sync customers error: [REDACTED]');
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> syncProducts(String shopId) async {
    try {
      final data = await _supabase
          .from('products')
          .select()
          .eq('shop_id', shopId)
          .is_('deleted_at', null);
      return data as List<Map<String, dynamic>>;
    } catch (e) {
      debugPrint('Sync products error: [REDACTED]');
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> syncBills(String shopId) async {
    try {
      final data = await _supabase
          .from('bills')
          .select('*, bill_items(*)')
          .eq('shop_id', shopId);
      return data as List<Map<String, dynamic>>;
    } catch (e) {
      debugPrint('Sync bills error: [REDACTED]');
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> syncInkDocuments(String shopId) async {
    try {
      final data = await _supabase
          .from('ink_documents')
          .select()
          .eq('shop_id', shopId)
          .is_('deleted_at', null);
      return data as List<Map<String, dynamic>>;
    } catch (e) {
      debugPrint('Sync ink documents error: [REDACTED]');
      return [];
    }
  }

  Future<Map<String, dynamic>?> pushCustomer(
      String shopId, Map<String, dynamic> customer) async {
    try {
      final result = await _supabase
          .from('customers')
          .upsert(customer)
          .select()
          .single();
      return result as Map<String, dynamic>?;
    } catch (e) {
      debugPrint('Push customer error: [REDACTED]');
      return null;
    }
  }

  Future<Map<String, dynamic>?> pushProduct(
      String shopId, Map<String, dynamic> product) async {
    try {
      final result = await _supabase
          .from('products')
          .upsert(product)
          .select()
          .single();
      return result as Map<String, dynamic>?;
    } catch (e) {
      debugPrint('Push product error: [REDACTED]');
      return null;
    }
  }

  Future<Map<String, dynamic>?> pushBill(
      String shopId, Map<String, dynamic> bill, List<Map<String, dynamic>> items) async {
    try {
      for (final item in items) {
        item['shop_id'] = shopId;
        item['bill_id'] = bill['id'];
      }
      final result = await _supabase.rpc('upsert_bill_with_items', params: {
        'p_bill': bill,
        'p_items': items,
      });
      return result as Map<String, dynamic>?;
    } catch (e) {
      debugPrint('Push bill error: [REDACTED]');
      return null;
    }
  }

  void _scheduleRetry(String shopId) {
    _retryTimer?.cancel();
    if (_retryCount >= _maxRetries) {
      _updateStatus(SyncStatus.offline);
      return;
    }
    final delay = _baseDelay * (1 << _retryCount);
    _retryTimer = Timer(delay, () => syncAll(shopId));
  }

  void dispose() {
    _retryTimer?.cancel();
    _statusController.close();
  }
}

final syncEngineProvider = Provider<SyncEngine>((ref) {
  final supabase = ref.watch(supabaseClientProvider);
  return SyncEngine(supabase);
});
