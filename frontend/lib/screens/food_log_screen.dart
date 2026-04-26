import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:table_calendar/table_calendar.dart';

import '../theme.dart';
import '../services/food_log_service.dart';
import 'progress_screen.dart';
import 'result_screen.dart';

enum _LogViewMode { byDay, all }

class FoodLogScreen extends StatefulWidget {
  const FoodLogScreen({super.key});

  @override
  State<FoodLogScreen> createState() => _FoodLogScreenState();
}

class _FoodLogScreenState extends State<FoodLogScreen> {
  final FoodLogService _log = FoodLogService.instance;
  _LogViewMode _mode = _LogViewMode.byDay;

  late DateTime _focusedDay;
  late DateTime _selectedDay;
  Set<DateTime> _daysWithEntry = {};
  List<FoodLogEntry> _dayEntries = [];
  List<FoodLogEntry> _allEntries = [];
  final Map<DateTime, List<FoodLogEntry>> _byDay = {};

  bool _loading = true;
  String? _err;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _focusedDay = now;
    _selectedDay = now;
    _log.addListener(_onLog);
    _load();
  }

  @override
  void dispose() {
    _log.removeListener(_onLog);
    super.dispose();
  }

  void _onLog() => _load();

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _err = null;
    });
    try {
      await _loadMonthMarkers();
      if (_mode == _LogViewMode.byDay) {
        final d = await _log.entriesForDay(_selectedDay);
        if (mounted) {
          setState(() {
            _dayEntries = d;
            _loading = false;
          });
        }
      } else {
        final e = await _log.allEntries(limit: 500);
        _rebuildByDayMap(e);
        if (mounted) {
          setState(() {
            _allEntries = e;
            _loading = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _err = 'Could not load your log';
          _loading = false;
        });
      }
    }
  }

  void _rebuildByDayMap(List<FoodLogEntry> entries) {
    _byDay.clear();
    for (final e in entries) {
      final d = FoodLogService.dateOnly(
        DateTime.fromMillisecondsSinceEpoch(e.createdAtMs),
      );
      _byDay.putIfAbsent(d, () => []).add(e);
    }
    for (final list in _byDay.values) {
      list.sort((a, b) => b.createdAtMs.compareTo(a.createdAtMs));
    }
  }

  Future<void> _loadMonthMarkers() async {
    final f = _focusedDay;
    final from = DateTime(f.year, f.month, 1);
    final to = DateTime(f.year, f.month + 1, 0);
    final s = await _log.daysWithEntriesInRange(from, to);
    if (mounted) {
      setState(() {
        _daysWithEntry = s;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        centerTitle: false,
        title: Text('Food log', style: AppTextStyles.headingSmall),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).push(
                PageRouteBuilder(
                  pageBuilder: (c, a, s) => const ProgressScreen(),
                  transitionsBuilder: (c, a, s, child) =>
                      FadeTransition(opacity: a, child: child),
                ),
              );
            },
            child: Text(
              'Stats',
              style: AppTextStyles.label.copyWith(color: AppColors.accent),
            ),
          ),
        ],
      ),
      body: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.x2),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Saved on this device',
                style: AppTextStyles.body.copyWith(
                  color: AppColors.mutedText,
                ),
              ),
              const SizedBox(height: AppSpacing.x2),
              SegmentedButton<_LogViewMode>(
                style: const ButtonStyle(
                  visualDensity: VisualDensity(vertical: -1),
                ),
                segments: const [
                  ButtonSegment(
                    value: _LogViewMode.byDay,
                    label: Text('By day'),
                  ),
                  ButtonSegment(
                    value: _LogViewMode.all,
                    label: Text('All'),
                  ),
                ],
                selected: {_mode},
                onSelectionChanged: (set) {
                  setState(() {
                    _mode = set.first;
                  });
                  _load();
                },
              ),
              const SizedBox(height: AppSpacing.x2),
              if (_mode == _LogViewMode.byDay) _buildCalendar(),
              if (_loading)
                const Expanded(
                  child: Center(
                    child: CircularProgressIndicator(color: AppColors.accent),
                  ),
                )
              else if (_err != null)
                Expanded(
                  child: Center(
                    child: Text(_err!, style: AppTextStyles.body),
                  ),
                )
              else if (_mode == _LogViewMode.byDay)
                Expanded(
                  child: _dayEntries.isEmpty
                      ? const _EmptyDay()
                      : ListView.separated(
                          itemCount: _dayEntries.length,
                          separatorBuilder: (_, _) =>
                              const SizedBox(height: AppSpacing.x2),
                          itemBuilder: (context, i) {
                            final e = _dayEntries[i];
                            return _LogTile(
                              entry: e,
                              onOpen: () => _openEntry(context, e),
                              onDelete: () => _delete(e),
                            );
                          },
                        ),
                )
              else
                Expanded(
                  child: _allEntries.isEmpty
                      ? const _EmptyState()
                      : _buildAllGroupedList(),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCalendar() {
    return TableCalendar<dynamic>(
      firstDay: DateTime.utc(2019, 1, 1),
      lastDay: DateTime.now().add(const Duration(days: 365 * 3)),
      focusedDay: _focusedDay,
      selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
      eventLoader: (day) {
        final d = FoodLogService.dateOnly(day);
        return _daysWithEntry.contains(d) ? [0] : [];
      },
      onDaySelected: (selected, focused) {
        setState(() {
          _selectedDay = selected;
          _focusedDay = focused;
        });
        if (_mode == _LogViewMode.byDay) {
          _load();
        }
      },
      onPageChanged: (focused) {
        setState(() => _focusedDay = focused);
        _loadMonthMarkers();
      },
      startingDayOfWeek: StartingDayOfWeek.monday,
      calendarFormat: CalendarFormat.month,
      availableCalendarFormats: const {CalendarFormat.month: 'Month'},
      calendarStyle: const CalendarStyle(
        outsideDaysVisible: false,
        defaultTextStyle: TextStyle(
          color: AppColors.primaryText,
          fontSize: 13,
        ),
        weekendTextStyle: TextStyle(
          color: AppColors.primaryText,
          fontSize: 13,
        ),
        selectedDecoration: BoxDecoration(
          color: AppColors.accent,
          shape: BoxShape.circle,
        ),
        selectedTextStyle: TextStyle(
          color: AppColors.background,
          fontSize: 13,
          fontWeight: FontWeight.w600,
        ),
        todayDecoration: BoxDecoration(
          color: AppColors.surface,
          shape: BoxShape.circle,
        ),
        todayTextStyle: TextStyle(
          color: AppColors.accent,
          fontSize: 13,
        ),
        defaultDecoration: BoxDecoration(
          shape: BoxShape.circle,
        ),
        markersMaxCount: 1,
        markerSize: 4,
        markerDecoration: BoxDecoration(
          color: AppColors.accent,
          shape: BoxShape.circle,
        ),
        markersAlignment: Alignment.bottomCenter,
      ),
      headerStyle: HeaderStyle(
        titleCentered: true,
        formatButtonVisible: false,
        titleTextStyle: AppTextStyles.label,
        leftChevronIcon: const Icon(
          LucideIcons.chevronLeft,
          color: AppColors.mutedText,
          size: 20,
        ),
        rightChevronIcon: const Icon(
          LucideIcons.chevronRight,
          color: AppColors.mutedText,
          size: 20,
        ),
      ),
      daysOfWeekStyle: const DaysOfWeekStyle(
        weekdayStyle: TextStyle(
          color: AppColors.mutedText,
          fontSize: 11,
        ),
        weekendStyle: TextStyle(
          color: AppColors.mutedText,
          fontSize: 11,
        ),
      ),
    );
  }

  Widget _buildAllGroupedList() {
    final days = _byDay.keys.toList()
      ..sort((a, b) => b.compareTo(a));
    return ListView(
      children: [
        for (final d in days) ...[
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.x1, top: AppSpacing.x1),
            child: Text(
              DateFormat.yMMMd().format(d),
              style: AppTextStyles.label.copyWith(color: AppColors.mutedText),
            ),
          ),
          for (final e in _byDay[d]!) ...[
            _LogTile(
              entry: e,
              onOpen: () => _openEntry(context, e),
              onDelete: () => _delete(e),
            ),
            const SizedBox(height: AppSpacing.x2),
          ],
        ],
      ],
    );
  }

  void _openEntry(BuildContext context, FoodLogEntry e) {
    Navigator.of(context).push(
      PageRouteBuilder(
        pageBuilder: (c, a, s) => ResultScreen(
          nutritionData: e.nutritionData,
          showBack: true,
          showAddToLog: false,
        ),
        transitionsBuilder: (c, a, s, child) {
          return FadeTransition(opacity: a, child: child);
        },
      ),
    );
  }

  Future<void> _delete(FoodLogEntry e) async {
    await _log.deleteEntry(e.id);
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: _EmptyStateBody(
        title: 'No meals logged yet',
        subtitle: 'Scans and manual entries show up here',
      ),
    );
  }
}

