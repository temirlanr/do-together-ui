import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../data/dto/dtos.dart';
import '../../data/dto/enums.dart';
import '../../providers/chore_provider.dart';
import '../../providers/household_provider.dart';

/// Create or edit a chore template.
/// Shows "edit only this occurrence" vs "edit future" info banner for edits.
class TemplateFormScreen extends ConsumerStatefulWidget {
  final ChoreTemplateDto? existing;

  const TemplateFormScreen({super.key, this.existing});

  @override
  ConsumerState<TemplateFormScreen> createState() => _TemplateFormScreenState();
}

class _TemplateFormScreenState extends ConsumerState<TemplateFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleController;
  late final TextEditingController _descController;

  RecurrenceType _recurrenceType = RecurrenceType.daily;
  int _interval = 1;
  Set<int> _daysOfWeek = {};
  int? _dayOfMonth;
  String? _assigneeId;
  DateTime _startDate = DateTime.now();
  DateTime? _endDate;
  bool _isActive = true;

  bool get _isEditing => widget.existing != null;

  @override
  void initState() {
    super.initState();
    _titleController =
        TextEditingController(text: widget.existing?.title ?? '');
    _descController =
        TextEditingController(text: widget.existing?.description ?? '');

    if (widget.existing != null) {
      final e = widget.existing!;
      if (e.recurrenceRule != null) {
        _recurrenceType = e.recurrenceRule!.type;
        _interval = e.recurrenceRule!.interval;
        _daysOfWeek = (e.recurrenceRule!.daysOfWeek ?? []).toSet();
        _dayOfMonth = e.recurrenceRule!.dayOfMonth;
      }
      _assigneeId = e.assigneeId;
      _startDate = DateTime.parse(e.startDate);
      _endDate = e.endDate != null ? DateTime.parse(e.endDate!) : null;
      _isActive = e.isActive;
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final household = ref.watch(householdProvider).household;
    final members = household?.members ?? [];
    final templateState = ref.watch(templateProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Edit Template' : 'Create Template'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Info banner for edit mode
            if (_isEditing)
              Card(
                color: theme.colorScheme.tertiaryContainer,
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline,
                          color: theme.colorScheme.onTertiaryContainer),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Editing this template affects all future occurrences. '
                          'Past occurrences remain unchanged.\n\n'
                          'Per-occurrence editing (e.g., "edit only this one") is '
                          'planned for a future release.',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onTertiaryContainer,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            const SizedBox(height: 16),

            // Title
            TextFormField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'Chore title *',
                hintText: 'e.g., Vacuum living room',
              ),
              validator: (v) =>
                  v == null || v.trim().isEmpty ? 'Title is required' : null,
            ),
            const SizedBox(height: 16),

            // Description
            TextFormField(
              controller: _descController,
              decoration: const InputDecoration(
                labelText: 'Description (optional)',
                hintText: 'Any additional details...',
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 24),

            // Recurrence Type
            Text('Recurrence', style: theme.textTheme.titleSmall),
            const SizedBox(height: 8),
            SegmentedButton<RecurrenceType>(
              segments: RecurrenceType.values
                  .map((t) => ButtonSegment(
                        value: t,
                        label: Text(t.label),
                      ))
                  .toList(),
              selected: {_recurrenceType},
              onSelectionChanged: (values) {
                setState(() {
                  _recurrenceType = values.first;
                  _daysOfWeek = {};
                  _dayOfMonth = null;
                });
              },
            ),
            const SizedBox(height: 12),

            // Interval
            Row(
              children: [
                const Text('Every '),
                SizedBox(
                  width: 60,
                  child: TextFormField(
                    initialValue: '$_interval',
                    keyboardType: TextInputType.number,
                    textAlign: TextAlign.center,
                    onChanged: (v) => _interval = int.tryParse(v) ?? 1,
                  ),
                ),
                Text(
                    ' ${_recurrenceType == RecurrenceType.daily ? 'day(s)' : _recurrenceType == RecurrenceType.monthly ? 'month(s)' : 'week(s)'}'),
              ],
            ),
            const SizedBox(height: 12),

            // Days of week (for weekly/biweekly)
            if (_recurrenceType == RecurrenceType.weekly) ...[
              Text('Days of week', style: theme.textTheme.bodyMedium),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: List.generate(7, (i) {
                  const dayNames = [
                    'Mon',
                    'Tue',
                    'Wed',
                    'Thu',
                    'Fri',
                    'Sat',
                    'Sun'
                  ];
                  return FilterChip(
                    label: Text(dayNames[i]),
                    selected: _daysOfWeek.contains(i),
                    onSelected: (selected) {
                      setState(() {
                        if (selected) {
                          _daysOfWeek.add(i);
                        } else {
                          _daysOfWeek.remove(i);
                        }
                      });
                    },
                  );
                }),
              ),
              const SizedBox(height: 12),
            ],

            // Day of month (for monthly)
            if (_recurrenceType == RecurrenceType.monthly) ...[
              Row(
                children: [
                  const Text('Day of month: '),
                  SizedBox(
                    width: 60,
                    child: TextFormField(
                      initialValue: _dayOfMonth?.toString() ?? '',
                      keyboardType: TextInputType.number,
                      textAlign: TextAlign.center,
                      onChanged: (v) => _dayOfMonth = int.tryParse(v),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
            ],

            const Divider(),
            const SizedBox(height: 12),

            // Assignee
            Text('Assignee', style: theme.textTheme.titleSmall),
            const SizedBox(height: 8),
            DropdownButtonFormField<String?>(
              value: _assigneeId,
              decoration: const InputDecoration(
                labelText: 'Assign to',
              ),
              items: [
                const DropdownMenuItem(value: null, child: Text('Unassigned')),
                ...members.map((m) => DropdownMenuItem(
                      value: m.userId,
                      child: Text(m.displayName ?? m.email ?? 'Unknown'),
                    )),
              ],
              onChanged: (v) => setState(() => _assigneeId = v),
            ),
            const SizedBox(height: 16),

            // Start date
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Start date'),
              subtitle: Text(DateFormat('yyyy-MM-dd').format(_startDate)),
              trailing: const Icon(Icons.calendar_today),
              onTap: () async {
                if (_isEditing) return; // Can't change start date on edit
                final picked = await showDatePicker(
                  context: context,
                  initialDate: _startDate,
                  firstDate: DateTime(2024),
                  lastDate: DateTime(2030),
                );
                if (picked != null) setState(() => _startDate = picked);
              },
            ),

            // End date
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('End date (optional)'),
              subtitle: Text(_endDate != null
                  ? DateFormat('yyyy-MM-dd').format(_endDate!)
                  : 'None'),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (_endDate != null)
                    IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () => setState(() => _endDate = null),
                    ),
                  const Icon(Icons.calendar_today),
                ],
              ),
              onTap: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: _endDate ?? _startDate,
                  firstDate: _startDate,
                  lastDate: DateTime(2030),
                );
                if (picked != null) setState(() => _endDate = picked);
              },
            ),

            // Active toggle (edit only)
            if (_isEditing) ...[
              const Divider(),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Active'),
                subtitle: const Text(
                    'Inactive templates stop generating new occurrences'),
                value: _isActive,
                onChanged: (v) => setState(() => _isActive = v),
              ),
            ],

            const SizedBox(height: 24),

            // Submit
            FilledButton(
              onPressed: templateState.isLoading ? null : _submit,
              child: templateState.isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(_isEditing ? 'Save Changes' : 'Create Template'),
            ),

            if (templateState.error != null) ...[
              const SizedBox(height: 16),
              Text(
                templateState.error!,
                style: TextStyle(color: theme.colorScheme.error),
                textAlign: TextAlign.center,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final dateFmt = DateFormat('yyyy-MM-dd');
    final rule = RecurrenceRuleDto(
      type: _recurrenceType,
      interval: _interval,
      daysOfWeek:
          _daysOfWeek.isNotEmpty ? (_daysOfWeek.toList()..sort()) : null,
      dayOfMonth: _dayOfMonth,
    );

    bool success;
    if (_isEditing) {
      success = await ref.read(templateProvider.notifier).update(
            widget.existing!.id,
            UpdateChoreTemplateDto(
              title: _titleController.text.trim(),
              description: _descController.text.trim().isEmpty
                  ? null
                  : _descController.text.trim(),
              recurrenceRule: rule,
              assigneeId: _assigneeId,
              endDate: _endDate != null ? dateFmt.format(_endDate!) : null,
              isActive: _isActive,
            ),
          );
    } else {
      success = await ref.read(templateProvider.notifier).create(
            CreateChoreTemplateDto(
              title: _titleController.text.trim(),
              description: _descController.text.trim().isEmpty
                  ? null
                  : _descController.text.trim(),
              recurrenceRule: rule,
              assigneeId: _assigneeId,
              startDate: dateFmt.format(_startDate),
              endDate: _endDate != null ? dateFmt.format(_endDate!) : null,
            ),
          );
    }

    if (success && mounted) {
      context.pop();
    }
  }
}
