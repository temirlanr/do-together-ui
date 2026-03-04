import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';

import '../../data/dto/achievement_dtos.dart';
import '../../providers/achievement_provider.dart';
import '../widgets/skeleton_loading.dart';

class AchievementsScreen extends ConsumerStatefulWidget {
  const AchievementsScreen({super.key});

  @override
  ConsumerState<AchievementsScreen> createState() => _AchievementsScreenState();
}

class _AchievementsScreenState extends ConsumerState<AchievementsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(achievementsProvider.notifier).load();
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(achievementsProvider);

    return RefreshIndicator(
      onRefresh: () => ref.read(achievementsProvider.notifier).refresh(),
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          // ── Scope toggle ──────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: _ScopeToggle(
                selected: state.scope,
                onChanged: (s) =>
                    ref.read(achievementsProvider.notifier).setScope(s),
              ),
            ),
          ),

          // ── Offline banner ────────────────────────────
          if (state.isFromCache && state.lastUpdated != null)
            SliverToBoxAdapter(
              child: _OfflineBanner(lastUpdated: state.lastUpdated!),
            ),

          // ── Body ──────────────────────────────────────
          if (state.isLoading && state.data == null)
            const SliverFillRemaining(
              child: SkeletonAchievements(),
            )
          else if (state.data == null && state.error != null)
            SliverFillRemaining(
              child: _ErrorState(
                message: state.error!,
                onRetry: () =>
                    ref.read(achievementsProvider.notifier).refresh(),
              ),
            )
          else if (state.data != null && state.data!.isEmpty)
            const SliverFillRemaining(child: _EmptyState())
          else if (state.data != null)
            SliverPadding(
              padding: const EdgeInsets.all(16),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  _TodayWinsCard(wins: state.data!.todayWins),
                  const SizedBox(height: 12),
                  _WeekSummaryCard(summary: state.data!.summary),
                  const SizedBox(height: 12),
                  _StreaksCard(streaks: state.data!.streaks),
                  const SizedBox(height: 12),
                  _BadgesSection(badges: state.data!.badges),
                  const SizedBox(height: 12),
                  _ShareButton(data: state.data!, scope: state.scope),
                  const SizedBox(height: 24),
                ]),
              ),
            ),
        ],
      ),
    );
  }
}

// ── Scope Toggle ──────────────────────────────────────────

class _ScopeToggle extends StatelessWidget {
  final AchievementScope selected;
  final ValueChanged<AchievementScope> onChanged;

  const _ScopeToggle({required this.selected, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return SegmentedButton<AchievementScope>(
      segments: AchievementScope.values
          .map((s) => ButtonSegment(value: s, label: Text(s.label)))
          .toList(),
      selected: {selected},
      onSelectionChanged: (v) => onChanged(v.first),
      style: SegmentedButton.styleFrom(
        backgroundColor: cs.surfaceContainerHighest,
        selectedBackgroundColor: cs.primaryContainer,
        selectedForegroundColor: cs.onPrimaryContainer,
      ),
    );
  }
}

// ── Offline Banner ────────────────────────────────────────

class _OfflineBanner extends StatelessWidget {
  final DateTime lastUpdated;
  const _OfflineBanner({required this.lastUpdated});

  @override
  Widget build(BuildContext context) {
    final fmt = DateFormat('MMM d, HH:mm');
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.tertiaryContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(children: [
        Icon(Icons.cloud_off_rounded,
            size: 16, color: Theme.of(context).colorScheme.onTertiaryContainer),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            'Offline — last updated ${fmt.format(lastUpdated.toLocal())}',
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: Theme.of(context).colorScheme.onTertiaryContainer,
                ),
          ),
        ),
      ]),
    );
  }
}

// ── Today's Wins Card ─────────────────────────────────────

