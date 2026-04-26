import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../theme.dart';
import '../tdee/mifflin_tdee.dart';
import '../services/user_profile_service.dart';

class BmiScreen extends StatefulWidget {
  const BmiScreen({super.key});

  @override
  State<BmiScreen> createState() => _BmiScreenState();
}

class _BmiScreenState extends State<BmiScreen> {
  final _height = TextEditingController();
  final _weight = TextEditingController();
  final _age = TextEditingController();
  final _goalOverride = TextEditingController();
  String _sex = 'M';
  String _activityLabel = 'Light (1-3x/wk)';

  double? _bmi;
  int? _suggestedTdee;
  bool _loading = true;
  String? _saveErr;

  final _profile = UserProfileService.instance;

  @override
  void initState() {
    super.initState();
    _loadSaved();
  }

  @override
  void dispose() {
    _height.dispose();
    _weight.dispose();
    _age.dispose();
    _goalOverride.dispose();
    super.dispose();
  }

  Future<void> _loadSaved() async {
    final p = await _profile.getProfile();
    if (mounted) {
      setState(() {
        if (p.heightCm != null) {
          _height.text = p.heightCm!.toStringAsFixed(0);
        }
        if (p.weightKg != null) {
          _weight.text = p.weightKg!.toStringAsFixed(1);
        }
        if (p.age != null) {
          _age.text = p.age.toString();
        } else {
          _age.text = '28';
        }
        if (p.sex == 'F') {
          _sex = 'F';
        }
        if (p.activity != null) {
          _activityLabel = activityLabelByFactor(p.activity!);
        }
        if (p.dailyKcalGoal != null) {
          _goalOverride.text = p.dailyKcalGoal.toString();
        }
        if (p.bmi != null) {
          _bmi = p.bmi;
        }
        _loading = false;
      });
    }
  }

  void _recalc() {
    setState(() {
      _compute();
      _saveErr = null;
    });
  }

  bool _compute() {
    final hCm = double.tryParse(_height.text.trim().replaceAll(',', '.'));
    final wKg = double.tryParse(_weight.text.trim().replaceAll(',', '.'));
    final age = int.tryParse(_age.text.trim()) ?? 30;
    if (hCm == null || wKg == null || hCm <= 0) {
      _bmi = null;
      _suggestedTdee = null;
      return false;
    }
    final m = hCm / 100.0;
    if (m <= 0) {
      return false;
    }
    final b = wKg / (m * m);
    _bmi = b;
    final tdee = MifflinTdee.tdeeKcal(
      weightKg: wKg,
      heightCm: hCm,
      age: age,
      isMale: _sex == 'M',
      activityFactor: activityFactorByLabel(_activityLabel),
    );
    _suggestedTdee = tdee.round();
    if (_goalOverride.text.trim().isEmpty) {
      _goalOverride.text = _suggestedTdee.toString();
    }
    return true;
  }

