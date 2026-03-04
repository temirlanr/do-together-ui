import 'package:flutter/material.dart';
import '../../data/dto/dtos.dart';
import '../../data/dto/enums.dart';

/// A tile widget for displaying a chore occurrence with action buttons.
class OccurrenceTile extends StatelessWidget {
  final ChoreOccurrenceDto occurrence;
  final VoidCallback? onComplete;
  final VoidCallback? onUndo;
  final VoidCallback? onSkip;
  final void Function(String newAssigneeId)? onReassign;
  final List<HouseholdMemberDto>? members;
  final bool isSyncing;

  const OccurrenceTile({
    super.key,
    required this.occurrence,
    this.onComplete,
    this.onUndo,
    this.onSkip,
    this.onReassign,
    this.members,
    this.isSyncing = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isOverdue = _isOverdue();

    return Card(
      color: _cardColor(theme),
      child: ListTile(
        leading: _statusIcon(theme),
        title: Text(
          occurrence.choreTitle ?? 'Untitled Chore',
          style: TextStyle(
            decoration: occurrence.status == OccurrenceStatus.completed
                ? TextDecoration.lineThrough
                : null,
            fontWeight: isOverdue ? FontWeight.bold : null,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (occurrence.assigneeName != null)
              Text(
                occurrence.assigneeName!,
                style: theme.textTheme.bodySmall,
              ),
            Row(
              children: [
                Text(
                  occurrence.dueDate,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: isOverdue
                        ? theme.colorScheme.error
                        : theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                if (isOverdue)
                  Padding(
                    padding: const EdgeInsets.only(left: 8),
                    child: Text(
                      'OVERDUE',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.error,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                if (isSyncing)
                  Padding(
                    padding: const EdgeInsets.only(left: 8),
                    child: SizedBox(
                      width: 12,
                      height: 12,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: theme.colorScheme.tertiary,
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
        trailing: _actionButtons(context),
        isThreeLine: true,
      ),
    );
  }

  bool _isOverdue() {
    if (occurrence.status != OccurrenceStatus.pending) return false;
    final today = DateTime.now();
    final todayStr =
        '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';
    return occurrence.dueDate.compareTo(todayStr) < 0;
  }

  Color? _cardColor(ThemeData theme) {
    switch (occurrence.status) {
      case OccurrenceStatus.completed:
        return theme.colorScheme.primaryContainer.withOpacity(0.3);
      case OccurrenceStatus.missed:
        return theme.colorScheme.errorContainer.withOpacity(0.3);
      case OccurrenceStatus.skipped:
        return theme.colorScheme.surfaceContainerHighest.withOpacity(0.5);
      case OccurrenceStatus.pending:
        return _isOverdue()
            ? theme.colorScheme.errorContainer.withOpacity(0.15)
            : null;
    }
  }

  Widget _statusIcon(ThemeData theme) {
    switch (occurrence.status) {
      case OccurrenceStatus.completed:
        return Icon(Icons.check_circle, color: theme.colorScheme.primary);
      case OccurrenceStatus.missed:
        return Icon(Icons.warning_rounded, color: theme.colorScheme.error);
      case OccurrenceStatus.skipped:
        return Icon(Icons.skip_next, color: theme.colorScheme.outline);
      case OccurrenceStatus.pending:
        return _isOverdue()
            ? Icon(Icons.error_outline, color: theme.colorScheme.error)
            : Icon(Icons.radio_button_unchecked,
                color: theme.colorScheme.outline);
    }
  }

  Widget? _actionButtons(BuildContext context) {
    if (occurrence.status == OccurrenceStatus.completed) {
      return onUndo != null
          ? IconButton(
              icon: const Icon(Icons.undo),
              tooltip: 'Undo',
              onPressed: onUndo,
            )
          : null;
    }

    if (occurrence.status == OccurrenceStatus.pending) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (onComplete != null)
            IconButton(
              icon: const Icon(Icons.check_circle_outline),
              tooltip: 'Complete',
              onPressed: onComplete,
            ),
          PopupMenuButton<String>(
            itemBuilder: (context) => [
              if (onSkip != null)
                const PopupMenuItem(value: 'skip', child: Text('Skip')),
              if (onReassign != null && members != null)
                const PopupMenuItem(value: 'reassign', child: Text('Reassign')),
            ],
            onSelected: (value) {
              if (value == 'skip') {
                onSkip?.call();
              } else if (value == 'reassign') {
                _showReassignDialog(context);
              }
            },
          ),
        ],
      );
    }

    return null;
  }

  void _showReassignDialog(BuildContext context) {
    if (members == null || members!.isEmpty) return;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Reassign To'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: members!
              .where((m) => m.userId != occurrence.assigneeId)
              .map((m) => ListTile(
                    title: Text(m.displayName ?? m.email ?? 'Unknown'),
                    onTap: () {
                      Navigator.of(ctx).pop();
                      onReassign?.call(m.userId);
                    },
                  ))
              .toList(),
        ),
      ),
    );
  }
}
