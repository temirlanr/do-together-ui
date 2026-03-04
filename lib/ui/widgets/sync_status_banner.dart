import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/sync/sync_manager.dart';
import '../../providers/core_providers.dart';

/// A banner displayed at the top of screens when there are pending sync items.
class SyncStatusBanner extends ConsumerWidget {
  const SyncStatusBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final syncStatus = ref.watch(syncStatusProvider);

    return syncStatus.when(
      data: (status) => _buildBanner(context, status),
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }

  Widget _buildBanner(BuildContext context, SyncStatus status) {
    final theme = Theme.of(context);

    switch (status) {
      case SyncStatus.synced:
        return const SizedBox.shrink();
      case SyncStatus.syncing:
        return MaterialBanner(
          content: const Row(
            children: [
              SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
              SizedBox(width: 12),
              Text('Syncing changes...'),
            ],
          ),
          backgroundColor: theme.colorScheme.tertiaryContainer,
          actions: const [SizedBox.shrink()],
        );
      case SyncStatus.pending:
        return MaterialBanner(
          content: const Text('Changes pending sync'),
          backgroundColor: theme.colorScheme.tertiaryContainer,
          actions: const [SizedBox.shrink()],
        );
      case SyncStatus.offline:
        return MaterialBanner(
          content: const Text('Offline — changes saved locally'),
          backgroundColor: theme.colorScheme.surfaceContainerHighest,
          leading: Icon(Icons.cloud_off, color: theme.colorScheme.outline),
          actions: const [SizedBox.shrink()],
        );
      case SyncStatus.conflict:
        return MaterialBanner(
          content: const Text('A chore was modified elsewhere. Refreshing...'),
          backgroundColor: theme.colorScheme.errorContainer,
          actions: const [SizedBox.shrink()],
        );
      case SyncStatus.authError:
        return MaterialBanner(
          content: const Text('Session expired. Please log in again.'),
          backgroundColor: theme.colorScheme.errorContainer,
          actions: const [SizedBox.shrink()],
        );
    }
  }
}