class _TodayWinsCard extends StatelessWidget {
  final TodayWinsDto wins;
  const _TodayWinsCard({required this.wins});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final preview = wins.completions.take(5).toList();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Icon(Icons.emoji_events_rounded, color: cs.primary),
              const SizedBox(width: 8),
              Text("Today's Wins", style: tt.titleMedium),
            ]),
            const SizedBox(height: 16),
            Center(
              child: Text(
                '${wins.completedCountToday}',
                style: tt.displayMedium?.copyWith(
                  color: cs.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            Center(
              child: Text(
                wins.completedCountToday == 1
                    ? 'chore completed today'
                    : 'chores completed today',
                style: tt.bodyMedium?.copyWith(color: cs.onSurfaceVariant),
              ),
            ),
            if (preview.isNotEmpty) ...[
              const SizedBox(height: 16),
              const Divider(),
              ...preview.map((c) => _CompletionTile(completion: c)),
              if (wins.completions.length > 5)
                Center(
                  child: TextButton(
                    onPressed: null, // future: navigate to full list
                    child: Text('+${wins.completions.length - 5} more'),
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }
}

class _CompletionTile extends StatelessWidget {
  final TodayCompletionDto completion;
  const _CompletionTile({required this.completion});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final timeFmt = DateFormat('HH:mm');
    final time = timeFmt.format(completion.completedAtUtc.toLocal());

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(children: [
        Icon(Icons.check_circle_rounded, size: 18, color: cs.primary),
        const SizedBox(width: 8),
        Expanded(
          child: Text(completion.title ?? 'Untitled',
              style: Theme.of(context).textTheme.bodyMedium),
        ),
        Text(time,
            style: Theme.of(context)
                .textTheme
                .labelSmall
                ?.copyWith(color: cs.onSurfaceVariant)),
        if (completion.wasLate) ...[
          const SizedBox(width: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: cs.errorContainer,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text('late',
                style: Theme.of(context)
                    .textTheme
                    .labelSmall
                    ?.copyWith(color: cs.onErrorContainer)),
          ),
        ],
      ]),
    );
  }
}

// ── Week Summary Card ─────────────────────────────────────

class _WeekSummaryCard extends StatelessWidget {
  final AchievementSummaryDto summary;
  const _WeekSummaryCard({required this.summary});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final rate = summary.completionRate.clamp(0.0, 1.0);
    final ratePercent = (rate * 100).round();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Icon(Icons.bar_chart_rounded, color: cs.secondary),
              const SizedBox(width: 8),
              Text('This Week', style: tt.titleMedium),
            ]),
            const SizedBox(height: 16),
            Row(children: [
              _StatChip(
                  label: 'Done',
                  value: '${summary.totalCompleted}',
                  color: cs.primaryContainer),
              const SizedBox(width: 8),
              _StatChip(
                  label: 'Scheduled',
                  value: '${summary.totalScheduled}',
                  color: cs.surfaceContainerHighest),
            ]),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Completion rate', style: tt.bodySmall),
                Text('$ratePercent%',
                    style: tt.labelMedium?.copyWith(
                        color: cs.primary, fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 4),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: rate,
                minHeight: 8,
                backgroundColor: cs.surfaceContainerHighest,
                valueColor: AlwaysStoppedAnimation(cs.primary),
              ),
            ),
            const SizedBox(height: 12),
            Row(children: [
              _InlineTag(
                  icon: Icons.timer_rounded,
                  label: '${summary.onTimeCompleted} on time',
                  color: cs.tertiary),
              const SizedBox(width: 12),
              _InlineTag(
                  icon: Icons.schedule_rounded,
                  label: '${summary.lateCompleted} late',
                  color: cs.error),
            ]),
          ],
        ),
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  const _StatChip(
      {required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration:
          BoxDecoration(color: color, borderRadius: BorderRadius.circular(12)),
      child: Column(children: [
        Text(value,
            style: Theme.of(context)
                .textTheme
                .titleLarge
                ?.copyWith(fontWeight: FontWeight.bold)),
        Text(label, style: Theme.of(context).textTheme.labelSmall),
      ]),
    );
  }
}

