import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:msupperlimbs/core/application/locale_provider.dart';

/// Seletor 🇬🇧 / 🇧🇷 no AppBar.
class LocaleSwitcher extends ConsumerWidget {
  const LocaleSwitcher({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final current = ref.watch(localeProvider);

    return PopupMenuButton<String>(
      icon: const Icon(Icons.language),
      tooltip: 'Language',
      initialValue: current.languageCode,
      onSelected: (code) {
        ref.read(localeProvider.notifier).changeLocale(Locale(code));
      },
      itemBuilder: (context) => const [
        PopupMenuItem(value: 'en', child: Text('🇬🇧 English')),
        PopupMenuItem(value: 'pt', child: Text('🇧🇷 Português')),
      ],
    );
  }
}
