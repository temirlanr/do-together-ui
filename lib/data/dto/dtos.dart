import 'enums.dart';

// ─── Auth DTOs ───────────────────────────────────────────────

class LoginDto {
  final String email;
  final String password;
  const LoginDto({required this.email, required this.password});

  Map<String, dynamic> toJson() => {'email': email, 'password': password};
}

class RegisterDto {
  final String email;
  final String displayName;
  final String password;
  const RegisterDto({
    required this.email,
    required this.displayName,
    required this.password,
  });

  Map<String, dynamic> toJson() => {
        'email': email,
        'displayName': displayName,
        'password': password,
      };
}

class RefreshRequestDto {
  final String refreshToken;
  const RefreshRequestDto({required this.refreshToken});

  Map<String, dynamic> toJson() => {'refreshToken': refreshToken};
}

class AuthResponseDto {
  final String? accessToken;
  final String? refreshToken;
  final DateTime expiresAtUtc;
  final UserDto user;

  const AuthResponseDto({
    this.accessToken,
    this.refreshToken,
    required this.expiresAtUtc,
    required this.user,
  });

  factory AuthResponseDto.fromJson(Map<String, dynamic> json) {
    return AuthResponseDto(
      accessToken: json['accessToken'] as String?,
      refreshToken: json['refreshToken'] as String?,
      expiresAtUtc: DateTime.parse(json['expiresAtUtc'] as String),
      user: UserDto.fromJson(json['user'] as Map<String, dynamic>),
    );
  }
}

class UserDto {
  final String id;
  final String? email;
  final String? displayName;

  const UserDto({required this.id, this.email, this.displayName});

