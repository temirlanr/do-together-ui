import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../core/network/api_exceptions.dart';
import '../core/sync/sync_manager.dart';
import '../data/api/calendar_api.dart';
import '../data/api/chore_api.dart';
import '../data/dto/dtos.dart';
import '../data/dto/enums.dart';
import 'core_providers.dart';
import 'household_provider.dart';

// ── Occurrence state ──────────────────────────────────────

class OccurrenceListState {
  final bool isLoading;
  final List<ChoreOccurrenceDto> occurrences;
  final String? error;

  const OccurrenceListState({
    this.isLoading = false,
    this.occurrences = const [],
    this.error,
  });

  OccurrenceListState copyWith({
    bool? isLoading,
    List<ChoreOccurrenceDto>? occurrences,
    String? error,
  }) {
    return OccurrenceListState(
      isLoading: isLoading ?? this.isLoading,
      occurrences: occurrences ?? this.occurrences,
      error: error,
    );
  }
}

class TodayOccurrencesNotifier extends StateNotifier<OccurrenceListState> {
  final CalendarApi _calendarApi;
  final SyncManager _syncManager;
  final String? _householdId;
  bool _isFetching = false;

  TodayOccurrencesNotifier(
      this._calendarApi, this._syncManager, this._householdId)
      : super(const OccurrenceListState());

  final _dateFmt = DateFormat('yyyy-MM-dd');

  Future<void> load() async {
    if (_householdId == null || _isFetching) return;
    _isFetching = true;
    state = state.copyWith(isLoading: true, error: null);

    final today = _dateFmt.format(DateTime.now());
    // Also include overdue: from 30 days ago
    final overdueFrom =
        _dateFmt.format(DateTime.now().subtract(const Duration(days: 30)));

    try {
      final occurrences = await _calendarApi.getOccurrences(
        householdId: _householdId!,
        from: overdueFrom,
        to: today,
      );

      final relevant = occurrences
          .where((o) =>
              o.dueDate == today ||
              (o.status == OccurrenceStatus.pending &&
                  o.dueDate.compareTo(today) < 0))
          .toList();

      state = state.copyWith(isLoading: false, occurrences: relevant);
    } on ApiException catch (e) {
      state = state.copyWith(isLoading: false, error: e.message);
    } finally {
      _isFetching = false;
    }
  }

  /// Complete an occurrence.
  Future<void> complete(String occurrenceId) async {
    if (_householdId == null) return;
    _updateLocalStatus(occurrenceId, OccurrenceStatus.completed);
    try {
      await _syncManager.enqueueComplete(_householdId!, occurrenceId);
    } catch (_) {
      _updateLocalStatus(occurrenceId, OccurrenceStatus.pending);
    }
  }

  /// Undo a completion.
  Future<void> undo(String occurrenceId) async {
    if (_householdId == null) return;
    _updateLocalStatus(occurrenceId, OccurrenceStatus.pending);
    try {
      await _syncManager.enqueueUndo(_householdId!, occurrenceId);
    } catch (_) {
      _updateLocalStatus(occurrenceId, OccurrenceStatus.completed);
    }
  }

  /// Skip an occurrence.
  Future<void> skip(String occurrenceId) async {
    if (_householdId == null) return;
    _updateLocalStatus(occurrenceId, OccurrenceStatus.skipped);
    try {
      await _syncManager.enqueueSkip(_householdId!, occurrenceId);
    } catch (_) {
      _updateLocalStatus(occurrenceId, OccurrenceStatus.pending);
    }
  }

  /// Reassign to a different household member.
  Future<void> reassign(String occurrenceId, String newAssigneeId) async {
    if (_householdId == null) return;
    try {
      await _syncManager.enqueueReassign(
          _householdId!, occurrenceId, newAssigneeId);
      // Reload to get updated data
      await load();
    } catch (_) {
      // Reload to restore correct state
      await load();
    }
  }

  void _updateLocalStatus(String occurrenceId, OccurrenceStatus newStatus) {
    state = state.copyWith(
      occurrences: state.occurrences.map((o) {
        if (o.id == occurrenceId) {
          return ChoreOccurrenceDto(
            id: o.id,
            choreTemplateId: o.choreTemplateId,
            choreTitle: o.choreTitle,
            assigneeId: o.assigneeId,
            assigneeName: o.assigneeName,
            dueDate: o.dueDate,
            status: newStatus,
            version: o.version,
            events: o.events,
          );
        }
        return o;
      }).toList(),
    );
  }
}

