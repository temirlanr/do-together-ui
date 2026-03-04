import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:do_together/core/sync/sync_manager.dart';
import 'package:do_together/data/api/chore_api.dart';
import 'package:do_together/data/dto/dtos.dart';
import 'package:do_together/data/dto/enums.dart';
import 'package:do_together/core/network/api_exceptions.dart';

// -- Mocks -------------------------------------------------------

class MockChoreApi extends Mock implements ChoreApi {}

class FakeMutationRequestDto extends Fake implements MutationRequestDto {}

class FakeReassignRequestDto extends Fake implements ReassignRequestDto {}

// -- Helpers -----------------------------------------------------

ChoreOccurrenceDto _makeOccurrence({
  String id = 'occ-1',
  OccurrenceStatus status = OccurrenceStatus.pending,
}) {
  return ChoreOccurrenceDto(
    id: id,
    choreTemplateId: 'tmpl-1',
    choreTitle: 'Wash dishes',
    assigneeId: 'user-1',
    assigneeName: 'Alice',
    dueDate: '2024-06-15',
    status: status,
    version: 1,
    events: [],
  );
}

/// Tests for the API-only SyncManager: direct API calls, status stream
/// emissions, and error handling.
void main() {
  late MockChoreApi mockApi;
  late SyncManager syncManager;

  setUpAll(() {
    registerFallbackValue(FakeMutationRequestDto());
    registerFallbackValue(FakeReassignRequestDto());
  });

  setUp(() {
    mockApi = MockChoreApi();
    syncManager = SyncManager(mockApi);
  });

  tearDown(() {
    syncManager.dispose();
  });

  group('enqueueComplete', () {
    test('calls API and returns a non-empty operation ID', () async {
      final response =
          _makeOccurrence(id: 'occ-1', status: OccurrenceStatus.completed);
      when(() => mockApi.completeOccurrence('hh-1', 'occ-1', any()))
          .thenAnswer((_) async => response);

      final opId = await syncManager.enqueueComplete('hh-1', 'occ-1');

      expect(opId, isNotEmpty);
      verify(() => mockApi.completeOccurrence('hh-1', 'occ-1', any()))
          .called(1);
    });

    test('emits syncing then synced on success', () async {
      final response =
          _makeOccurrence(id: 'occ-1', status: OccurrenceStatus.completed);
      when(() => mockApi.completeOccurrence('hh-1', 'occ-1', any()))
          .thenAnswer((_) async => response);

      final statuses = <SyncStatus>[];
      final sub = syncManager.syncStatusStream.listen(statuses.add);

      await syncManager.enqueueComplete('hh-1', 'occ-1');
      await Future<void>.delayed(Duration.zero);

      expect(statuses, [SyncStatus.syncing, SyncStatus.synced]);

      await sub.cancel();
    });

    test('emits offline and rethrows on NetworkException', () async {
      when(() => mockApi.completeOccurrence('hh-1', 'occ-1', any()))
          .thenThrow(const NetworkException());

      final statuses = <SyncStatus>[];
      final sub = syncManager.syncStatusStream.listen(statuses.add);

      expect(
        () => syncManager.enqueueComplete('hh-1', 'occ-1'),
        throwsA(isA<NetworkException>()),
      );

      await Future<void>.delayed(Duration.zero);
      expect(statuses, contains(SyncStatus.offline));

      await sub.cancel();
    });

    test('emits authError and rethrows on UnauthorizedException', () async {
      when(() => mockApi.completeOccurrence('hh-1', 'occ-1', any()))
          .thenThrow(const UnauthorizedException());

      final statuses = <SyncStatus>[];
      final sub = syncManager.syncStatusStream.listen(statuses.add);

      expect(
        () => syncManager.enqueueComplete('hh-1', 'occ-1'),
        throwsA(isA<UnauthorizedException>()),
      );

      await Future<void>.delayed(Duration.zero);
      expect(statuses, contains(SyncStatus.authError));

      await sub.cancel();
    });
  });

  group('enqueueUndo', () {
    test('calls undoOccurrence API and emits synced', () async {
      final response =
          _makeOccurrence(id: 'occ-1', status: OccurrenceStatus.pending);
      when(() => mockApi.undoOccurrence('hh-1', 'occ-1', any()))
          .thenAnswer((_) async => response);

      final statuses = <SyncStatus>[];
      final sub = syncManager.syncStatusStream.listen(statuses.add);

      final opId = await syncManager.enqueueUndo('hh-1', 'occ-1');

      expect(opId, isNotEmpty);
      verify(() => mockApi.undoOccurrence('hh-1', 'occ-1', any())).called(1);

      await Future<void>.delayed(Duration.zero);
      expect(statuses.last, SyncStatus.synced);

      await sub.cancel();
    });
  });

  group('enqueueSkip', () {
    test('calls skipOccurrence API and emits synced', () async {
      final response =
          _makeOccurrence(id: 'occ-1', status: OccurrenceStatus.skipped);
      when(() => mockApi.skipOccurrence('hh-1', 'occ-1', any()))
          .thenAnswer((_) async => response);

      final statuses = <SyncStatus>[];
      final sub = syncManager.syncStatusStream.listen(statuses.add);

      final opId = await syncManager.enqueueSkip('hh-1', 'occ-1');

      expect(opId, isNotEmpty);
      verify(() => mockApi.skipOccurrence('hh-1', 'occ-1', any())).called(1);

      await Future<void>.delayed(Duration.zero);
      expect(statuses.last, SyncStatus.synced);

      await sub.cancel();
    });
  });

  group('enqueueReassign', () {
    test('calls reassignOccurrence API and emits synced', () async {
      final response = _makeOccurrence(id: 'occ-1');
      when(() => mockApi.reassignOccurrence('hh-1', 'occ-1', any()))
          .thenAnswer((_) async => response);

      final statuses = <SyncStatus>[];
      final sub = syncManager.syncStatusStream.listen(statuses.add);

      final opId = await syncManager.enqueueReassign('hh-1', 'occ-1', 'user-2');

      expect(opId, isNotEmpty);
      verify(() => mockApi.reassignOccurrence('hh-1', 'occ-1', any()))
          .called(1);

      await Future<void>.delayed(Duration.zero);
      expect(statuses.last, SyncStatus.synced);

      await sub.cancel();
    });

    test('emits offline on NetworkException', () async {
      when(() => mockApi.reassignOccurrence('hh-1', 'occ-1', any()))
          .thenThrow(const NetworkException());

      final statuses = <SyncStatus>[];
      final sub = syncManager.syncStatusStream.listen(statuses.add);

      expect(
        () => syncManager.enqueueReassign('hh-1', 'occ-1', 'user-2'),
        throwsA(isA<NetworkException>()),
      );

      await Future<void>.delayed(Duration.zero);
      expect(statuses, contains(SyncStatus.offline));

      await sub.cancel();
    });
  });

  group('idempotency', () {
    test('each call generates a unique clientOperationId', () async {
      final response =
          _makeOccurrence(id: 'occ-1', status: OccurrenceStatus.completed);
      when(() => mockApi.completeOccurrence('hh-1', 'occ-1', any()))
          .thenAnswer((_) async => response);

      final opId1 = await syncManager.enqueueComplete('hh-1', 'occ-1');
      final opId2 = await syncManager.enqueueComplete('hh-1', 'occ-1');

      expect(opId1, isNot(equals(opId2)));
    });
  });
}
