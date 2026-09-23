import 'package:flutter/material.dart';

import '../core/app_scope.dart';
import '../core/theme.dart';
import '../services/stats_service.dart';

Future<void> showSettingsSheet(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    builder: (_) => const _SettingsSheet(),
  );
}

class _SettingsSheet extends StatelessWidget {
  const _SettingsSheet();

  Future<void> _confirmReset(BuildContext context) async {
    final stats = AppScope.read(context);
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        icon: const Icon(
          Icons.warning_amber_rounded,
          color: AppColors.wrong,
          size: 40,
        ),
        title: const Text('مسح كل البيانات؟'),
        content: const Text(
          'سيتم حذف سجل الاختبارات وأفضل النتائج والمستوى. لا يمكن التراجع عن هذا.',
          textAlign: TextAlign.center,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('إلغاء'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.wrong),
            child: const Text('مسح'),
          ),
        ],
      ),
    );
    if (ok == true) {
      await stats.reset();
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('تم مسح البيانات')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final stats = AppScope.of(context);

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'الإعدادات',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'المظهر',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: SegmentedButton<ThemeModeSetting>(
                segments: const [
                  ButtonSegment(
                    value: ThemeModeSetting.light,
                    icon: Icon(Icons.light_mode_rounded),
                    label: Text('فاتح'),
                  ),
                  ButtonSegment(
                    value: ThemeModeSetting.system,
                    icon: Icon(Icons.brightness_auto_rounded),
                    label: Text('تلقائي'),
                  ),
                  ButtonSegment(
                    value: ThemeModeSetting.dark,
                    icon: Icon(Icons.dark_mode_rounded),
                    label: Text('داكن'),
                  ),
                ],
                selected: {stats.themeMode},
                onSelectionChanged: (s) => stats.setThemeMode(s.first),
              ),
            ),
            const SizedBox(height: 12),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              secondary: const Icon(Icons.vibration_rounded),
              title: const Text('الاهتزاز'),
              subtitle: const Text('اهتزاز خفيف عند الإجابة'),
              value: stats.hapticsEnabled,
              onChanged: stats.setHaptics,
            ),
            const Divider(),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(
                Icons.delete_forever_rounded,
                color: AppColors.wrong,
              ),
              title: const Text(
                'مسح كل البيانات',
                style: TextStyle(color: AppColors.wrong),
              ),
              onTap: () => _confirmReset(context),
            ),
          ],
        ),
      ),
    );
  }
}
