import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pawsure_app/core/i18n/l10n/app_localizations.dart';
import '../../core/theme/theme_provider.dart';
import '../../core/i18n/locale_provider.dart';

class SettingsBottomSheet extends ConsumerWidget {
  const SettingsBottomSheet({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = S.of(context)!;
    final themeState = ref.watch(themeNotifierProvider);
    final locale = ref.watch(localeNotifierProvider);

    return Container(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Text(s.settingsTitle, style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 20),

          // 主题切换
          Text('主题', style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: 8),
          SegmentedButton<AppThemeMode>(
            segments: [
              ButtonSegment(
                  value: AppThemeMode.light,
                  label: Text(s.themeLight),
                  icon: const Icon(Icons.light_mode)),
              ButtonSegment(
                  value: AppThemeMode.dark,
                  label: Text(s.themeDark),
                  icon: const Icon(Icons.dark_mode)),
              ButtonSegment(
                  value: AppThemeMode.system,
                  label: Text(s.themeSystem),
                  icon: const Icon(Icons.brightness_auto)),
            ],
            selected: {themeState},
            onSelectionChanged: (modes) =>
                ref.read(themeNotifierProvider.notifier).setTheme(modes.first),
          ),

          const SizedBox(height: 24),

          // 语言切换
          Text('语言 / Language', style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: 8),
          SegmentedButton<Locale>(
            segments: [
              ButtonSegment(
                  value: const Locale('zh'), label: Text(s.langZh)),
              ButtonSegment(
                  value: const Locale('en'), label: Text(s.langEn)),
            ],
            selected: {locale},
            onSelectionChanged: (locales) => ref
                .read(localeNotifierProvider.notifier)
                .setLocale(locales.first),
          ),

          const SizedBox(height: 16),
        ],
      ),
    );
  }
}
