import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'app/gainly_app.dart';
import 'core/data/secure_session_storage.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  const url = String.fromEnvironment('SUPABASE_URL');
  const key = String.fromEnvironment('SUPABASE_PUBLISHABLE_KEY');
  SupabaseClient? client;
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
  runApp(GainlyApp(client: client));
}
