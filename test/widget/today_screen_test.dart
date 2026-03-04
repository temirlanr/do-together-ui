import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:do_together/data/dto/dtos.dart';
import 'package:do_together/data/dto/enums.dart';
import 'package:do_together/data/api/chore_api.dart';
import 'package:do_together/data/api/calendar_api.dart';
import 'package:do_together/data/api/household_api.dart';
import 'package:do_together/core/sync/sync_manager.dart';
import 'package:do_together/core/storage/secure_storage.dart';
import 'package:do_together/providers/chore_provider.dart';
import 'package:do_together/providers/core_providers.dart';
import 'package:do_together/providers/household_provider.dart';
import 'package:do_together/ui/today/today_screen.dart';

// ── Mocks ────────────────────────────────────────────────────

class MockChoreApi extends Mock implements ChoreApi {}

class MockCalendarApi extends Mock implements CalendarApi {}

class MockSyncManager extends Mock implements SyncManager {}

// ── Helpers ──────────────────────────────────────────────────

String _todayStr() {
  final now = DateTime.now();
  return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
}

ChoreOccurrenceDto _makeOccurrence({
  String id = 'occ-1',
  String title = 'Wash dishes',
  OccurrenceStatus status = OccurrenceStatus.pending,
  String? dueDate,
}) {
  return ChoreOccurrenceDto(
    id: id,
    choreTemplateId: 'tmpl-1',
    choreTitle: title,
    assigneeId: 'user-1',
    assigneeName: 'Alice',
    dueDate: dueDate ?? _todayStr(),
    status: status,
    version: 1,
    events: [],
  );
}

final _householdDto = HouseholdDto(
  id: 'hh-1',
  name: 'Test Household',
  timeZoneId: 'UTC',
  members: [
    HouseholdMemberDto(
      userId: 'user-1',
      displayName: 'Alice',
      email: 'alice@test.com',
      role: MemberRole.admin,
      joinedAtUtc: DateTime(2024),
    ),
    HouseholdMemberDto(
      userId: 'user-2',
      displayName: 'Bob',
      email: 'bob@test.com',
      role: MemberRole.member,
      joinedAtUtc: DateTime(2024),
    ),
  ],
);

/// Build TodayScreen inside a ProviderScope with the given occurrences pre-loaded.
Widget _buildTestWidget({
  required List<ChoreOccurrenceDto> occurrences,
  HouseholdDto? household,
}) {
  return ProviderScope(
    overrides: [
      // Override the today provider with a pre-loaded state
      todayOccurrencesProvider.overrideWith(
        (ref) => _FakeTodayNotifier(occurrences),
      ),
      householdProvider.overrideWith(
        (ref) => _FakeHouseholdNotifier(household: household ?? _householdDto),
      ),
      syncStatusProvider.overrideWith(
        (ref) => Stream.value(SyncStatus.synced),
      ),
    ],
    child: const MaterialApp(
      home: TodayScreen(),
    ),
  );
}

/// A fake notifier that starts with provided data.
class _FakeTodayNotifier extends TodayOccurrencesNotifier {
  _FakeTodayNotifier(List<ChoreOccurrenceDto> items)
      : super(
          MockCalendarApi(),
          MockSyncManager(),
          'hh-1',
        ) {
    state = OccurrenceListState(occurrences: items);
  }

  bool completeCalled = false;
  bool undoCalled = false;
  bool skipCalled = false;

  @override
  Future<void> load() async {
    // No-op for tests
  }

  @override
  Future<void> complete(String occurrenceId) async {
    completeCalled = true;
    // Simulate optimistic update
    state = state.copyWith(
      occurrences: state.occurrences.map((o) {
        if (o.id == occurrenceId) {
          return ChoreOccurrenceDto(
            id: o.id,
            choreTemplateId: o.choreTemplateId,
            choreTitle: o.choreTitle,
            assigneeId: o.assigneeId,
            assigneeName: o.assigneeName,
            dueDate: o.dueDate,
            status: OccurrenceStatus.completed,
            version: o.version,
            events: o.events,
          );
        }
        return o;
      }).toList(),
    );
  }

  @override
  Future<void> undo(String occurrenceId) async {
    undoCalled = true;
    state = state.copyWith(
      occurrences: state.occurrences.map((o) {
        if (o.id == occurrenceId) {
          return ChoreOccurrenceDto(
            id: o.id,
            choreTemplateId: o.choreTemplateId,
            choreTitle: o.choreTitle,
            assigneeId: o.assigneeId,
            assigneeName: o.assigneeName,
            dueDate: o.dueDate,
            status: OccurrenceStatus.pending,
            version: o.version,
            events: o.events,
          );
        }
        return o;
      }).toList(),
    );
  }

