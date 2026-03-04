import 'dart:async';
import 'package:logger/logger.dart';
import 'package:uuid/uuid.dart';
import '../../data/api/chore_api.dart';
import '../../data/dto/dtos.dart';
import '../network/api_exceptions.dart';

/// Manages chore mutations by calling the API directly.
class SyncManager {
  final ChoreApi _choreApi;
  final Logger _log = Logger();
  final Uuid _uuid = const Uuid();

  /// Stream controller to notify UI about sync status changes.
  final _syncStatusController = StreamController<SyncStatus>.broadcast();
  Stream<SyncStatus> get syncStatusStream => _syncStatusController.stream;

  SyncManager(this._choreApi);

  // -- Operations -----------------------------------------------

  /// Generate a unique clientOperationId for idempotent requests.
  String generateOperationId() => _uuid.v4();

  Future<String> enqueueComplete(
      String householdId, String occurrenceId) async {
    final opId = generateOperationId();
    _syncStatusController.add(SyncStatus.syncing);
    try {
      await _choreApi.completeOccurrence(householdId, occurrenceId,
          MutationRequestDto(clientOperationId: opId));
      _syncStatusController.add(SyncStatus.synced);
    } on NetworkException {
      _syncStatusController.add(SyncStatus.offline);
      rethrow;
    } on UnauthorizedException {
      _syncStatusController.add(SyncStatus.authError);
      rethrow;
    } catch (e) {
      _log.e('enqueueComplete failed', error: e);
      _syncStatusController.add(SyncStatus.synced);
      rethrow;
    }
    return opId;
  }

  Future<String> enqueueUndo(String householdId, String occurrenceId) async {
    final opId = generateOperationId();
    _syncStatusController.add(SyncStatus.syncing);
    try {
      await _choreApi.undoOccurrence(householdId, occurrenceId,
          MutationRequestDto(clientOperationId: opId));
      _syncStatusController.add(SyncStatus.synced);
    } on NetworkException {
      _syncStatusController.add(SyncStatus.offline);
      rethrow;
    } on UnauthorizedException {
      _syncStatusController.add(SyncStatus.authError);
      rethrow;
    } catch (e) {
      _log.e('enqueueUndo failed', error: e);
      _syncStatusController.add(SyncStatus.synced);
      rethrow;
    }
    return opId;
  }

  Future<String> enqueueSkip(String householdId, String occurrenceId) async {
    final opId = generateOperationId();
    _syncStatusController.add(SyncStatus.syncing);
    try {
      await _choreApi.skipOccurrence(householdId, occurrenceId,
          MutationRequestDto(clientOperationId: opId));
      _syncStatusController.add(SyncStatus.synced);
    } on NetworkException {
      _syncStatusController.add(SyncStatus.offline);
      rethrow;
    } on UnauthorizedException {
      _syncStatusController.add(SyncStatus.authError);
      rethrow;
    } catch (e) {
      _log.e('enqueueSkip failed', error: e);
      _syncStatusController.add(SyncStatus.synced);
      rethrow;
    }
    return opId;
  }

  Future<String> enqueueReassign(
      String householdId, String occurrenceId, String newAssigneeId) async {
    final opId = generateOperationId();
    _syncStatusController.add(SyncStatus.syncing);
    try {
      await _choreApi.reassignOccurrence(
          householdId,
          occurrenceId,
          ReassignRequestDto(
              clientOperationId: opId, newAssigneeId: newAssigneeId));
      _syncStatusController.add(SyncStatus.synced);
    } on NetworkException {
      _syncStatusController.add(SyncStatus.offline);
      rethrow;
    } on UnauthorizedException {
      _syncStatusController.add(SyncStatus.authError);
      rethrow;
    } catch (e) {
      _log.e('enqueueReassign failed', error: e);
      _syncStatusController.add(SyncStatus.synced);
      rethrow;
    }
    return opId;
  }

  /// No-op kept for backward compatibility with provider setup.
  void startListening() {}

  void dispose() {
    _syncStatusController.close();
  }
}

enum SyncStatus {
  synced,
  syncing,
  pending,
  offline,
  conflict,
  authError,
}
