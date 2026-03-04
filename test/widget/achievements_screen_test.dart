import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:do_together/data/api/achievement_api.dart';
import 'package:do_together/data/dto/achievement_dtos.dart';
import 'package:do_together/providers/achievement_provider.dart';
import 'package:do_together/ui/achievements/achievements_screen.dart';

//  Mocks

class MockAchievementApi extends Mock implements AchievementApi {}

//  Fake notifier
//
// Extends the real AchievementsNotifier so overrideWith type-checks.
// _initial is placed in the initializer list (runs before super()), so it is
// available when super() calls load() which we override below.

class _FakeAchievementsNotifier extends AchievementsNotifier {
  final AchievementsState _initial;

  _FakeAchievementsNotifier(AchievementsState initial)
      : _initial = initial,
        super(MockAchievementApi(), '');

  @override
  Future<void> load() async => state = _initial;

  @override
  Future<void> refresh() async => state = _initial;

  @override
  void setScope(AchievementScope scope) => state = state.copyWith(scope: scope);
}

//  Widget builder

Widget _buildScreen(AchievementsState initial) {
  return ProviderScope(
    overrides: [
      achievementsProvider
          .overrideWith((ref) => _FakeAchievementsNotifier(initial)),
    ],
    child: const MaterialApp(
      home: Scaffold(body: AchievementsScreen()),
    ),
  );
}

//  Sample data factories

AchievementsData _sampleData() => AchievementsData(
      todayWins: TodayWinsDto(
        completedCountToday: 3,
        completions: [
          TodayCompletionDto(
            occurrenceId: 'occ-1',
            title: 'Wash dishes',
            completedAtUtc: DateTime.now().subtract(const Duration(hours: 1)),
            scheduledDate: '2026-03-03',
            wasLate: false,
          ),
          TodayCompletionDto(
            occurrenceId: 'occ-2',
            title: 'Vacuum bedroom',
            completedAtUtc: DateTime.now().subtract(const Duration(hours: 2)),
            scheduledDate: '2026-03-03',
            wasLate: true,
          ),
        ],
      ),
      summary: const AchievementSummaryDto(
        totalCompleted: 5,
        totalScheduled: 7,
        completionRate: 0.71,
        completedByDay: [],
        topTemplates: [],
        onTimeCompleted: 4,
        lateCompleted: 1,
      ),
      streaks: const StreaksDto(
        currentStreakDays: 5,
        longestStreakDays: 12,
        currentOnTimeStreakDays: 3,
      ),
      badges: const BadgesResponseDto(
        earnedBadges: [
          BadgeDto(
              key: 'completions_10',
              title: 'First 10',
              description: 'Completed 10 chores'),
        ],
        progressBadges: [
          BadgeProgressDto(
            key: 'completions_25',
            title: 'Top 25',
            description: 'Complete 25 chores',
            current: 11,
            target: 25,
          ),
        ],
      ),
    );

AchievementsData _emptyData() => const AchievementsData(
      todayWins: TodayWinsDto(completedCountToday: 0, completions: []),
      summary: AchievementSummaryDto(
        totalCompleted: 0,
        totalScheduled: 0,
        completionRate: 0,
        completedByDay: [],
        topTemplates: [],
        onTimeCompleted: 0,
        lateCompleted: 0,
      ),
      streaks: StreaksDto(
          currentStreakDays: 0,
          longestStreakDays: 0,
          currentOnTimeStreakDays: 0),
      badges: BadgesResponseDto(earnedBadges: [], progressBadges: []),
    );

//  Tests

void main() {
  group('AchievementsScreen', () {
    testWidgets('shows loading indicator while loading with no cached data',
        (tester) async {
      const state = AchievementsState(isLoading: true, data: null);
      await tester.pumpWidget(_buildScreen(state));
      await tester.pump();

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.text("Today's Wins"), findsNothing);
    });

    testWidgets('shows all sections in loaded state', (tester) async {
      // Use a tall surface so SliverList renders all children.
      await tester.binding.setSurfaceSize(const Size(400, 3000));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      final state = AchievementsState(
        isLoading: false,
        data: _sampleData(),
        lastUpdated: DateTime.now(),
      );
      await tester.pumpWidget(_buildScreen(state));
      await tester.pump();

      expect(find.text("Today's Wins"), findsOneWidget);
      expect(find.text('Wash dishes'), findsOneWidget);
      expect(find.text('Vacuum bedroom'), findsOneWidget);
      expect(find.text('late'), findsOneWidget);
      expect(find.text('This Week'), findsOneWidget);
      expect(find.text('71%'), findsOneWidget);
      expect(find.text('Streaks'), findsOneWidget);
      expect(find.text('Badges Earned'), findsOneWidget);
      expect(find.text('First 10'), findsOneWidget);
      expect(find.text('In Progress'), findsOneWidget);
      expect(find.text('Top 25'), findsOneWidget);
      expect(find.text('Share Summary'), findsOneWidget);
    });

    testWidgets('shows scope toggle with all three options', (tester) async {
      final state = AchievementsState(
        isLoading: false,
        data: _sampleData(),
        lastUpdated: DateTime.now(),
      );
      await tester.pumpWidget(_buildScreen(state));
      await tester.pump();

      expect(find.text('Me'), findsOneWidget);
      expect(find.text('Partner'), findsOneWidget);
      expect(find.text('Household'), findsOneWidget);
    });

    testWidgets('shows empty state when no completions ever', (tester) async {
      final state = AchievementsState(
        isLoading: false,
        data: _emptyData(),
        lastUpdated: DateTime.now(),
      );
      await tester.pumpWidget(_buildScreen(state));
      await tester.pump();

      expect(find.text('No achievements yet'), findsOneWidget);
      expect(find.textContaining('Complete your first chore'), findsOneWidget);
      expect(find.text("Today's Wins"), findsNothing);
    });

    testWidgets('shows error state when load fails with no cache',
        (tester) async {
      const state = AchievementsState(
        isLoading: false,
        data: null,
        error: 'No internet connection',
      );
      await tester.pumpWidget(_buildScreen(state));
      await tester.pump();

      expect(find.text('Could not load achievements'), findsOneWidget);
      expect(find.text('No internet connection'), findsOneWidget);
      expect(find.text('Try Again'), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsNothing);
    });

    testWidgets('shows offline banner when showing cached data',
        (tester) async {
      await tester.binding.setSurfaceSize(const Size(400, 3000));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      final ts = DateTime(2026, 3, 3, 10, 30);
      final state = AchievementsState(
        isLoading: false,
        data: _sampleData(),
        isFromCache: true,
        lastUpdated: ts,
        error: 'No internet connection',
      );
      await tester.pumpWidget(_buildScreen(state));
      await tester.pump();

      expect(find.textContaining('Offline'), findsOneWidget);
      expect(find.text("Today's Wins"), findsOneWidget);
    });

    testWidgets('tapping scope toggle updates scope without errors',
        (tester) async {
      final state = AchievementsState(
        isLoading: false,
        data: _sampleData(),
        scope: AchievementScope.household,
        lastUpdated: DateTime.now(),
      );
      await tester.pumpWidget(_buildScreen(state));
      await tester.pump();

      await tester.tap(find.text('Me'));
      await tester.pump();
    });
  });
}
