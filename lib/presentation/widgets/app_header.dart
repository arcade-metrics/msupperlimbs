import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:msupperlimbs/gen_l10n/app_localizations.dart';
import 'package:msupperlimbs/features/user/application/user_state.dart';
import 'package:msupperlimbs/core/application/locale_provider.dart';

class AppHeader extends ConsumerWidget implements PreferredSizeWidget {
  final String title;

  const AppHeader({
    super.key,
    required this.title,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userState = ref.watch(userProvider);
    final l10n = AppLocalizations.of(context)!;
    final subtitle = userState?.displayName ?? l10n.home_noUserLoggedIn;
    final currentLocale = ref.watch(localeProvider);

    return AppBar(
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title),
          Text(
            subtitle,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.white70,
                ),
          ),
        ],
      ),
      actions: [
        DropdownButtonHideUnderline(
          child: DropdownButton<String>(
            items: const [
              DropdownMenuItem(
                value: 'en',
                child: Text('🇬🇧', style: TextStyle(fontSize: 20.0)),
              ),
              DropdownMenuItem(
                value: 'pt',
                child: Text('🇧🇷', style: TextStyle(fontSize: 20.0)),
              ),
            ],
            onChanged: (value) {
              if (value != null) {
                ref
                    .read(localeProvider.notifier)
                    .changeLocale(Locale(value));
              }
            },
            value: currentLocale.languageCode,
          ),
        ),
      ],
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
