import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../core/network/api_exceptions.dart';
import '../data/api/calendar_api.dart';
import '../data/dto/dtos.dart';
import 'core_providers.dart';
import 'household_provider.dart';

class CalendarState {
  final bool isLoading;
  final Map<String, DayAggregateDto> aggregates; // date -> aggregate
  final List<ChoreOccurrenceDto> selectedDayOccurrences;
  final DateTime selectedDate;
  final DateTime focusedMonth;
  final String? error;

  CalendarState({
    this.isLoading = false,
    this.aggregates = const {},
    this.selectedDayOccurrences = const [],
    DateTime? selectedDate,
    DateTime? focusedMonth,
    this.error,
  })  : selectedDate = selectedDate ?? DateTime.now(),
        focusedMonth = focusedMonth ?? DateTime.now();

  CalendarState copyWith({
    bool? isLoading,
    Map<String, DayAggregateDto>? aggregates,
    List<ChoreOccurrenceDto>? selectedDayOccurrences,
    DateTime? selectedDate,
    DateTime? focusedMonth,
    String? error,
  }) {
    return CalendarState(
      isLoading: isLoading ?? this.isLoading,
      aggregates: aggregates ?? this.aggregates,
      selectedDayOccurrences:
          selectedDayOccurrences ?? this.selectedDayOccurrences,
      selectedDate: selectedDate ?? this.selectedDate,
      focusedMonth: focusedMonth ?? this.focusedMonth,
      error: error,
    );
  }
}

class CalendarNotifier extends StateNotifier<CalendarState> {
  final CalendarApi _api;
  final String? _householdId;

  bool _isFetching = false;

  CalendarNotifier(this._api, this._householdId) : super(CalendarState());

  final _dateFmt = DateFormat('yyyy-MM-dd');

  /// Load aggregates for currently focused month.
  Future<void> loadMonth([DateTime? month]) async {
    if (_householdId == null || _isFetching) return;
    _isFetching = true;

    final m = month ?? state.focusedMonth;
    final from = DateTime(m.year, m.month, 1);
    final to = DateTime(m.year, m.month + 1, 0); // last day of month

    state = state.copyWith(isLoading: true, error: null, focusedMonth: m);

    final fromStr = _dateFmt.format(from);
    final toStr = _dateFmt.format(to);

    try {
      final aggregates = await _api.getAggregates(
        householdId: _householdId!,
        from: fromStr,
        to: toStr,
      );
      final map = {for (final a in aggregates) a.date: a};
      state = state.copyWith(isLoading: false, aggregates: map);
    } on ApiException catch (e) {
      state = state.copyWith(isLoading: false, error: e.message);
    } finally {
      _isFetching = false;
    }
  }

  /// Select a day and load its occurrences.
  Future<void> selectDay(DateTime day) async {
    if (_householdId == null) return;

    state = state.copyWith(selectedDate: day);
    final dateStr = _dateFmt.format(day);

    try {
      final occurrences = await _api.getOccurrences(
        householdId: _householdId!,
        from: dateStr,
        to: dateStr,
      );
      state = state.copyWith(selectedDayOccurrences: occurrences);
    } on ApiException catch (_) {
      // Keep existing occurrences on error
    }
  }

  void changeFocusedMonth(DateTime month) {
    loadMonth(month);
  }
}

final calendarProvider =
    StateNotifierProvider<CalendarNotifier, CalendarState>((ref) {
  return CalendarNotifier(
    ref.watch(calendarApiProvider),
    ref.watch(currentHouseholdIdProvider),
  );
});
