import 'package:equatable/equatable.dart';
import '../../features/file_transfer/domain/entities/file_item.dart';
import '../../features/file_transfer/domain/entities/transfer.dart';

enum DownloadPhase {
  idle,
  preview,

  /// The sender has not uploaded its files yet. This is a temporary state,
  /// not a failure: the sender may still be waiting for a direct connection
  /// before it starts uploading.
  waiting,
  downloading,
  completed,
  failed,
  cancelled,
}

class DownloadState extends Equatable {
  final Transfer? transfer;
  final List<FileItem> downloadFiles;
  final String? aesKey;
  final String? accessToken;
  final int currentFileIndex;
  final double overallProgress;
  final DownloadPhase phase;
  final List<String> downloadedPaths;
  final String? errorMessage;
  /// True when the files arrived over the direct P2P channel.
  final bool direct;

  const DownloadState({
    this.transfer,
    this.downloadFiles = const [],
    this.aesKey,
    this.accessToken,
    this.currentFileIndex = 0,
    this.overallProgress = 0.0,
    this.phase = DownloadPhase.idle,
    this.downloadedPaths = const [],
    this.errorMessage,
    this.direct = false,
  });

  DownloadState copyWith({
    Transfer? transfer,
    List<FileItem>? downloadFiles,
    String? aesKey,
    String? accessToken,
    int? currentFileIndex,
    double? overallProgress,
    DownloadPhase? phase,
    List<String>? downloadedPaths,
    String? errorMessage,
    bool? direct,
  }) {
    return DownloadState(
      transfer: transfer ?? this.transfer,
      downloadFiles: downloadFiles ?? this.downloadFiles,
      aesKey: aesKey ?? this.aesKey,
      accessToken: accessToken ?? this.accessToken,
      currentFileIndex: currentFileIndex ?? this.currentFileIndex,
      overallProgress: overallProgress ?? this.overallProgress,
      phase: phase ?? this.phase,
      downloadedPaths: downloadedPaths ?? this.downloadedPaths,
      errorMessage: errorMessage ?? this.errorMessage,
      direct: direct ?? this.direct,
    );
  }

  @override
  List<Object?> get props => [
    transfer,
    downloadFiles,
    aesKey,
    accessToken,
    currentFileIndex,
    overallProgress,
    phase,
    downloadedPaths,
    errorMessage,
    direct,
  ];
}
