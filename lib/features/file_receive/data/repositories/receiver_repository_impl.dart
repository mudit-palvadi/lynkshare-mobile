import 'package:client/core/errors/failures.dart';
import 'package:client/core/errors/result.dart';
import 'package:client/features/file_receive/data/datasources/receiver_remote_data_source.dart';
import 'package:client/features/file_receive/domain/entities/receiver_session.dart';
import 'package:client/features/file_receive/domain/repositories/receiver_repository.dart';
import 'package:dio/dio.dart';

class ReceiverRepositoryImpl implements ReceiverRepository {
  final ReceiverRemoteDataSource remoteDataSource;
  ReceiverRepositoryImpl({required this.remoteDataSource});

  static ServerFailure _failure(DioException error, String fallback) {
    final status = error.response?.statusCode;
    final message = switch (status) {
      409 => 'This receiver code is already paired.',
      404 => 'This receiver code has expired. Ask the sender for a new one.',
      401 => 'This receiver code is no longer valid.',
      408 || 429 =>
        'The connection is busy. Wait a moment and try again.',
      _ => fallback,
    };
    return ServerFailure(message, statusCode: status);
  }

  static ServerFailure _unexpected(String fallback) =>
      ServerFailure(fallback);

  @override
  Future<Result<ReceiverSession>> createReceiverSession() async {
    try {
      final session = await remoteDataSource.createReceiverSession();
      return Result.success(session);
    } on DioException catch (e) {
      return Result.failure(_failure(e, 'Could not create a receiver code'));
    } catch (_) {
      return Result.failure(_unexpected('Could not create a receiver code'));
    }
  }

  @override
  Future<Result<ReceiverSession>> getReceiverSession(String sessionId) async {
    try {
      final session = await remoteDataSource.getReceiverSession(sessionId);
      return Result.success(session);
    } on DioException catch (e) {
      return Result.failure(_failure(e, 'Could not check this receiver code'));
    } catch (_) {
      return Result.failure(_unexpected('Could not check this receiver code'));
    }
  }

  @override
  Future<Result<void>> attachTransfer({
    required String sessionId,
    required String transferId,
    String? wrappedKey,
  }) async {
    try {
      await remoteDataSource.attachTransfer(
        sessionId: sessionId,
        transferId: transferId,
        wrappedKey: wrappedKey,
      );
      return Result.success(null);
    } on DioException catch (e) {
      return Result.failure(
        _failure(e, 'Could not connect this receiver code. Try again.'),
      );
    } catch (_) {
      return Result.failure(
        _unexpected('Could not connect this receiver code. Try again.'),
      );
    }
  }

  @override
  Future<Result<void>> cancelReceiverSession(String sessionId) async {
    try {
      await remoteDataSource.cancelReceiverSession(sessionId);
      return Result.success(null);
    } on DioException catch (e) {
      return Result.failure(_failure(e, 'Could not close this receiver code'));
    } catch (_) {
      return Result.failure(_unexpected('Could not close this receiver code'));
    }
  }
}