  @override
  Future<void> skip(String occurrenceId) async {
    skipCalled = true;
    state = state.copyWith(
      occurrences: state.occurrences.map((o) {
        if (o.id == occurrenceId) {
          return ChoreOccurrenceDto(
            id: o.id,
            choreTemplateId: o.choreTemplateId,
            choreTitle: o.choreTitle,
            assigneeId: o.assigneeId,
            assigneeName: o.assigneeName,
            dueDate: o.dueDate,
            status: OccurrenceStatus.skipped,
            version: o.version,
            events: o.events,
          );
        }
        return o;
      }).toList(),
    );
  }
}

class _FakeHouseholdNotifier extends HouseholdNotifier {
  _FakeHouseholdNotifier({required HouseholdDto household})
      : super(MockHouseholdApi(), MockSecureStorage()) {
    state = HouseholdState(household: household);
  }
}

class MockHouseholdApi extends Mock implements HouseholdApi {}

class MockSecureStorage extends Mock implements SecureStorage {}

// ── Tests ────────────────────────────────────────────────────

void main() {
  group('TodayScreen', () {
    testWidgets('shows empty state when no occurrences', (tester) async {
      await tester.pumpWidget(_buildTestWidget(occurrences: []));
      await tester.pumpAndSettle();

      expect(find.text('All caught up!'), findsOneWidget);
    });

    testWidgets('displays today occurrences with title and assignee',
        (tester) async {
      final occ = _makeOccurrence(title: 'Wash dishes');
      await tester.pumpWidget(_buildTestWidget(occurrences: [occ]));
      await tester.pumpAndSettle();

      expect(find.text('Wash dishes'), findsOneWidget);
      expect(find.text('Alice'), findsOneWidget);
    });

    testWidgets('shows overdue section for past-due pending items',
        (tester) async {
      final yesterday = DateTime.now().subtract(const Duration(days: 1));
      final yesterdayStr =
          '${yesterday.year}-${yesterday.month.toString().padLeft(2, '0')}-${yesterday.day.toString().padLeft(2, '0')}';

      final overdue = _makeOccurrence(
        id: 'occ-overdue',
        title: 'Vacuum',
        dueDate: yesterdayStr,
        status: OccurrenceStatus.pending,
      );
      final todayOcc = _makeOccurrence(id: 'occ-today', title: 'Dishes');

      await tester
          .pumpWidget(_buildTestWidget(occurrences: [overdue, todayOcc]));
      await tester.pumpAndSettle();

      expect(find.textContaining('Overdue'), findsOneWidget);
      expect(find.text('Vacuum'), findsOneWidget);
      expect(find.text('Dishes'), findsOneWidget);
    });

    testWidgets('tapping complete button marks occurrence completed',
        (tester) async {
      final occ =
          _makeOccurrence(title: 'Mop floor', status: OccurrenceStatus.pending);
      await tester.pumpWidget(_buildTestWidget(occurrences: [occ]));
      await tester.pumpAndSettle();

      // Find the complete button (check_circle_outline icon)
      final completeBtn = find.byIcon(Icons.check_circle_outline);
      expect(completeBtn, findsOneWidget);

      await tester.tap(completeBtn);
      await tester.pumpAndSettle();

      // After optimistic update the status icon should become check_circle (completed)
      expect(find.byIcon(Icons.check_circle), findsOneWidget);
    });

    testWidgets('tapping undo on completed item reverts to pending',
        (tester) async {
      final occ = _makeOccurrence(
        title: 'Take out trash',
        status: OccurrenceStatus.completed,
      );
      await tester.pumpWidget(_buildTestWidget(occurrences: [occ]));
      await tester.pumpAndSettle();

      // Completed items show undo button
      final undoBtn = find.byIcon(Icons.undo);
      expect(undoBtn, findsOneWidget);

      await tester.tap(undoBtn);
      await tester.pumpAndSettle();

      // After undo, should revert to pending: radio_button_unchecked or check_circle_outline
      expect(find.byIcon(Icons.radio_button_unchecked), findsOneWidget);
    });

    testWidgets('shows multiple occurrences from different templates',
        (tester) async {
      final occurrences = [
        _makeOccurrence(id: 'occ-1', title: 'Dishes'),
        _makeOccurrence(id: 'occ-2', title: 'Vacuum'),
        _makeOccurrence(id: 'occ-3', title: 'Laundry'),
      ];

      await tester.pumpWidget(_buildTestWidget(occurrences: occurrences));
      await tester.pumpAndSettle();

      expect(find.text('Dishes'), findsOneWidget);
      expect(find.text('Vacuum'), findsOneWidget);
      expect(find.text('Laundry'), findsOneWidget);
      expect(find.textContaining('Today (3)'), findsOneWidget);
    });

    testWidgets('completed occurrence has strikethrough text style',
        (tester) async {
      final occ = _makeOccurrence(
        title: 'Sweep floor',
        status: OccurrenceStatus.completed,
      );
      await tester.pumpWidget(_buildTestWidget(occurrences: [occ]));
      await tester.pumpAndSettle();

      final textWidget = tester.widget<Text>(find.text('Sweep floor'));
      expect(textWidget.style?.decoration, TextDecoration.lineThrough);
    });
  });
}
