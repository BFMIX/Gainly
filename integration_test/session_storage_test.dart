import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:gainly/core/data/secure_session_storage.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets('native session and PKCE storage survive new storage instances', (
    tester,
  ) async {
    const first = SecureSessionStorage('integration-test');
    await first.initialize();
    await first.persistSession('synthetic-session-fixture');
    try {
      const restored = SecureSessionStorage('integration-test');
      expect(await restored.hasAccessToken(), isTrue);
      expect(await restored.accessToken(), 'synthetic-session-fixture');
      final verifier = SecurePkceStorage('integration-test');
      await verifier.setItem(key: 'verifier', value: 'synthetic-verifier');
      expect(
        await SecurePkceStorage('integration-test').getItem(key: 'verifier'),
        'synthetic-verifier',
      );
      await verifier.removeItem(key: 'verifier');
      expect(await verifier.getItem(key: 'verifier'), isNull);
    } finally {
      await first.removePersistedSession();
    }
    expect(await first.hasAccessToken(), isFalse);
  });
}