class _InlineTag extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  const _InlineTag(
      {required this.icon, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Row(mainAxisSize: MainAxisSize.min, children: [
      Icon(icon, size: 14, color: color),
      const SizedBox(width: 4),
      Text(label,
          style:
              Theme.of(context).textTheme.labelSmall?.copyWith(color: color)),
    ]);
  }
}

// ── Streaks Card ───────────────────────────────────────────

class _StreaksCard extends StatelessWidget {
  final StreaksDto streaks;
  const _StreaksCard({required this.streaks});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Icon(Icons.local_fire_department_rounded, color: cs.error),
              const SizedBox(width: 8),
              Text('Streaks', style: tt.titleMedium),
            ]),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _StreakStat(
                  label: 'Current',
                  days: streaks.currentStreakDays,
                  icon: Icons.local_fire_department_rounded,
                  color: cs.error,
                ),
                Container(width: 1, height: 48, color: cs.outlineVariant),
                _StreakStat(
                  label: 'Best',
                  days: streaks.longestStreakDays,
                  icon: Icons.emoji_events_rounded,
                  color: cs.primary,
                ),
                if (streaks.currentOnTimeStreakDays > 0) ...[
                  Container(width: 1, height: 48, color: cs.outlineVariant),
                  _StreakStat(
                    label: 'On-time',
                    days: streaks.currentOnTimeStreakDays,
                    icon: Icons.timer_rounded,
                    color: cs.tertiary,
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _StreakStat extends StatelessWidget {
  final String label;
  final int days;
  final IconData icon;
  final Color color;
  const _StreakStat(
      {required this.label,
      required this.days,
      required this.icon,
      required this.color});

  @override
  Widget build(BuildContext context) {
    return Column(mainAxisSize: MainAxisSize.min, children: [
      Icon(icon, color: color, size: 28),
      const SizedBox(height: 4),
      Text('$days',
          style: Theme.of(context)
              .textTheme
              .headlineMedium
              ?.copyWith(color: color, fontWeight: FontWeight.bold)),
      Text(days == 1 ? 'day' : 'days',
          style: Theme.of(context).textTheme.labelSmall),
      Text(label,
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant)),
    ]);
  }
}

// ── Badges Section ────────────────────────────────────────

class _BadgesSection extends StatelessWidget {
  final BadgesResponseDto badges;
  const _BadgesSection({required this.badges});

  static const _badgeIcons = <String, IconData>{
    'completions_10': Icons.looks_one_rounded,
    'completions_25': Icons.looks_two_rounded,
    'completions_50': Icons.filter_5_rounded,
    'completions_100': Icons.filter_none_rounded,
    'streak_3': Icons.local_fire_department_rounded,
    'streak_7': Icons.whatshot_rounded,
    'streak_14': Icons.bolt_rounded,
    'streak_30': Icons.star_rounded,
    'perfect_week': Icons.workspace_premium_rounded,
  };

  IconData _iconFor(String? key) =>
      _badgeIcons[key] ?? Icons.military_tech_rounded;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Earned badges ─────────────────────────────
        if (badges.earnedBadges.isNotEmpty) ...[
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(children: [
              Icon(Icons.military_tech_rounded, color: cs.primary),
              const SizedBox(width: 8),
              Text('Badges Earned', style: tt.titleMedium),
            ]),
          ),
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 3,
            mainAxisSpacing: 8,
            crossAxisSpacing: 8,
            childAspectRatio: 0.8,
            children: badges.earnedBadges
                .map((b) => _EarnedBadgeTile(
                      badge: b,
                      icon: _iconFor(b.key),
                    ))
                .toList(),
          ),
          const SizedBox(height: 12),
        ],

        // ── Progress badges ───────────────────────────
        if (badges.progressBadges.isNotEmpty) ...[
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(children: [
              Icon(Icons.trending_up_rounded, color: cs.secondary),
              const SizedBox(width: 8),
              Text('In Progress', style: tt.titleMedium),
            ]),
          ),
          ...badges.progressBadges.map((p) => _ProgressBadgeTile(
                progress: p,
                icon: _iconFor(p.key),
              )),
        ],
      ],
    );
  }
}

