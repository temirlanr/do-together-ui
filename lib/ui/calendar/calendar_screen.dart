import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';
import '../../data/dto/dtos.dart';
import '../../data/dto/enums.dart';
import '../../providers/calendar_provider.dart';
import '../widgets/skeleton_loading.dart';

class CalendarScreen extends ConsumerStatefulWidget {
  const CalendarScreen({super.key});

  @override
  ConsumerState<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends ConsumerState<CalendarScreen> {
  CalendarFormat _calendarFormat = CalendarFormat.month;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final notifier = ref.read(calendarProvider.notifier);
      notifier.loadMonth();
      notifier.selectDay(DateTime.now());
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(calendarProvider);
    final theme = Theme.of(context);

    return Scaffold(
      body: Column(
        children: [
          // Calendar view
          TableCalendar(
            firstDay: DateTime(2024, 1, 1),
            lastDay: DateTime(2030, 12, 31),
            focusedDay: state.focusedMonth,
            calendarFormat: _calendarFormat,
            selectedDayPredicate: (day) => isSameDay(day, state.selectedDate),
            onDaySelected: (selectedDay, focusedDay) {
              ref.read(calendarProvider.notifier).selectDay(selectedDay);
            },
            onFormatChanged: (format) {
              setState(() => _calendarFormat = format);
            },
            onPageChanged: (focusedDay) {
              ref
                  .read(calendarProvider.notifier)
                  .changeFocusedMonth(focusedDay);
            },
            calendarStyle: CalendarStyle(
              todayDecoration: BoxDecoration(
                color: theme.colorScheme.primaryContainer,
                shape: BoxShape.circle,
              ),
              todayTextStyle: TextStyle(
                color: theme.colorScheme.onPrimaryContainer,
              ),
              selectedDecoration: BoxDecoration(
                color: theme.colorScheme.primary,
                shape: BoxShape.circle,
              ),
              markerDecoration: BoxDecoration(
                shape: BoxShape.circle,
                color: theme.colorScheme.tertiary,
              ),
            ),
            calendarBuilders: CalendarBuilders(
              markerBuilder: (context, date, events) {
                final dateStr = DateFormat('yyyy-MM-dd').format(date);
                final agg = state.aggregates[dateStr];
                if (agg == null || agg.total == 0) return null;

                return Positioned(
                  bottom: 1,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (agg.done > 0) _dot(theme.colorScheme.primary),
                      if (agg.missed > 0) _dot(theme.colorScheme.error),
                      if (agg.due > 0) _dot(theme.colorScheme.tertiary),
                      if (agg.skipped > 0) _dot(theme.colorScheme.outline),
                    ],
                  ),
                );
              },
            ),
          ),
          const Divider(),
          // Aggregate summary for selected day
          _buildDaySummary(theme, state),
          const Divider(height: 1),
          // Occurrences list for selected day
          Expanded(
            child: state.isLoading && state.selectedDayOccurrences.isEmpty
                ? const SkeletonListScreen(itemCount: 3)
                : state.selectedDayOccurrences.isEmpty
                    ? Center(
                        child: Text(
                          'No chores on this day',
                          style: theme.textTheme.bodyLarge?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: state.selectedDayOccurrences.length,
                        itemBuilder: (context, index) {
                          final occ = state.selectedDayOccurrences[index];
                          return _buildOccurrenceItem(theme, occ);
                        },
                      ),
          ),
        ],
      ),
    );
  }

  Widget _dot(Color color) {
    return Container(
      width: 6,
      height: 6,
      margin: const EdgeInsets.symmetric(horizontal: 1),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color,
      ),
    );
  }

  Widget _buildDaySummary(ThemeData theme, CalendarState state) {
    final dateStr = DateFormat('yyyy-MM-dd').format(state.selectedDate);
    final agg = state.aggregates[dateStr];
    final dayLabel = DateFormat('EEEE, MMM d').format(state.selectedDate);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(dayLabel, style: theme.textTheme.titleSmall),
          const SizedBox(height: 4),
          if (agg != null)
            Row(
              children: [
                _statChip('Due', agg.due, theme.colorScheme.tertiary, theme),
                const SizedBox(width: 8),
                _statChip('Done', agg.done, theme.colorScheme.primary, theme),
                const SizedBox(width: 8),
                _statChip('Missed', agg.missed, theme.colorScheme.error, theme),
                const SizedBox(width: 8),
                _statChip(
                    'Skipped', agg.skipped, theme.colorScheme.outline, theme),
              ],
            )
          else
            Text(
              'No data',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
        ],
      ),
    );
  }

  Widget _statChip(String label, int count, Color color, ThemeData theme) {
    return Chip(
      avatar: CircleAvatar(
        backgroundColor: color,
        radius: 6,
        child: Text(
          '$count',
          style: const TextStyle(fontSize: 9, color: Colors.white),
        ),
      ),
      label: Text(label, style: const TextStyle(fontSize: 11)),
      visualDensity: VisualDensity.compact,
      padding: EdgeInsets.zero,
    );
  }

  Widget _buildOccurrenceItem(ThemeData theme, ChoreOccurrenceDto occ) {
    return Card(
      child: ListTile(
        leading: _statusIcon(occ.status, theme),
        title: Text(occ.choreTitle ?? 'Untitled'),
        subtitle: Text(occ.assigneeName ?? 'Unassigned'),
        trailing: Text(
          occ.status.name[0].toUpperCase() + occ.status.name.substring(1),
          style: theme.textTheme.labelMedium?.copyWith(
            color: _statusColor(occ.status, theme),
          ),
        ),
        onTap: () => _showEventHistory(context, theme, occ),
      ),
    );
  }

  Widget _statusIcon(OccurrenceStatus status, ThemeData theme) {
    switch (status) {
      case OccurrenceStatus.completed:
        return Icon(Icons.check_circle, color: theme.colorScheme.primary);
      case OccurrenceStatus.missed:
        return Icon(Icons.warning_rounded, color: theme.colorScheme.error);
      case OccurrenceStatus.skipped:
        return Icon(Icons.skip_next, color: theme.colorScheme.outline);
      case OccurrenceStatus.pending:
        return Icon(Icons.radio_button_unchecked,
            color: theme.colorScheme.tertiary);
    }
  }

  Color _statusColor(OccurrenceStatus status, ThemeData theme) {
    switch (status) {
      case OccurrenceStatus.completed:
        return theme.colorScheme.primary;
      case OccurrenceStatus.missed:
        return theme.colorScheme.error;
      case OccurrenceStatus.skipped:
        return theme.colorScheme.outline;
      case OccurrenceStatus.pending:
        return theme.colorScheme.tertiary;
    }
  }

  /// Show event history for an occurrence in a bottom sheet.
  void _showEventHistory(
      BuildContext context, ThemeData theme, ChoreOccurrenceDto occ) {
    if (occ.events == null || occ.events!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No event history available')),
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${occ.choreTitle ?? "Chore"} — History',
              style: theme.textTheme.titleMedium,
            ),
            const Divider(),
            ...occ.events!.map((e) => ListTile(
                  dense: true,
                  leading: Icon(_eventIcon(e.eventType)),
                  title: Text(e.eventType.name),
                  subtitle: Text(
                    '${e.performedByName ?? "Unknown"} • ${DateFormat('MMM d, HH:mm').format(e.occurredAtUtc.toLocal())}',
                  ),
                )),
          ],
        ),
      ),
    );
  }

  IconData _eventIcon(ChoreEventType type) {
    switch (type) {
      case ChoreEventType.created:
        return Icons.add;
      case ChoreEventType.completed:
        return Icons.check;
      case ChoreEventType.undone:
        return Icons.undo;
      case ChoreEventType.skipped:
        return Icons.skip_next;
      case ChoreEventType.reassigned:
        return Icons.swap_horiz;
      case ChoreEventType.edited:
        return Icons.auto_fix_high;
      case ChoreEventType.missed:
        return Icons.warning;
    }
  }
}