  Future<void> _save() async {
    if (!_compute() || _bmi == null) {
      setState(() {
        _saveErr = 'Enter valid height, weight, and age';
      });
      return;
    }
    final h = double.parse(_height.text.trim().replaceAll(',', '.'));
    final w = double.parse(_weight.text.trim().replaceAll(',', '.'));
    final age = int.tryParse(_age.text.trim()) ?? 28;
    final goal = int.tryParse(_goalOverride.text.trim().replaceAll(',', '.'));
    if (goal == null || goal < 500) {
      setState(() {
        _saveErr = 'Set a daily kcal target (e.g. suggested or your own, min 500).';
      });
      return;
    }
    try {
      await _profile.saveProfileAndLogBmi(
        heightCm: h,
        weightKg: w,
        bmi: _bmi!,
        age: age,
        sex: _sex,
        activityFactor: activityFactorByLabel(_activityLabel),
        suggestedTdee: _suggestedTdee,
        dailyKcalGoal: goal,
      );
      if (mounted) {
        Navigator.of(context).pop();
      }
    } catch (_) {
      setState(() {
        _saveErr = 'Could not save. Try again.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        leading: IconButton(
          onPressed: () => Navigator.of(context).pop(),
          icon: const Icon(LucideIcons.chevronLeft, color: AppColors.accent),
        ),
        title: Text(
          'BMI & daily goal',
          style: AppTextStyles.heading.copyWith(fontSize: AppFontSizes.lg),
        ),
        elevation: 0,
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.accent),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(AppSpacing.x2),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Height, weight, age, and activity set your maintenance kcal (Mifflin). '
                    'Set your max kcal to eat per day as a limit — often near maintenance or lower for a deficit.',
                    style: AppTextStyles.body.copyWith(
                      color: AppColors.mutedText,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.x3),
                  TextField(
                    controller: _height,
                    onChanged: (_) => _recalc(),
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'[\d.]')),
                    ],
                    style: AppTextStyles.body,
                    decoration: _dec('Height', 'cm'),
                  ),
                  const SizedBox(height: AppSpacing.x2),
                  TextField(
                    controller: _weight,
                    onChanged: (_) => _recalc(),
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'[\d.]')),
                    ],
                    style: AppTextStyles.body,
                    decoration: _dec('Weight', 'kg'),
                  ),
                  const SizedBox(height: AppSpacing.x2),
                  TextField(
                    controller: _age,
                    onChanged: (_) => _recalc(),
                    keyboardType: TextInputType.number,
                    style: AppTextStyles.body,
                    decoration: _dec('Age', 'years'),
                  ),
                  const SizedBox(height: AppSpacing.x2),
                  Text('Sex (for BMR estimate)', style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.mutedText,
                  )),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      _sexChip('M', 'Male'),
                      const SizedBox(width: 8),
                      _sexChip('F', 'Female'),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.x2),
                  Text('Activity (for daily burn)', style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.mutedText,
                  )),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      border: Border.all(color: AppColors.border),
                      borderRadius: AppRadius.borderRadius,
                    ),
                    child: DropdownButton<String>(
                      isExpanded: true,
                      value: kActivityLabelToFactor.containsKey(_activityLabel)
                          ? _activityLabel
                          : 'Light (1-3x/wk)',
                      underline: const SizedBox.shrink(),
                      items: kActivityLabelToFactor.keys
                          .map(
                            (k) => DropdownMenuItem(
                              value: k,
                              child: Text(
                                k,
                                style: AppTextStyles.body,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          )
                          .toList(),
                      onChanged: (v) {
                        if (v != null) {
                          setState(() {
                            _activityLabel = v;
                          });
                          _recalc();
                        }
                      },
                    ),
                  ),
                  const SizedBox(height: AppSpacing.x2),
                  SizedBox(
                    height: 48,
                    child: OutlinedButton(
                      onPressed: () {
                        setState(_recalc);
                      },
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.accent,
                        side: const BorderSide(color: AppColors.accent),
                        shape: RoundedRectangleBorder(
                          borderRadius: AppRadius.borderRadius,
                        ),
                      ),
                      child: const Text('UPDATE ESTIMATE'),
                    ),
                  ),
                  if (_bmi != null) ...[
                    const SizedBox(height: AppSpacing.x3),
                    Center(
                      child: Text(
                        'BMI ${_bmi!.toStringAsFixed(1)}',
                        style: const TextStyle(
                          fontFamily: 'ClashGrotesk',
                          fontWeight: FontWeight.w600,
                          fontSize: 36,
                          color: AppColors.primaryText,
                        ),
                      ),
                    ),
                    if (_suggestedTdee != null) ...[
                      const SizedBox(height: AppSpacing.x2),
                      Center(
                        child: Text(
                          'Suggested maintenance ≈ $_suggestedTdee kcal / day',
                          textAlign: TextAlign.center,
                          style: AppTextStyles.body.copyWith(
                            color: AppColors.accent,
                          ),
                        ),
                      ),
                    ],
                  ],
                  const SizedBox(height: AppSpacing.x3),
                  Text(
                    'Daily kcal limit (max to eat today — shown on home)',
                    style: AppTextStyles.label,
                  ),
                  const SizedBox(height: 4),
                  TextField(
                    controller: _goalOverride,
                    keyboardType: TextInputType.number,
                    style: AppTextStyles.body,
                    decoration: _dec('Target', 'kcal / day'),
                  ),
                  if (_saveErr != null) ...[
                    const SizedBox(height: AppSpacing.x2),
                    Text(
                      _saveErr!,
                      style: AppTextStyles.body.copyWith(
                        color: AppColors.error,
                      ),
                    ),
                  ],
                  const SizedBox(height: AppSpacing.x2),
                  Text(
                    'Saves your BMI in history and your daily kcal cap for the tracker.',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.mutedText,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.x3),
                  SizedBox(
                    height: 52,
                    child: ElevatedButton(
                      onPressed: _save,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.accent,
                        foregroundColor: AppColors.background,
                        shape: RoundedRectangleBorder(
                          borderRadius: AppRadius.borderRadius,
                        ),
                        elevation: 0,
                      ),
                      child: Text('SAVE & USE ON HOME', style: AppTextStyles.buttonText),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _sexChip(String val, String label) {
    final sel = _sex == val;
    return ChoiceChip(
      label: Text(label),
      selected: sel,
      onSelected: (_) {
        setState(() => _sex = val);
        _recalc();
      },
      selectedColor: AppColors.accent,
      backgroundColor: AppColors.surface,
      labelStyle: AppTextStyles.bodySmall.copyWith(
        color: sel ? AppColors.background : AppColors.primaryText,
      ),
    );
  }

  InputDecoration _dec(String label, String unit) {
    return InputDecoration(
      labelText: '$label ($unit)',
      labelStyle: AppTextStyles.label.copyWith(
        color: AppColors.mutedText,
      ),
      filled: true,
      fillColor: AppColors.surface,
      border: OutlineInputBorder(
        borderRadius: AppRadius.borderRadius,
        borderSide: const BorderSide(color: AppColors.border),
      ),
    );
  }

}