class _EmptyDay extends StatelessWidget {
  const _EmptyDay();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: _EmptyStateBody(
        title: 'Nothing logged this day',
        subtitle: 'Pick another day or add food from the home screen',
      ),
    );
  }
}

class _EmptyStateBody extends StatelessWidget {
  final String title;
  final String subtitle;

  const _EmptyStateBody({required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          LucideIcons.clipboard,
          size: 40,
          color: AppColors.mutedText,
        ),
        const SizedBox(height: AppSpacing.x2),
        Text(
          title,
          style: AppTextStyles.headingSmall,
        ),
        const SizedBox(height: AppSpacing.x1),
        Text(
          subtitle,
          textAlign: TextAlign.center,
          style: AppTextStyles.body.copyWith(
            color: AppColors.mutedText,
          ),
        ),
      ],
    );
  }
}

class _LogTile extends StatelessWidget {
  final FoodLogEntry entry;
  final VoidCallback onOpen;
  final VoidCallback onDelete;

  const _LogTile({
    required this.entry,
    required this.onOpen,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final time = DateTime.fromMillisecondsSinceEpoch(entry.createdAtMs);
    final timeStr = DateFormat.MMMd().add_jm().format(time);

    return Dismissible(
      key: ValueKey('log_${entry.id}'),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: AppSpacing.x2),
        color: AppColors.error,
        child: const Icon(LucideIcons.trash2, color: AppColors.background),
      ),
      onDismissed: (_) => onDelete(),
      child: Material(
        color: AppColors.surface,
        borderRadius: AppRadius.borderRadius,
        child: InkWell(
          onTap: onOpen,
          borderRadius: AppRadius.borderRadius,
          child: Container(
            padding: const EdgeInsets.all(AppSpacing.x2),
            decoration: BoxDecoration(
              borderRadius: AppRadius.borderRadius,
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        entry.dishName,
                        style: AppTextStyles.label,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Text(
                            timeStr,
                            style: AppTextStyles.bodySmall.copyWith(
                              color: AppColors.mutedText,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              border: Border.all(
                                color: AppColors.border,
                                width: 1,
                              ),
                              borderRadius: AppRadius.borderRadius,
                            ),
                            child: Text(
                              entry.mealTypeLabel,
                              style: AppTextStyles.bodySmall.copyWith(
                                color: AppColors.accent,
                                fontSize: 10,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: AppSpacing.x2),
                Text(
                  '${entry.calories.round()} kcal',
                  style: AppTextStyles.headingSmall,
                ),
                const Icon(
                  LucideIcons.chevronRight,
                  size: 18,
                  color: AppColors.mutedText,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
