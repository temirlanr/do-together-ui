import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../data/dto/dtos.dart';
import '../../data/dto/enums.dart';
import '../../providers/chore_provider.dart';
import '../widgets/skeleton_loading.dart';

class UpcomingScreen extends ConsumerStatefulWidget {
  const UpcomingScreen({super.key});

  @override
  ConsumerState<UpcomingScreen> createState() => _UpcomingScreenState();
}

class _UpcomingScreenState extends ConsumerState<UpcomingScreen> {
  int _selectedDays = 7;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(upcomingOccurrencesProvider.notifier).load(days: _selectedDays);
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(upcomingOccurrencesProvider);
    final theme = Theme.of(context);

    // Group by date
    final grouped = <String, List<ChoreOccurrenceDto>>{};
    for (final o in state.occurrences) {
      grouped.putIfAbsent(o.dueDate, () => []).add(o);
    }
    final sortedDates = grouped.keys.toList()..sort();

    return Scaffold(
      body: Column(
        children: [
          // Day range selector
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: SegmentedButton<int>(
              segments: const [
                ButtonSegment(value: 7, label: Text('7 days')),
                ButtonSegment(value: 14, label: Text('14 days')),
                ButtonSegment(value: 30, label: Text('30 days')),
              ],
              selected: {_selectedDays},
              onSelectionChanged: (values) {
                setState(() => _selectedDays = values.first);
                ref
                    .read(upcomingOccurrencesProvider.notifier)
                    .load(days: _selectedDays);
              },
            ),
          ),
          Expanded(
            child: IgnorePointer(
              ignoring: state.isLoading,
              child: RefreshIndicator(
                onRefresh: () => ref
                    .read(upcomingOccurrencesProvider.notifier)
                    .load(days: _selectedDays),
                child: state.isLoading && state.occurrences.isEmpty
                    ? const SkeletonListScreen(itemCount: 6)
                    : sortedDates.isEmpty
                        ? _buildEmptyState(theme)
                        : ListView.builder(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            itemCount: sortedDates.length,
                            itemBuilder: (context, index) {
                              final date = sortedDates[index];
                              final items = grouped[date]!;
                              return _buildDateSection(
                                  context, theme, date, items);
                            },
                          ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDateSection(BuildContext context, ThemeData theme, String date,
      List<ChoreOccurrenceDto> items) {
    final parsedDate = DateTime.parse(date);
    final formatter = DateFormat('EEEE, MMM d');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 16, bottom: 8),
          child: Text(
            formatter.format(parsedDate),
            style: theme.textTheme.titleSmall?.copyWith(
              color: theme.colorScheme.primary,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        ...items.map((o) => Card(
              child: ListTile(
                leading: _statusIcon(o.status, theme),
                title: Text(o.choreTitle ?? 'Untitled'),
                subtitle: Text(o.assigneeName ?? 'Unassigned'),
                trailing: _statusChip(o.status, theme),
              ),
            )),
      ],
    );
  }

  Widget _statusIcon(OccurrenceStatus status, ThemeData theme) {
    switch (status) {
      case OccurrenceStatus.completed:
        return Icon(Icons.check_circle, color: theme.colorScheme.primary);
      case OccurrenceStatus.missed:
        return Icon(Icons.warning, color: theme.colorScheme.error);
      case OccurrenceStatus.skipped:
        return Icon(Icons.skip_next, color: theme.colorScheme.outline);
      case OccurrenceStatus.pending:
        return Icon(Icons.schedule, color: theme.colorScheme.tertiary);
    }
  }

  Widget? _statusChip(OccurrenceStatus status, ThemeData theme) {
    if (status == OccurrenceStatus.pending) return null;
    final label = status.name[0].toUpperCase() + status.name.substring(1);
    return Chip(
      label: Text(label, style: const TextStyle(fontSize: 11)),
      padding: EdgeInsets.zero,
      visualDensity: VisualDensity.compact,
    );
  }

  Widget _buildEmptyState(ThemeData theme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.calendar_today,
              size: 72, color: theme.colorScheme.primary.withOpacity(0.5)),
          const SizedBox(height: 16),
          Text('Nothing upcoming', style: theme.textTheme.titleLarge),
          const SizedBox(height: 8),
          Text(
            'Create some chore templates to get started.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}