  factory UserDto.fromJson(Map<String, dynamic> json) {
    return UserDto(
      id: json['id'] as String,
      email: json['email'] as String?,
      displayName: json['displayName'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'email': email,
        'displayName': displayName,
      };
}

// ─── Household DTOs ──────────────────────────────────────────

class CreateHouseholdDto {
  final String name;
  final String timeZoneId;

  const CreateHouseholdDto({required this.name, required this.timeZoneId});

  Map<String, dynamic> toJson() => {'name': name, 'timeZoneId': timeZoneId};
}

class HouseholdDto {
  final String id;
  final String? name;
  final String? timeZoneId;
  final List<HouseholdMemberDto>? members;

  const HouseholdDto({
    required this.id,
    this.name,
    this.timeZoneId,
    this.members,
  });

  factory HouseholdDto.fromJson(Map<String, dynamic> json) {
    return HouseholdDto(
      id: json['id'] as String,
      name: json['name'] as String?,
      timeZoneId: json['timeZoneId'] as String?,
      members: (json['members'] as List<dynamic>?)
          ?.map((e) => HouseholdMemberDto.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}

class HouseholdMemberDto {
  final String userId;
  final String? displayName;
  final String? email;
  final MemberRole role;
  final DateTime joinedAtUtc;

  const HouseholdMemberDto({
    required this.userId,
    this.displayName,
    this.email,
    required this.role,
    required this.joinedAtUtc,
  });

  factory HouseholdMemberDto.fromJson(Map<String, dynamic> json) {
    return HouseholdMemberDto(
      userId: json['userId'] as String,
      displayName: json['displayName'] as String?,
      email: json['email'] as String?,
      role: MemberRole.fromValue(json['role'] as int),
      joinedAtUtc: DateTime.parse(json['joinedAtUtc'] as String),
    );
  }
}

class InviteMemberDto {
  final String email;
  const InviteMemberDto({required this.email});
  Map<String, dynamic> toJson() => {'email': email};
}

class InviteResponseDto {
  final String inviteId;
  final String? token;
  final DateTime expiresAtUtc;

  const InviteResponseDto({
    required this.inviteId,
    this.token,
    required this.expiresAtUtc,
  });

  factory InviteResponseDto.fromJson(Map<String, dynamic> json) {
    return InviteResponseDto(
      inviteId: json['inviteId'] as String,
      token: json['token'] as String?,
      expiresAtUtc: DateTime.parse(json['expiresAtUtc'] as String),
    );
  }
}

class JoinHouseholdDto {
  final String inviteToken;
  const JoinHouseholdDto({required this.inviteToken});
  Map<String, dynamic> toJson() => {'inviteToken': inviteToken};
}

// ─── Chore DTOs ──────────────────────────────────────────────

class RecurrenceRuleDto {
  final RecurrenceType type;
  final int interval;
  final List<int>? daysOfWeek;
  final int? dayOfMonth;

  const RecurrenceRuleDto({
    required this.type,
    required this.interval,
    this.daysOfWeek,
    this.dayOfMonth,
  });

  factory RecurrenceRuleDto.fromJson(Map<String, dynamic> json) {
    return RecurrenceRuleDto(
      type: RecurrenceType.fromValue(json['type'] as int),
      interval: json['interval'] as int,
      daysOfWeek:
          (json['daysOfWeek'] as List<dynamic>?)?.map((e) => e as int).toList(),
      dayOfMonth: json['dayOfMonth'] as int?,
    );
  }

  Map<String, dynamic> toJson() => {
        'type': type.value,
        'interval': interval,
        if (daysOfWeek != null) 'daysOfWeek': daysOfWeek,
        if (dayOfMonth != null) 'dayOfMonth': dayOfMonth,
      };

  String get displayText {
    switch (type) {
      case RecurrenceType.daily:
        return interval == 1 ? 'Every day' : 'Every $interval days';
      case RecurrenceType.weekly:
        if (daysOfWeek != null && daysOfWeek!.isNotEmpty) {
          const dayNames = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
          final days = daysOfWeek!.map((d) => dayNames[d % 7]).join(', ');
          return interval == 1
              ? 'Weekly on $days'
              : 'Every $interval weeks on $days';
        }
        return interval == 1 ? 'Weekly' : 'Every $interval weeks';
      case RecurrenceType.once:
        return 'Once';
      case RecurrenceType.monthly:
        if (dayOfMonth != null) {
          return interval == 1
              ? 'Monthly on day $dayOfMonth'
              : 'Every $interval months on day $dayOfMonth';
        }
        return interval == 1 ? 'Monthly' : 'Every $interval months';
    }
  }
}

class CreateChoreTemplateDto {
  final String title;
  final String? description;
  final RecurrenceRuleDto recurrenceRule;
  final String? assigneeId;
  final String startDate; // yyyy-MM-dd
  final String? endDate;

  const CreateChoreTemplateDto({
    required this.title,
    this.description,
    required this.recurrenceRule,
    this.assigneeId,
    required this.startDate,
    this.endDate,
  });

  Map<String, dynamic> toJson() => {
        'title': title,
        if (description != null) 'description': description,
        'recurrenceRule': recurrenceRule.toJson(),
        if (assigneeId != null) 'assigneeId': assigneeId,
        'startDate': startDate,
        if (endDate != null) 'endDate': endDate,
      };
}

class UpdateChoreTemplateDto {
  final String? title;
  final String? description;
  final RecurrenceRuleDto? recurrenceRule;
  final String? assigneeId;
  final String? endDate;
  final bool? isActive;

  const UpdateChoreTemplateDto({
    this.title,
    this.description,
    this.recurrenceRule,
    this.assigneeId,
    this.endDate,
    this.isActive,
  });

  Map<String, dynamic> toJson() => {
        if (title != null) 'title': title,
        if (description != null) 'description': description,
        if (recurrenceRule != null) 'recurrenceRule': recurrenceRule!.toJson(),
        if (assigneeId != null) 'assigneeId': assigneeId,
        if (endDate != null) 'endDate': endDate,
        if (isActive != null) 'isActive': isActive,
      };
}

class ChoreTemplateDto {
  final String id;
  final String? title;
  final String? description;
  final RecurrenceRuleDto? recurrenceRule;
  final String? assigneeId;
  final String? assigneeName;
  final String startDate;
  final String? endDate;
  final bool isActive;
  final DateTime createdAtUtc;

  const ChoreTemplateDto({
    required this.id,
    this.title,
    this.description,
    this.recurrenceRule,
    this.assigneeId,
    this.assigneeName,
    required this.startDate,
    this.endDate,
    required this.isActive,
    required this.createdAtUtc,
  });

  factory ChoreTemplateDto.fromJson(Map<String, dynamic> json) {
    return ChoreTemplateDto(
      id: json['id'] as String,
      title: json['title'] as String?,
      description: json['description'] as String?,
      recurrenceRule: json['recurrenceRule'] != null
          ? RecurrenceRuleDto.fromJson(
              json['recurrenceRule'] as Map<String, dynamic>)
          : null,
      assigneeId: json['assigneeId'] as String?,
      assigneeName: json['assigneeName'] as String?,
      startDate: json['startDate'] as String,
      endDate: json['endDate'] as String?,
      isActive: json['isActive'] as bool,
      createdAtUtc: DateTime.parse(json['createdAtUtc'] as String),
    );
  }
}

class ChoreOccurrenceDto {
  final String id;
  final String choreTemplateId;
  final String? choreTitle;
  final String? assigneeId;
  final String? assigneeName;
  final String dueDate; // yyyy-MM-dd
  final OccurrenceStatus status;
  final int version;
  final List<ChoreEventDto>? events;

  const ChoreOccurrenceDto({
    required this.id,
    required this.choreTemplateId,
    this.choreTitle,
    this.assigneeId,
    this.assigneeName,
    required this.dueDate,
    required this.status,
    required this.version,
    this.events,
  });

  factory ChoreOccurrenceDto.fromJson(Map<String, dynamic> json) {
    return ChoreOccurrenceDto(
      id: json['id'] as String,
      choreTemplateId: json['choreTemplateId'] as String,
      choreTitle: json['choreTitle'] as String?,
      assigneeId: json['assigneeId'] as String?,
      assigneeName: json['assigneeName'] as String?,
      dueDate: json['dueDate'] as String,
      status: OccurrenceStatus.fromValue(json['status'] as int),
      version: json['version'] as int,
      events: (json['events'] as List<dynamic>?)
          ?.map((e) => ChoreEventDto.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'choreTemplateId': choreTemplateId,
        'choreTitle': choreTitle,
        'assigneeId': assigneeId,
        'assigneeName': assigneeName,
        'dueDate': dueDate,
        'status': status.value,
        'version': version,
      };
}

class ChoreEventDto {
  final String id;
  final ChoreEventType eventType;
  final String performedByUserId;
  final String? performedByName;
  final DateTime occurredAtUtc;
  final String clientOperationId;
  final String? metadata;

  const ChoreEventDto({
    required this.id,
    required this.eventType,
    required this.performedByUserId,
    this.performedByName,
    required this.occurredAtUtc,
    required this.clientOperationId,
    this.metadata,
  });

  factory ChoreEventDto.fromJson(Map<String, dynamic> json) {
    return ChoreEventDto(
      id: json['id'] as String,
      eventType: ChoreEventType.fromValue(json['eventType'] as int),
      performedByUserId: json['performedByUserId'] as String,
      performedByName: json['performedByName'] as String?,
      occurredAtUtc: DateTime.parse(json['occurredAtUtc'] as String),
      clientOperationId: json['clientOperationId'] as String,
      metadata: json['metadata'] as String?,
    );
  }
}

// ─── Calendar DTOs ───────────────────────────────────────────

class DayAggregateDto {
  final String date; // yyyy-MM-dd
  final int due;
  final int done;
  final int missed;
  final int skipped;

  const DayAggregateDto({
    required this.date,
    required this.due,
    required this.done,
    required this.missed,
    required this.skipped,
  });

  factory DayAggregateDto.fromJson(Map<String, dynamic> json) {
    return DayAggregateDto(
      date: json['date'] as String,
      due: json['due'] as int,
      done: json['done'] as int,
      missed: json['missed'] as int,
      skipped: json['skipped'] as int,
    );
  }

  int get total => due + done + missed + skipped;
}

// ─── Device DTOs ─────────────────────────────────────────────

class RegisterDeviceDto {
  final PushPlatform platform;
  final String token;

  const RegisterDeviceDto({required this.platform, required this.token});

  Map<String, dynamic> toJson() => {
        'platform': platform.value,
        'token': token,
      };
}

// ─── Mutation DTOs ───────────────────────────────────────────

class MutationRequestDto {
  final String clientOperationId;
  const MutationRequestDto({required this.clientOperationId});
  Map<String, dynamic> toJson() => {'clientOperationId': clientOperationId};
}

class ReassignRequestDto {
  final String clientOperationId;
  final String newAssigneeId;

  const ReassignRequestDto({
    required this.clientOperationId,
    required this.newAssigneeId,
  });

  Map<String, dynamic> toJson() => {
        'clientOperationId': clientOperationId,
        'newAssigneeId': newAssigneeId,
      };
}
