import 'dart:io';

import 'package:app_settings/app_settings.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../theme.dart';
import '../services/health_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  String _version = '';
  String? _hcStatusText;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final info = await PackageInfo.fromPlatform();
    if (Platform.isAndroid) {
      final ok = await HealthService.isAvailable();
      if (mounted) {
        setState(() {
          _version = '${info.version} (${info.buildNumber})';
          _hcStatusText = _healthStatusText(ok);
        });
      }
    } else {
      if (mounted) {
        setState(() {
          _version = '${info.version} (${info.buildNumber})';
        });
      }
    }
  }

  String _healthStatusText(bool available) {
    if (!available) {
      return 'Health Connect is not available on this device.';
    }
    return 'Health Connect is ready. Grant access to show steps, active calories, and sleep.';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(LucideIcons.arrowLeft, color: AppColors.primaryText),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text('Settings', style: AppTextStyles.headingSmall),
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.x2),
        children: [
          if (Platform.isAndroid) ...[
            Text('Android & Health', style: AppTextStyles.label),
            const SizedBox(height: AppSpacing.x1),
            Text(
              _hcStatusText ?? 'Checking Health Connect…',
              style: AppTextStyles.body.copyWith(
                color: AppColors.secondaryText,
              ),
            ),
            const SizedBox(height: AppSpacing.x2),
            _tile(
              icon: LucideIcons.shield,
              title: 'Re-check Health access',
              subtitle: 'Opens the system permission flow',
              onTap: () async {
                final g = await HealthService.requestPermissions();
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        g
                            ? 'Access granted or updated.'
                            : 'No access — check Health Connect in system settings.',
                        style: const TextStyle(color: AppColors.background),
                      ),
                      backgroundColor: AppColors.accent,
                    ),
                  );
                }
                await _load();
              },
            ),
            _tile(
              icon: LucideIcons.smartphone,
              title: 'App settings (FitCore)',
              subtitle: 'Notifications, app info, manual permissions',
              onTap: () => AppSettings.openAppSettings(
                asAnotherTask: true,
              ),
            ),
            _tile(
              icon: LucideIcons.activity,
              title: 'Health Connect in Play Store',
              subtitle: 'Install or update the Health Connect app',
              onTap: () => _openStore(),
            ),
            const SizedBox(height: AppSpacing.x4),
          ],
          Text('About', style: AppTextStyles.label),
          const SizedBox(height: AppSpacing.x1),
          Text('FitCore AI', style: AppTextStyles.headingSmall),
          if (_version.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              'Version $_version',
              style: AppTextStyles.body.copyWith(
                color: AppColors.mutedText,
              ),
            ),
          ],
          const SizedBox(height: AppSpacing.x2),
          Text(
            'Your food log, BMI history, and goals are stored only on this device. '
            'Health data is read from Health Connect on Android and is not sent to our servers.',
            style: AppTextStyles.body.copyWith(
              color: AppColors.secondaryText,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _openStore() async {
    final u = Uri.parse(
      'https://play.google.com/store/apps/details?id=com.google.android.apps.healthdata',
    );
    if (await canLaunchUrl(u)) {
      await launchUrl(u, mode: LaunchMode.externalApplication);
    }
  }

  Widget _tile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.x1),
      child: Material(
        color: AppColors.surface,
        borderRadius: AppRadius.borderRadius,
        child: ListTile(
          leading: Icon(icon, color: AppColors.accent, size: 20),
          title: Text(title, style: AppTextStyles.label),
          subtitle: Text(
            subtitle,
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.mutedText,
            ),
          ),
          onTap: onTap,
        ),
      ),
    );
  }
}
