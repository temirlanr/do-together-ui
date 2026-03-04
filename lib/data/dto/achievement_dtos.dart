// Achievement-related DTOs matching the backend swagger schema.

// ── Scope ────────────────────────────────────────────────

/// 0 = Me, 1 = Partner, 2 = Household
enum AchievementScope {
  me(0, 'Me'),
  partner(1, 'Partner'),
  household(2, 'Household');

  const AchievementScope(this.value, this.label);
  final int value;
  final String label;

  static AchievementScope fromValue(int v) => AchievementScope.values
      .firstWhere((e) => e.value == v, orElse: () => AchievementScope.me);
}

// ── Today's Wins ─────────────────────────────────────────

class TodayCompletionDto {
  final String occurrenceId;
  final String? title;
  final DateTime completedAtUtc;
  final String scheduledDate; // "yyyy-MM-dd"
  final bool wasLate;

  const TodayCompletionDto({
    required this.occurrenceId,
    this.title,
    required this.completedAtUtc,
    required this.scheduledDate,
    required this.wasLate,
  });

  factory TodayCompletionDto.fromJson(Map<String, dynamic> json) {
    return TodayCompletionDto(
      occurrenceId: json['occurrenceId'] as String,
      title: json['title'] as String?,
      completedAtUtc: DateTime.parse(json['completedAtUtc'] as String),
      scheduledDate: json['scheduledDate'] as String,
      wasLate: json['wasLate'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() => {
        'occurrenceId': occurrenceId,
        'title': title,
        'completedAtUtc': completedAtUtc.toIso8601String(),
        'scheduledDate': scheduledDate,
        'wasLate': wasLate,
      };
}

class TodayWinsDto {
  final int completedCountToday;
  final List<TodayCompletionDto> completions;

  const TodayWinsDto({
    required this.completedCountToday,
    required this.completions,
  });

  factory TodayWinsDto.fromJson(Map<String, dynamic> json) {
    final list = json['completions'] as List<dynamic>?;
    return TodayWinsDto(
      completedCountToday: json['completedCountToday'] as int? ?? 0,
      completions: list
              ?.map(
                  (e) => TodayCompletionDto.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() => {
        'completedCountToday': completedCountToday,
        'completions': completions.map((e) => e.toJson()).toList(),
      };
}

// ── Summary ───────────────────────────────────────────────

class CompletedByDayDto {
  final String date; // "yyyy-MM-dd"
  final int count;

  const CompletedByDayDto({required this.date, required this.count});

  factory CompletedByDayDto.fromJson(Map<String, dynamic> json) =>
      CompletedByDayDto(
        date: json['date'] as String,
        count: json['count'] as int? ?? 0,
      );

  Map<String, dynamic> toJson() => {'date': date, 'count': count};
}

class TopTemplateDto {
  final String templateId;
  final String? title;
  final int completedCount;

  const TopTemplateDto({
    required this.templateId,
    this.title,
    required this.completedCount,
  });

  factory TopTemplateDto.fromJson(Map<String, dynamic> json) => TopTemplateDto(
        templateId: json['templateId'] as String,
        title: json['title'] as String?,
        completedCount: json['completedCount'] as int? ?? 0,
      );

  Map<String, dynamic> toJson() => {
        'templateId': templateId,
        'title': title,
        'completedCount': completedCount,
      };
}

class AchievementSummaryDto {
  final int totalCompleted;
  final int totalScheduled;
  final double completionRate;
  final List<CompletedByDayDto> completedByDay;
  final List<TopTemplateDto> topTemplates;
  final int onTimeCompleted;
  final int lateCompleted;

  const AchievementSummaryDto({
    required this.totalCompleted,
    required this.totalScheduled,
    required this.completionRate,
    required this.completedByDay,
    required this.topTemplates,
    required this.onTimeCompleted,
    required this.lateCompleted,
  });

  factory AchievementSummaryDto.fromJson(Map<String, dynamic> json) {
    final byDay = json['completedByDay'] as List<dynamic>?;
    final templates = json['topTemplates'] as List<dynamic>?;
    return AchievementSummaryDto(
      totalCompleted: json['totalCompleted'] as int? ?? 0,
      totalScheduled: json['totalScheduled'] as int? ?? 0,
      completionRate: (json['completionRate'] as num?)?.toDouble() ?? 0.0,
      completedByDay: byDay
              ?.map(
                  (e) => CompletedByDayDto.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      topTemplates: templates
              ?.map((e) => TopTemplateDto.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      onTimeCompleted: json['onTimeCompleted'] as int? ?? 0,
      lateCompleted: json['lateCompleted'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
        'totalCompleted': totalCompleted,
        'totalScheduled': totalScheduled,
        'completionRate': completionRate,
        'completedByDay': completedByDay.map((e) => e.toJson()).toList(),
        'topTemplates': topTemplates.map((e) => e.toJson()).toList(),
        'onTimeCompleted': onTimeCompleted,
        'lateCompleted': lateCompleted,
      };
}

// ── Streaks ───────────────────────────────────────────────

class StreaksDto {
  final int currentStreakDays;
  final int longestStreakDays;
  final int currentOnTimeStreakDays;

  const StreaksDto({
    required this.currentStreakDays,
    required this.longestStreakDays,
    required this.currentOnTimeStreakDays,
  });

  factory StreaksDto.fromJson(Map<String, dynamic> json) => StreaksDto(
        currentStreakDays: json['currentStreakDays'] as int? ?? 0,
        longestStreakDays: json['longestStreakDays'] as int? ?? 0,
        currentOnTimeStreakDays: json['currentOnTimeStreakDays'] as int? ?? 0,
      );

  Map<String, dynamic> toJson() => {
        'currentStreakDays': currentStreakDays,
        'longestStreakDays': longestStreakDays,
        'currentOnTimeStreakDays': currentOnTimeStreakDays,
      };
}

// ── Badges ────────────────────────────────────────────────

class BadgeDto {
  final String? key;
  final String? title;
  final String? description;

  const BadgeDto({this.key, this.title, this.description});

  factory BadgeDto.fromJson(Map<String, dynamic> json) => BadgeDto(
        key: json['key'] as String?,
        title: json['title'] as String?,
        description: json['description'] as String?,
      );

  Map<String, dynamic> toJson() =>
      {'key': key, 'title': title, 'description': description};
}

class BadgeProgressDto {
  final String? key;
  final String? title;
  final String? description;
  final int current;
  final int target;

  const BadgeProgressDto({
    this.key,
    this.title,
    this.description,
    required this.current,
    required this.target,
  });

  double get progress => target > 0 ? (current / target).clamp(0.0, 1.0) : 0;

  factory BadgeProgressDto.fromJson(Map<String, dynamic> json) =>
      BadgeProgressDto(
        key: json['key'] as String?,
        title: json['title'] as String?,
        description: json['description'] as String?,
        current: json['current'] as int? ?? 0,
        target: json['target'] as int? ?? 1,
      );

  Map<String, dynamic> toJson() => {
        'key': key,
        'title': title,
        'description': description,
        'current': current,
        'target': target,
      };
}

class BadgesResponseDto {
  final List<BadgeDto> earnedBadges;
  final List<BadgeProgressDto> progressBadges;

  const BadgesResponseDto({
    required this.earnedBadges,
    required this.progressBadges,
  });

  factory BadgesResponseDto.fromJson(Map<String, dynamic> json) {
    final earned = json['earnedBadges'] as List<dynamic>?;
    final progress = json['progressBadges'] as List<dynamic>?;
    return BadgesResponseDto(
      earnedBadges: earned
              ?.map((e) => BadgeDto.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      progressBadges: progress
              ?.map((e) => BadgeProgressDto.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() => {
        'earnedBadges': earnedBadges.map((e) => e.toJson()).toList(),
        'progressBadges': progressBadges.map((e) => e.toJson()).toList(),
      };
}