class _EarnedBadgeTile extends StatelessWidget {
  final BadgeDto badge;
  final IconData icon;
  const _EarnedBadgeTile({required this.badge, required this.icon});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Card(
      color: cs.primaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 36, color: cs.onPrimaryContainer),
            const SizedBox(height: 6),
            Text(
              badge.title ?? '',
              style: Theme.of(context)
                  .textTheme
                  .labelSmall
                  ?.copyWith(color: cs.onPrimaryContainer),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

class _ProgressBadgeTile extends StatelessWidget {
  final BadgeProgressDto progress;
  final IconData icon;
  const _ProgressBadgeTile({required this.progress, required this.icon});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(children: [
          Icon(icon, size: 32, color: cs.onSurfaceVariant),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(progress.title ?? '', style: tt.labelLarge),
                if (progress.description != null)
                  Text(progress.description!,
                      style:
                          tt.bodySmall?.copyWith(color: cs.onSurfaceVariant)),
                const SizedBox(height: 6),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(6),
                        child: LinearProgressIndicator(
                          value: progress.progress,
                          minHeight: 6,
                          backgroundColor: cs.surfaceContainerHighest,
                          valueColor: AlwaysStoppedAnimation(cs.secondary),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text('${progress.current}/${progress.target}',
                        style: tt.labelSmall
                            ?.copyWith(color: cs.onSurfaceVariant)),
                  ],
                ),
              ],
            ),
          ),
        ]),
      ),
    );
  }
}

// ── Share Button ──────────────────────────────────────────

class _ShareButton extends StatelessWidget {
  final AchievementsData data;
  final AchievementScope scope;
  const _ShareButton({required this.data, required this.scope});

  String _buildSummary() {
    final sb = StringBuffer();
    sb.writeln('🏆 DoTogether Achievements — ${scope.label}');
    sb.writeln();
    sb.writeln(
        "Today's wins: ${data.todayWins.completedCountToday} chore(s) completed");
    sb.writeln(
        'This week: ${data.summary.totalCompleted}/${data.summary.totalScheduled} scheduled (${(data.summary.completionRate * 100).round()}%)');
    sb.writeln(
        '  ✅ On-time: ${data.summary.onTimeCompleted}  ⏱ Late: ${data.summary.lateCompleted}');
    sb.writeln();
    sb.writeln(
        '🔥 Current streak: ${data.streaks.currentStreakDays} day(s)  |  Best: ${data.streaks.longestStreakDays} day(s)');
    if (data.badges.earnedBadges.isNotEmpty) {
      sb.writeln();
      sb.writeln(
          '🥇 Badges: ${data.badges.earnedBadges.map((b) => b.title ?? b.key ?? '').join(', ')}');
    }
    return sb.toString();
  }

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: () => Share.share(_buildSummary()),
      icon: const Icon(Icons.share_rounded),
      label: const Text('Share Summary'),
    );
  }
}

// ── Empty State ───────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.emoji_events_outlined, size: 80, color: cs.outlineVariant),
          const SizedBox(height: 16),
          Text('No achievements yet',
              style: tt.titleLarge, textAlign: TextAlign.center),
          const SizedBox(height: 8),
          Text(
            'Complete your first chore to start earning achievements and streaks!',
            style: tt.bodyMedium?.copyWith(color: cs.onSurfaceVariant),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

// ── Error State ───────────────────────────────────────────

class _ErrorState extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _ErrorState({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.cloud_off_rounded, size: 64, color: cs.error),
          const SizedBox(height: 16),
          Text('Could not load achievements',
              style: tt.titleMedium, textAlign: TextAlign.center),
          const SizedBox(height: 8),
          Text(message,
              style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
              textAlign: TextAlign.center),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('Try Again'),
          ),
        ],
      ),
    );
  }
}
