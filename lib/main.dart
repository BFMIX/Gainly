import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'app/gainly_app.dart';
import 'core/data/cached_ledger_repository.dart';
import 'core/data/hive_ledger_local_store.dart';
import 'core/data/secure_session_storage.dart';
import 'features/notifications/notification_coordinator.dart';
import 'features/notifications/notification_delivery.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  const url = String.fromEnvironment('SUPABASE_URL');
  const key = String.fromEnvironment('SUPABASE_PUBLISHABLE_KEY');
  SupabaseClient? client;
  LedgerLocalStore? localStore;
  NotificationCoordinator? notifications;
  try {
    localStore = await HiveLedgerLocalStore.initialize();
  } catch (_) {
    /* Online operation remains available if local storage cannot open. */
  }
  if (url.isNotEmpty && key.isNotEmpty && !url.contains('YOUR_PROJECT')) {
    try {
      await Supabase.initialize(
        url: url,
        publishableKey: key,
        debug: false,
        authOptions: FlutterAuthClientOptions(
          authFlowType: AuthFlowType.pkce,
          pkceAsyncStorage: SecurePkceStorage(Uri.parse(url).host),
          localStorage: SecureSessionStorage(Uri.parse(url).host),
        ),
      );
      client = Supabase.instance.client;
    } catch (_) {
      /* Show a localized setup state; never log credentials. */
    }
  }
  try {
    final delivery = LocalNotificationDelivery();
    await delivery.initialize();
    notifications = NotificationCoordinator(delivery);
  } catch (_) {
    /* Financial tracking remains available if notifications cannot start. */
  }
  runApp(
    GainlyApp(
      client: client,
      localStore: localStore,
      notifications: notifications,
    ),
  );
}
