/// Maps to backend OccurrenceStatus enum.
/// 0=Pending, 1=Completed, 2=Skipped, 3=Missed
enum OccurrenceStatus {
  pending(0),
  completed(1),
  skipped(2),
  missed(3);

  const OccurrenceStatus(this.value);
  final int value;

  static OccurrenceStatus fromValue(int v) => OccurrenceStatus.values
      .firstWhere((e) => e.value == v, orElse: () => OccurrenceStatus.pending);
}

/// Maps to backend RecurrenceType enum.
/// 0=Once, 1=Daily, 2=Weekly, 3=Monthly
enum RecurrenceType {
  once(0),
  daily(1),
  weekly(2),
  monthly(3);

  const RecurrenceType(this.value);
  final int value;

  static RecurrenceType fromValue(int v) => RecurrenceType.values
      .firstWhere((e) => e.value == v, orElse: () => RecurrenceType.once);

  String get label {
    switch (this) {
      case RecurrenceType.once:
        return 'Once';
      case RecurrenceType.daily:
        return 'Daily';
      case RecurrenceType.weekly:
        return 'Weekly';
      case RecurrenceType.monthly:
        return 'Monthly';
    }
  }
}

/// Maps to backend ChoreEventType enum.
enum ChoreEventType {
  created(0),
  completed(1),
  undone(2),
  skipped(3),
  reassigned(4),
  edited(5),
  missed(6);

  const ChoreEventType(this.value);
  final int value;

  static ChoreEventType fromValue(int v) => ChoreEventType.values
      .firstWhere((e) => e.value == v, orElse: () => ChoreEventType.created);
}

/// Maps to backend MemberRole enum.
/// 0=Admin, 1=Member
enum MemberRole {
  admin(0),
  member(1);

  const MemberRole(this.value);
  final int value;

  static MemberRole fromValue(int v) =>
      MemberRole.values.firstWhere((e) => e.value == v,
          orElse: () => MemberRole.member); // default to member if unknown
}

/// Maps to backend PushPlatform enum.
/// 0=Fcm, 1=Apns
enum PushPlatform {
  fcm(0),
  apns(1);

  const PushPlatform(this.value);
  final int value;
}
