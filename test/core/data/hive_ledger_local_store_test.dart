import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:gainly/core/data/hive_ledger_local_store.dart';
import 'package:hive_ce_flutter/hive_flutter.dart';

void main() {
  test(
    'encrypted cache survives a box restart without plaintext data',
    () async {
      final directory = await Directory.systemTemp.createTemp(
        'gainly-ledger-cache-',
      );
      addTearDown(() async {
        await Hive.close();
        await directory.delete(recursive: true);
      });
      final key = List<int>.generate(32, (index) => index);
      const payload = '{"private_financial_value":"987654321"}';
      Hive.init(directory.path);
      var box = await Hive.openBox<String>(
        'ledger',
        encryptionCipher: HiveAesCipher(key),
      );
      var store = HiveLedgerLocalStore(box);
      await store.write('owner', payload);
      await box.close();

      final bytes = <int>[];
      await for (final file in directory.list()) {
        if (file is File) bytes.addAll(await file.readAsBytes());
      }
      expect(String.fromCharCodes(bytes), isNot(contains('987654321')));

      box = await Hive.openBox<String>(
        'ledger',
        encryptionCipher: HiveAesCipher(key),
      );
      store = HiveLedgerLocalStore(box);
      expect(await store.read('owner'), payload);
    },
  );
}
