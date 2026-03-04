import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/dto/enums.dart';
import '../../providers/chore_provider.dart';
import '../../providers/household_provider.dart';
import '../widgets/occurrence_tile.dart';
import '../widgets/skeleton_loading.dart';
import '../widgets/sync_status_banner.dart';

class TodayScreen extends ConsumerStatefulWidget {
  const TodayScreen({super.key});

  @override
  ConsumerState<TodayScreen> createState() => _TodayScreenState();
}

class _TodayScreenState extends ConsumerState<TodayScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(todayOccurrencesProvider.notifier).load();
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(todayOccurrencesProvider);
    final household = ref.watch(householdProvider).household;
    final theme = Theme.of(context);

    // Separate overdue and today's chores
    final today = DateTime.now();
    final todayStr =
        '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';
    final overdue = state.occurrences
        .where((o) =>
            o.dueDate.compareTo(todayStr) < 0 &&
            o.status == OccurrenceStatus.pending)
        .toList();
    final todayItems =
        state.occurrences.where((o) => o.dueDate == todayStr).toList();

    return Scaffold(
      body: IgnorePointer(
        ignoring: state.isLoading,
        child: Column(
          children: [
            const SyncStatusBanner(),
            Expanded(
              child: RefreshIndicator(
                onRefresh: () =>
                    ref.read(todayOccurrencesProvider.notifier).load(),
                child: state.isLoading && state.occurrences.isEmpty
                    ? const SkeletonListScreen(itemCount: 6)
                    : state.occurrences.isEmpty
                        ? _buildEmptyState(theme)
                        : ListView(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 8),
                            children: [
                              if (overdue.isNotEmpty) ...[
                                Padding(
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 8),
                                  child: Text(
                                    'Overdue (${overdue.length})',
                                    style:
                                        theme.textTheme.titleMedium?.copyWith(
                                      color: theme.colorScheme.error,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                ...overdue.map((o) => OccurrenceTile(
                                      occurrence: o,
                                      members: household?.members,
                                      onComplete: () => ref
                                          .read(
                                              todayOccurrencesProvider.notifier)
                                          .complete(o.id),
                                      onUndo: () => ref
                                          .read(
                                              todayOccurrencesProvider.notifier)
                                          .undo(o.id),
                                      onSkip: () => ref
                                          .read(
                                              todayOccurrencesProvider.notifier)
                                          .skip(o.id),
                                      onReassign: (newId) => ref
                                          .read(
                                              todayOccurrencesProvider.notifier)
                                          .reassign(o.id, newId),
                                    )),
                                const Divider(),
                              ],
                              Padding(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 8),
                                child: Text(
                                  'Today (${todayItems.length})',
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              if (todayItems.isEmpty)
                                Padding(
                                  padding: const EdgeInsets.all(16),
                                  child: Text(
                                    'No chores due today!',
                                    style: theme.textTheme.bodyLarge?.copyWith(
                                      color: theme.colorScheme.onSurfaceVariant,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                              ...todayItems.map((o) => OccurrenceTile(
                                    occurrence: o,
                                    members: household?.members,
                                    onComplete:
                                        o.status == OccurrenceStatus.pending
                                            ? () => ref
                                                .read(todayOccurrencesProvider
                                                    .notifier)
                                                .complete(o.id)
                                            : null,
                                    onUndo:
                                        o.status == OccurrenceStatus.completed
                                            ? () => ref
                                                .read(todayOccurrencesProvider
                                                    .notifier)
                                                .undo(o.id)
                                            : null,
                                    onSkip: o.status == OccurrenceStatus.pending
                                        ? () => ref
                                            .read(todayOccurrencesProvider
                                                .notifier)
                                            .skip(o.id)
                                        : null,
                                    onReassign:
                                        o.status == OccurrenceStatus.pending
                                            ? (newId) => ref
                                                .read(todayOccurrencesProvider
                                                    .notifier)
                                                .reassign(o.id, newId)
                                            : null,
                                  )),
                            ],
                          ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(ThemeData theme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.check_circle_outline,
              size: 72, color: theme.colorScheme.primary.withOpacity(0.5)),
          const SizedBox(height: 16),
          Text(
            'All caught up!',
            style: theme.textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          Text(
            'No chores due today.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}
