import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';
import '../../core/notifications/notification_service.dart';
import '../../core/notifications/push_notification_service.dart';
import '../../data/dto/dtos.dart';
import '../../data/dto/enums.dart';
import '../../providers/auth_provider.dart';
import '../../providers/core_providers.dart';
import '../../providers/household_provider.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  bool _notificationsEnabled = false;
  bool _loadingNotifPermission = false;
  bool _pushRegistered = false;
  bool _pushLoading = false;
  String? _fcmToken;

  @override
  void initState() {
    super.initState();
    _loadNotificationStatus();
    _loadFcmToken();
  }

  Future<void> _loadNotificationStatus() async {
    try {
      final ns = NotificationService();
      await ns.initialize();
      final granted = await ns.checkPermissionStatus();
      if (mounted) setState(() => _notificationsEnabled = granted);
    } catch (_) {}
  }

  Future<void> _loadFcmToken() async {
    setState(() => _pushLoading = true);
    try {
      final token = await PushNotificationService().getToken();
      if (mounted) {
        setState(() {
          _fcmToken = token;
          _pushLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _pushLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final household = ref.watch(householdProvider).household;
    final authState = ref.watch(authProvider);

    return Scaffold(
      appBar: AppBar(
        leading: const BackButton(),
        title: const Text('Settings'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // User info
          Card(
            child: ListTile(
              leading: CircleAvatar(
                child: Text(
                  (authState.user?.displayName ?? authState.user?.email ?? '?')
                      .substring(0, 1)
                      .toUpperCase(),
                ),
              ),
              title: Text(authState.user?.displayName ??
                  authState.user?.email ??
                  'User'),
              subtitle: Text(authState.user?.email ?? ''),
            ),
          ),
          const SizedBox(height: 16),

          // Household info
          Text('Household', style: theme.textTheme.titleSmall),
          const SizedBox(height: 8),
          if (household != null) ...[
            Card(
              child: Column(
                children: [
                  ListTile(
                    title: Text(household.name ?? 'Unnamed'),
                    subtitle:
                        Text('Timezone: ${household.timeZoneId ?? "Unknown"}'),
                    leading: const Icon(Icons.home),
                  ),
                  const Divider(height: 1),
                  if (household.members != null)
                    ...household.members!.map((m) => ListTile(
                          dense: true,
                          title: Text(m.displayName ?? m.email ?? 'Unknown'),
                          subtitle: Text(
                              m.role == MemberRole.admin ? 'Admin' : 'Member'),
                          leading: const Icon(Icons.person_outline),
                        )),
                ],
              ),
            ),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              icon: const Icon(Icons.person_add),
              label: const Text('Invite Member'),
              onPressed: () => _showInviteDialog(context),
            ),
          ],
          const SizedBox(height: 24),

          // Notifications
          Text('Notifications', style: theme.textTheme.titleSmall),
          const SizedBox(height: 8),
          Card(
            child: Column(
              children: [
                SwitchListTile(
                  title: const Text('Local reminders'),
                  subtitle: const Text(
                      'Get reminded about due chores on this device'),
                  value: _notificationsEnabled,
                  onChanged: (v) => _toggleNotifications(v),
                ),
                if (_loadingNotifPermission)
                  const Padding(
                    padding: EdgeInsets.all(8),
                    child: LinearProgressIndicator(),
                  ),
                ListTile(
                  title: const Text('Push notifications'),
                  subtitle: Text(
                    _pushLoading
                        ? 'Checking…'
                        : _fcmToken != null
                            ? _pushRegistered
                                ? 'Registered — awaiting server messages'
                                : 'Token ready — tap Register to activate'
                            : 'Firebase not configured (see README)',
                  ),
                  leading: Icon(
                    Icons.cloud,
                    color: _pushRegistered
                        ? Theme.of(context).colorScheme.primary
                        : null,
                  ),
                  trailing: _pushLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : _fcmToken != null
                          ? Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.copy, size: 18),
                                  tooltip: 'Copy token',
                                  onPressed: () {
                                    Clipboard.setData(
                                        ClipboardData(text: _fcmToken!));
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                          content: Text('FCM token copied')),
                                    );
                                  },
                                ),
                                if (!_pushRegistered)
                                  FilledButton.tonal(
                                    onPressed: () => _registerDevice(context),
                                    child: const Text('Register'),
                                  ),
                                if (_pushRegistered)
                                  const Icon(Icons.check_circle,
                                      color: Colors.green),
                              ],
                            )
                          : Icon(Icons.info_outline,
                              color: Theme.of(context).colorScheme.outline),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Danger zone
          Text('Account', style: theme.textTheme.titleSmall),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            icon: const Icon(Icons.logout),
            label: const Text('Sign Out'),
            onPressed: () => _confirmLogout(context),
          ),
        ],
      ),
    );
  }

  Future<void> _registerDevice(BuildContext context) async {
    if (_fcmToken == null) return;
    setState(() => _pushLoading = true);
    try {
      final deviceApi = ref.read(deviceApiProvider);
      final success =
          await PushNotificationService().registerWithBackend(deviceApi);
      if (mounted) {
        setState(() {
          _pushRegistered = success;
          _pushLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(success
              ? 'Push notifications registered!'
              : 'Registration failed — check server logs'),
        ));
      }
    } catch (_) {
      if (mounted) setState(() => _pushLoading = false);
    }
  }

  Future<void> _toggleNotifications(bool enable) async {
    setState(() => _loadingNotifPermission = true);
    final ns = NotificationService();
    await ns.initialize();

    if (enable) {
      final granted = await ns.requestPermissions();
      setState(() {
        _notificationsEnabled = granted;
        _loadingNotifPermission = false;
      });
      if (!granted && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text(
                  'Notification permission denied. Enable in system settings.')),
        );
      }
    } else {
      await ns.cancelAll();
      setState(() {
        _notificationsEnabled = false;
        _loadingNotifPermission = false;
      });
    }
  }

  void _showInviteDialog(BuildContext context) {
    final emailController = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Invite Member'),
        content: TextField(
          controller: emailController,
          keyboardType: TextInputType.emailAddress,
          decoration: const InputDecoration(
            labelText: 'Email address',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              final email = emailController.text.trim();
              if (email.isEmpty) return;
              Navigator.of(ctx).pop();

              final invite = await ref
                  .read(householdProvider.notifier)
                  .inviteMember(email);
              if (invite != null && mounted) {
                _showInviteResult(invite);
              }
            },
            child: const Text('Send Invite'),
          ),
        ],
      ),
    );
  }

  void _showInviteResult(InviteResponseDto invite) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Invite Sent!'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Share this token with your household partner:'),
            const SizedBox(height: 12),
            SelectableText(
              invite.token ?? '',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Close'),
          ),
          FilledButton.icon(
            icon: const Icon(Icons.share),
            label: const Text('Share'),
            onPressed: () {
              Navigator.of(ctx).pop();
              SharePlus.instance.share(ShareParams(
                text: 'Join my household on DoTogether! '
                    'Use this invite token: ${invite.token}',
              ));
            },
          ),
        ],
      ),
    );
  }

  void _confirmLogout(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Sign Out'),
        content: const Text('Are you sure you want to sign out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              ref.read(authProvider.notifier).logout();
            },
            child: const Text('Sign Out'),
          ),
        ],
      ),
    );
  }
}
