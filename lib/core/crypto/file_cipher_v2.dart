import 'dart:convert';
import 'dart:typed_data';

import 'package:pointycastle/export.dart';

/// Version-2 file cipher: a base64url key body prefixed with `2.`, and
/// AES-256-GCM with a 12-byte nonce and a 16-byte tag.
class FileCipherV2 {
  const FileCipherV2._();

  static const prefix = '2.';
  static const nonceLength = 12;
  static const tagLength = 16;

  static bool isV2(String key) => key.trim().startsWith(prefix);

  /// Decodes the 32-byte key body. The full `2.` value is never included in
  /// errors, because it is the file key.
  static Uint8List rawKey(String key) {
    final value = key.trim();
    if (!value.startsWith(prefix)) {
      throw ArgumentError('not a version-2 key');
    }
    final body = value.substring(prefix.length);
    if (body.isEmpty || body.contains('.')) {
      throw ArgumentError('a version-2 key must have one key body');
    }
    late final Uint8List bytes;
    try {
      bytes = Uint8List.fromList(
        base64Url.decode(base64Url.normalize(body)),
      );
    } catch (_) {
      throw ArgumentError('a version-2 key must be base64url');
    }
    if (bytes.length != 32) {
      throw ArgumentError('a version-2 key must decode to exactly 32 bytes');
    }
    return bytes;
  }

  /// Decrypts `nonce || ciphertext || tag` with the key body in [key].
  static Uint8List decrypt(Uint8List packed, String key) {
    if (packed.length < nonceLength + tagLength) {
      throw const FormatException('version-2 ciphertext is too short');
    }
    final nonce = Uint8List.sublistView(packed, 0, nonceLength);
    final sealed = Uint8List.sublistView(packed, nonceLength);
    final cipher = GCMBlockCipher(AESEngine())
      ..init(
        false,
        AEADParameters(
          KeyParameter(rawKey(key)),
          tagLength * 8,
          nonce,
          Uint8List(0),
        ),
      );
    return cipher.process(sealed);
  }
}
