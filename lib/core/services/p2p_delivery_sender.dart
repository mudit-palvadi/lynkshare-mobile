import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';

import 'chunk_sender.dart';
import 'name_sealer.dart';
import 'transfer_framer.dart';

/// Owns the sender's framing and confirmation, independently of native RTC.
/// A successful send means the peer confirmed all decrypted/delivered files,
/// not merely that the local plugin accepted the outgoing bytes.
class P2PDeliverySender {
  P2PDeliverySender({
    required this.sendText,
    required this.sendBinary,
    required this.bufferedAmount,
    required this.isOpen,
    this.aesKey,
    this.helloTimeout = const Duration(seconds: 2),
    this.confirmationTimeout = const Duration(seconds: 30),
  });

  final Future<void> Function(String) sendText;
  final Future<void> Function(Uint8List) sendBinary;
  final int Function() bufferedAmount;
  final bool Function() isOpen;
  final String? aesKey;
  final Duration helloTimeout;
  final Duration confirmationTimeout;
  final _hello = Completer<ParsedFrame>();
  final Set<int> _completed = <int>{};
  int? _expectedFiles;
  int? _expectedBytes;
  String? _expectedDigest;
  bool _prepared = false;
  bool _confirmed = false;
  bool _lost = false;
  bool _sending = false;

  Set<int> get completedIndexes => Set<int>.unmodifiable(_completed);

  void accept(ParsedFrame frame) {
    if (frame.kind == FrameKind.hello && !_hello.isCompleted) {
      _hello.complete(frame);
    } else if (frame.kind == FrameKind.fileAck) {
      _completed.add(frame.index);
    } else if (frame.kind == FrameKind.receipt &&
        frame.files == _expectedFiles &&
        frame.bytes == _expectedBytes &&
        frame.digest != null &&
        frame.digest == _expectedDigest) {
      _confirmed = true;
    }
  }

  void cancel() => _lost = true;

  Future<void> sendFiles(
    List<File> files, {
    List<String>? names,
    List<int>? indexes,
    void Function(int)? onProgress,
    bool Function()? shouldAbort,
  }) async {
    if (_sending) throw StateError('P2P send already started');
    _sending = true;
    if (files.isEmpty ||
        files.length > 10 ||
        (names != null && names.length != files.length) ||
        (indexes != null && indexes.length != files.length)) {
      _sending = false;
      throw ArgumentError('one name and index are needed for each file');
    }
    final positions =
        indexes ?? List<int>.generate(files.length, (index) => index);
    bool abort() => _lost || !isOpen() || (shouldAbort?.call() ?? false);
    void check() {
      if (abort()) throw const SocketException('P2P send stopped');
    }

    try {
      check();
      final hello = await _hello.future.timeout(helloTimeout);
      check();
      if (!hello.receipts) {
        throw StateError('peer cannot confirm direct delivery');
      }
      if (!_prepared) {
        var total = 0;
        final digestOut = _DigestSlot();
        final digestIn = sha256.startChunkedConversion(digestOut);
        for (final file in files) {
          await for (final bytes in file.openRead()) {
            digestIn.add(bytes);
            total += bytes.length;
          }
        }
        digestIn.close();
        _expectedFiles = files.length;
        _expectedBytes = total;
        _expectedDigest = digestOut.value.toString();
        _prepared = true;
      }
      var cumulative = 0;
      for (var index = 0; index < files.length; index++) {
        check();
        final file = files[index];
        final name =
            names?[index] ?? file.path.split(Platform.pathSeparator).last;
        final size = await file.length();
        final token = hello.version >= 2 && aesKey != null
            ? NameSealer.seal(name, aesKey)
            : null;
        check();
        await sendText(
          TransferFramer.encodeHeader(
            FramedFileMeta(
              name: name,
              size: size,
              token: token,
              index: positions[index],
              hasIndex: true,
            ),
          ).text!,
        );
        final chunks = ChunkSender(
          bufferedAmount: bufferedAmount,
          send: sendBinary,
          shouldAbort: abort,
          onProgress: (sent) => onProgress?.call(cumulative + sent),
        );
        await for (final bytes in file.openRead()) {
          await chunks.sendAll(Uint8List.fromList(bytes));
        }
        cumulative += size;
        check();
        await sendText(
          TransferFramer.encodeEof(
            FramedFileMeta(
              name: name,
              size: 0,
              token: token,
              index: positions[index],
              hasIndex: true,
            ),
          ).text!,
        );
      }
      await sendText(TransferFramer.encodeDone().text!);
      final elapsed = Stopwatch()..start();
      while (!_confirmed) {
        check();
        if (elapsed.elapsed >= confirmationTimeout) {
          throw TimeoutException('receiver did not confirm direct delivery');
        }
        // Keep the native channel alive until the receiver confirms delivery.
        // bufferedAmount == 0 alone is never a delivery acknowledgement.
        await Future<void>.delayed(const Duration(milliseconds: 10));
      }
    } finally {
      _sending = false;
    }
  }
}

class _DigestSlot implements Sink<Digest> {
  Digest? value;

  @override
  void add(Digest data) => value = data;

  @override
  void close() {}
}