final todayOccurrencesProvider =
    StateNotifierProvider<TodayOccurrencesNotifier, OccurrenceListState>((ref) {
  return TodayOccurrencesNotifier(
    ref.watch(calendarApiProvider),
    ref.watch(syncManagerProvider),
    ref.watch(currentHouseholdIdProvider),
  );
});

// ── Upcoming occurrences ──────────────────────────────────

class UpcomingOccurrencesNotifier extends StateNotifier<OccurrenceListState> {
  final CalendarApi _calendarApi;
  final String? _householdId;
  bool _isFetching = false;

  UpcomingOccurrencesNotifier(this._calendarApi, this._householdId)
      : super(const OccurrenceListState());

  final _dateFmt = DateFormat('yyyy-MM-dd');

  Future<void> load({int days = 14}) async {
    if (_householdId == null || _isFetching) return;
    _isFetching = true;
    state = state.copyWith(isLoading: true, error: null);

    final tomorrow = DateTime.now().add(const Duration(days: 1));
    final from = _dateFmt.format(tomorrow);
    final to = _dateFmt.format(DateTime.now().add(Duration(days: days)));

    try {
      final occurrences = await _calendarApi.getOccurrences(
        householdId: _householdId!,
        from: from,
        to: to,
      );
      state = state.copyWith(isLoading: false, occurrences: occurrences);
    } on ApiException catch (e) {
      state = state.copyWith(isLoading: false, error: e.message);
    } finally {
      _isFetching = false;
    }
  }
}

final upcomingOccurrencesProvider =
    StateNotifierProvider<UpcomingOccurrencesNotifier, OccurrenceListState>(
        (ref) {
  return UpcomingOccurrencesNotifier(
    ref.watch(calendarApiProvider),
    ref.watch(currentHouseholdIdProvider),
  );
});

// ── Templates ─────────────────────────────────────────────

class TemplateListState {
  final bool isLoading;
  final List<ChoreTemplateDto> templates;
  final String? error;

  const TemplateListState({
    this.isLoading = false,
    this.templates = const [],
    this.error,
  });

  TemplateListState copyWith({
    bool? isLoading,
    List<ChoreTemplateDto>? templates,
    String? error,
  }) {
    return TemplateListState(
      isLoading: isLoading ?? this.isLoading,
      templates: templates ?? this.templates,
      error: error,
    );
  }
}

class TemplateNotifier extends StateNotifier<TemplateListState> {
  final ChoreApi _api;
  final String? _householdId;
  bool _isFetching = false;

  TemplateNotifier(this._api, this._householdId)
      : super(const TemplateListState());

  Future<void> load() async {
    if (_householdId == null || _isFetching) return;
    _isFetching = true;
    state = state.copyWith(isLoading: true, error: null);

    try {
      final templates = await _api.getTemplates(_householdId!);
      state = state.copyWith(isLoading: false, templates: templates);
    } on ApiException catch (e) {
      state = state.copyWith(isLoading: false, error: e.message);
    } finally {
      _isFetching = false;
    }
  }

  Future<bool> create(CreateChoreTemplateDto dto) async {
    if (_householdId == null) return false;
    state = state.copyWith(isLoading: true, error: null);
    try {
      await _api.createTemplate(_householdId!, dto);
      // Also trigger generation of occurrences
      await _api.generateOccurrences(_householdId!);
      await load();
      return true;
    } on ApiException catch (e) {
      state = state.copyWith(isLoading: false, error: e.message);
      return false;
    }
  }

  Future<bool> update(String templateId, UpdateChoreTemplateDto dto) async {
    if (_householdId == null) return false;
    state = state.copyWith(isLoading: true, error: null);
    try {
      await _api.updateTemplate(_householdId!, templateId, dto);
      await _api.generateOccurrences(_householdId!);
      await load();
      return true;
    } on ApiException catch (e) {
      state = state.copyWith(isLoading: false, error: e.message);
      return false;
    }
  }

  Future<bool> deleteTemplate(String templateId) async {
    if (_householdId == null) return false;
    state = state.copyWith(isLoading: true, error: null);
    try {
      await _api.deleteTemplate(_householdId!, templateId);
      await load();
      return true;
    } on ApiException catch (e) {
      state = state.copyWith(isLoading: false, error: e.message);
      return false;
    }
  }
}

final templateProvider =
    StateNotifierProvider<TemplateNotifier, TemplateListState>((ref) {
  return TemplateNotifier(
    ref.watch(choreApiProvider),
    ref.watch(currentHouseholdIdProvider),
  );
});
