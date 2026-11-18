import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:client/core/crypto/file_cipher_v2.dart';
import 'package:client/features/file_receive/domain/usecases/decrypt_file_use_case.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const key = '2.AAECAwQFBgcICQoLDA0ODxAREhMUFRYXGBkaGxwdHh8';
  final packed = base64Decode(
    base64.normalize(
      'AQIDBAUGBwgJCgsMbY82uYO0nP8iyUMxIn1eIKdT9V04oJrTI7ax2NQ',
    ),
  );
  final plain = Uint8List.fromList(utf8.encode('hello lynk v2'));
  final decrypt = DecryptFileUseCase();

  test('version-2 keys decode to 32 raw bytes', () {
    final bytes = FileCipherV2.rawKey(key);
    expect(bytes.length, 32);
    expect(bytes.first, 0);
    expect(bytes.last, 31);
  });

  test('version-2 ciphertext decrypts with the web layout', () {
    expect(FileCipherV2.decrypt(packed, key), plain);
  });

  test('the receive use case decrypts version 2 in memory', () {
    expect(
      decrypt.executeBytes(encryptedBytes: packed, aesKey32Bytes: key),
      plain,
    );
  });

  test('the receive use case decrypts a version-2 file', () async {
    final directory = await Directory.systemTemp.createTemp('lynk-v2-test-');
    addTearDown(() => directory.delete(recursive: true));
    final input = await File(
      '${directory.path}/input.enc',
    ).writeAsBytes(packed);
    final output = await decrypt.execute(
      encryptedFile: input,
      aesKey32Bytes: key,
      outputPath: '${directory.path}/output',
    );

    expect(await output.readAsBytes(), plain);
  });

  test('a tampered version-2 tag is rejected', () {
    final corrupted = Uint8List.fromList(packed);
    corrupted[corrupted.length - 1] ^= 0x01;
    expect(
      () => decrypt.executeBytes(encryptedBytes: corrupted, aesKey32Bytes: key),
      throwsA(anything),
    );
  });

  test('a malformed version-2 key is rejected without echoing it', () {
    expect(
      () => FileCipherV2.rawKey('2.short'),
      throwsA(
        isA<ArgumentError>().having(
          (error) => error.toString(),
          'message',
          isNot(contains('short')),
        ),
      ),
    );
  });
}
