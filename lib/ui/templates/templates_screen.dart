import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../data/dto/dtos.dart';
import '../../providers/chore_provider.dart';
import '../widgets/skeleton_loading.dart';

class TemplatesScreen extends ConsumerStatefulWidget {
  const TemplatesScreen({super.key});

  @override
  ConsumerState<TemplatesScreen> createState() => _TemplatesScreenState();
}

class _TemplatesScreenState extends ConsumerState<TemplatesScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(templateProvider.notifier).load();
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(templateProvider);
    final theme = Theme.of(context);

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: () => ref.read(templateProvider.notifier).load(),
        child: state.isLoading && state.templates.isEmpty
            ? const SkeletonListScreen(itemCount: 4)
            : state.templates.isEmpty
                ? _buildEmptyState(theme)
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: state.templates.length,
                    itemBuilder: (context, index) {
                      final template = state.templates[index];
                      return _buildTemplateCard(context, theme, template);
                    },
                  ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push('/templates/create'),
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildTemplateCard(
      BuildContext context, ThemeData theme, ChoreTemplateDto template) {
    return Card(
      child: ListTile(
        title: Text(
          template.title ?? 'Untitled',
          style: TextStyle(
            decoration: !template.isActive ? TextDecoration.lineThrough : null,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (template.recurrenceRule != null)
              Text(
                template.recurrenceRule!.displayText,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.primary,
                ),
              ),
            Row(
              children: [
                if (template.assigneeName != null)
                  Text(template.assigneeName!,
                      style: theme.textTheme.bodySmall),
                if (!template.isActive)
                  Padding(
                    padding: const EdgeInsets.only(left: 8),
                    child: Chip(
                      label: const Text('Inactive'),
                      visualDensity: VisualDensity.compact,
                      padding: EdgeInsets.zero,
                      labelStyle: const TextStyle(fontSize: 10),
                    ),
                  ),
              ],
            ),
          ],
        ),
        isThreeLine: true,
        trailing: PopupMenuButton<String>(
          itemBuilder: (context) => [
            const PopupMenuItem(value: 'edit', child: Text('Edit template')),
            const PopupMenuItem(
              value: 'delete',
              child: Text('Delete template'),
            ),
          ],
          onSelected: (value) {
            if (value == 'edit') {
              context.push('/templates/edit', extra: template);
            } else if (value == 'delete') {
              _confirmDelete(context, template);
            }
          },
        ),
        onTap: () => context.push('/templates/edit', extra: template),
      ),
    );
  }

  void _confirmDelete(BuildContext context, ChoreTemplateDto template) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Template'),
        content: Text(
            'Delete "${template.title}"? This will not remove past occurrences.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              ref.read(templateProvider.notifier).deleteTemplate(template.id);
            },
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(ThemeData theme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.assignment_outlined,
              size: 72, color: theme.colorScheme.primary.withOpacity(0.5)),
          const SizedBox(height: 16),
          Text('No chore templates', style: theme.textTheme.titleLarge),
          const SizedBox(height: 8),
          Text(
            'Tap + to create your first recurring chore.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}
