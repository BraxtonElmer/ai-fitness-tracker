import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../theme.dart';
import '../services/food_log_service.dart';
import 'result_screen.dart';

class FoodLogScreen extends StatefulWidget {
  const FoodLogScreen({super.key});

  @override
  State<FoodLogScreen> createState() => _FoodLogScreenState();
}

class _FoodLogScreenState extends State<FoodLogScreen> {
  final FoodLogService _log = FoodLogService.instance;
  List<FoodLogEntry> _entries = [];
  bool _loading = true;
  String? _err;

  @override
  void initState() {
    super.initState();
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
      final e = await _log.allEntries();
      if (mounted) {
        setState(() {
          _entries = e;
          _loading = false;
        });
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

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.x2),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: AppSpacing.x4),
            Text('Food log', style: AppTextStyles.heading),
            const SizedBox(height: AppSpacing.x1),
            Text(
              'Saved on this device',
              style: AppTextStyles.body.copyWith(
                color: AppColors.mutedText,
              ),
            ),
            const SizedBox(height: AppSpacing.x3),
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
            else if (_entries.isEmpty)
              const Expanded(
                child: _EmptyState(),
              )
            else
              Expanded(
                child: ListView.separated(
                  itemCount: _entries.length,
                  separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.x2),
                  itemBuilder: (context, i) {
                    final e = _entries[i];
                    return _LogTile(
                      entry: e,
                      onOpen: () {
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
                      },
                      onDelete: () => _delete(e),
                    );
                  },
                ),
              ),
          ],
        ),
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
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            LucideIcons.clipboard,
            size: 40,
            color: AppColors.mutedText,
          ),
          const SizedBox(height: AppSpacing.x2),
          Text(
            'No meals logged yet',
            style: AppTextStyles.headingSmall,
          ),
          const SizedBox(height: AppSpacing.x1),
          Text(
            'Successful scans are saved here automatically',
            textAlign: TextAlign.center,
            style: AppTextStyles.body.copyWith(
              color: AppColors.mutedText,
            ),
          ),
        ],
      ),
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
