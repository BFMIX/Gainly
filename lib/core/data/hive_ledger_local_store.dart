import 'dart:convert';
import 'dart:math';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:hive_ce_flutter/hive_flutter.dart';

import 'cached_ledger_repository.dart';

class HiveLedgerLocalStore implements LedgerLocalStore {
  const HiveLedgerLocalStore(this.box);

  final Box<String> box;

  static Future<HiveLedgerLocalStore> initialize({
    FlutterSecureStorage secureStorage = const FlutterSecureStorage(),
  }) async {
    const encryptionKeyName = 'gainly.ledger-cache.encryption-key.v1';
    var encodedKey = await secureStorage.read(key: encryptionKeyName);
    if (encodedKey == null) {
      final random = Random.secure();
      encodedKey = base64UrlEncode(
        List<int>.generate(32, (_) => random.nextInt(256)),
      );
      await secureStorage.write(key: encryptionKeyName, value: encodedKey);
    }
    final key = base64Url.decode(encodedKey);
    if (key.length != 32) {
      throw const FormatException('Invalid ledger cache encryption key');
    }
    await Hive.initFlutter();
    final box = await Hive.openBox<String>(
      'gainly_ledger_cache_v1',
      encryptionCipher: HiveAesCipher(key),
    );
    return HiveLedgerLocalStore(box);
  }

  @override
  Future<String?> read(String userId) async => box.get(userId);

  @override
  Future<void> write(String userId, String value) => box.put(userId, value);
}
