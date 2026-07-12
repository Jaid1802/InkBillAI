import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:inkbill_ai/features/auth/data/datasources/auth_local_datasource.dart';

void main() {
  group('AuthLocalDataSource', () {
    test('clearAll should not throw', () async {
      final storage = FlutterSecureStorage();
      final ds = AuthLocalDataSource(storage: storage);
      await ds.clearAll();
    });

    test('hasSession returns false for fresh storage', () async {
      final storage = FlutterSecureStorage();
      final ds = AuthLocalDataSource(storage: storage);
      final hasSession = await ds.hasSession();
      expect(hasSession, false);
    });
  });
}
