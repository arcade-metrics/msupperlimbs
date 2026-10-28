import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:msupperlimbs/gen_l10n/app_localizations.dart';
import 'package:msupperlimbs/features/user/application/user_state.dart';
import 'dart:io';
import 'dart:convert'; // Added for utf8.decoder

class ConsentScreen extends ConsumerStatefulWidget {
  const ConsentScreen({super.key});

  @override
  ConsumerState<ConsentScreen> createState() => _ConsentScreenState();
}

class _ConsentScreenState extends ConsumerState<ConsentScreen> {
  bool _checked = false;

  Future<String?> _getUserIP() async {
    try {
      // Method 1: Try external IP via service
      final response =
          await HttpClient().getUrl(Uri.parse('https://api.ipify.org'));
      final result = await response.close();
      final ip = await result.transform(utf8.decoder).join();
      if (ip.isNotEmpty) return ip;
    } catch (e) {
      print('Error getting external IP: $e');
    }

    try {
      // Method 2: Fallback for DNS lookup
      final result = await InternetAddress.lookup('google.com');
      return result.first.address;
    } catch (e) {
      print('Error getting IP via DNS: $e');
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(userProvider);
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.consent_title)),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.consent_requireConsent,
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Checkbox(
                  value: _checked,
                  onChanged: (v) => setState(() => _checked = v ?? false),
                ),
                Expanded(
                  child: Text(l10n.consent_checkboxText),
                ),
              ],
            ),
            const Spacer(),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => context.go('/login'),
                    child: Text(l10n.consent_exit),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: !_checked || user == null
                        ? null
                        : () async {
                            final ipAddress = await _getUserIP();
                            await ref.read(userProvider.notifier).updateUser(
                                  user.copyWith(
                                    hasConsent: true,
                                    consentTimestamp:
                                        DateTime.now().toIso8601String(),
                                    consentVersion: 'v1.0',
                                    consentRevokedAt: null,
                                    ipAddress: ipAddress,
                                  ),
                                );
                            if (context.mounted) context.go('/home');
                          },
                    child: Text(l10n.consent_proceed),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class ConsentFullScreen extends StatelessWidget {
  const ConsentFullScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.consent_participantInfo)),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: SingleChildScrollView(
                child: Text(
                  l10n.consent_fullText,
                  style: const TextStyle(fontSize: 16),
                ),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                child: Text(l10n.common_back),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
