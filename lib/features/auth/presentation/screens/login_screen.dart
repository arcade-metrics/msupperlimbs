import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:msupperlimbs/gen_l10n/app_localizations.dart';
import 'package:msupperlimbs/core/utils/screen_orientation.dart';
import 'package:msupperlimbs/features/auth/application/auth_state.dart';
import 'package:msupperlimbs/features/user/application/user_state.dart';
import 'package:msupperlimbs/core/application/locale_provider.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  bool isLoading = false;
  String appVersion = 'latest';

  @override
  void initState() {
    super.initState();
    lockToPortrait();
    _loadAppVersion();
  }

  Future<void> _loadAppVersion() async {
    final info = await PackageInfo.fromPlatform();
    setState(() {
      appVersion = '${info.version}+${info.buildNumber}';
    });
  }

  Future<void> _login() async {
    setState(() => isLoading = true);
    final auth = ref.read(authServiceProvider);
    final user = await auth.signInWithEmail(
      ref,
      emailController.text.trim(),
      passwordController.text.trim(),
    );
    setState(() => isLoading = false);

    if (user != null) {
      await ref.read(userProvider.notifier).loadUser(user.uid);
      final loadedUser = ref.read(userProvider);
      if (mounted) {
        final l10n = AppLocalizations.of(context)!;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.auth_loginSuccessful)),
        );
      }
      if (loadedUser != null && loadedUser.hasConsent == true) {
        context.go('/home');
      } else {
        context.go('/consent');
      }
    } else {
      if (mounted) {
        final l10n = AppLocalizations.of(context)!;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.auth_invalidCredentials)),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDarkTheme = Theme.of(context).brightness == Brightness.dark;
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.auth_login),
        actions: [
          // Language switcher in app bar
          PopupMenuButton<String>(
            icon: const Icon(Icons.language),
            onSelected: (String languageCode) {
              ref.read(localeProvider.notifier).changeLocale(Locale(languageCode));
            },
            itemBuilder: (BuildContext context) => [
              const PopupMenuItem<String>(
                value: 'en',
                child: Row(
                  children: [
                    Text('🇬🇧 '),
                    SizedBox(width: 8),
                    Text('English'),
                  ],
                ),
              ),
              const PopupMenuItem<String>(
                value: 'pt',
                child: Row(
                  children: [
                    Text('🇧🇷 '),
                    SizedBox(width: 8),
                    Text('Português'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom,
            ),
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight),
              child: IntrinsicHeight(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16.0, 8.0, 16.0, 16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const SizedBox(height: 8), // Reduced spacing
                      Image.asset(
                        isDarkTheme
                            ? 'assets/logo-dark-1024x1024.png'
                            : 'assets/logo-light-1024x1024.png',
                        height: 100,
                        fit: BoxFit.contain,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        l10n.app_title,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                            fontSize: 24, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '${l10n.app_subtitle} $appVersion',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                            fontSize: 10, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 24),
                                             TextField(
                         controller: emailController,
                         decoration: InputDecoration(labelText: l10n.common_email),
                         keyboardType: TextInputType.emailAddress,
                       ),
                      const SizedBox(height: 10),
                                             TextField(
                         controller: passwordController,
                         decoration:
                             InputDecoration(labelText: l10n.common_password),
                         obscureText: true,
                       ),
                      const SizedBox(height: 20),
                      isLoading
                          ? const Center(child: CircularProgressIndicator())
                                                     : ElevatedButton(
                               onPressed: _login,
                               child: Text(l10n.auth_login),
                             ),
                      TextButton(
                        onPressed: () {
                          context.go('/signup');
                        },
                                                 child: Text("${l10n.auth_noAccountQuestion} ${l10n.auth_signup}"),
                      ),
                      const SizedBox(height: 24.0),
                                             Text(
                         l10n.common_or,
                         textAlign: TextAlign.center,
                         style: const TextStyle(
                             fontSize: 16.0, fontWeight: FontWeight.bold),
                       ),
                      const SizedBox(height: 24.0),
                      ElevatedButton.icon(
                        onPressed: () async {
                          final auth = ref.read(authServiceProvider);
                          final user = await auth.signInWithGoogle(ref);
                          if (user != null) {
                            if (mounted) {
                              final l10n = AppLocalizations.of(context)!;
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                    content:
                                        Text(l10n.auth_googleLoginSuccessful)),
                              );
                            }
                            context.go('/home');
                          } else {
                            if (mounted) {
                              final l10n = AppLocalizations.of(context)!;
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                    content: Text(l10n.auth_googleLoginFailed)),
                              );
                            }
                          }
                        },
                        icon: Image.asset(
                          'assets/images/global/google_icon_color-512x512.png',
                          width: 20,
                        ),
                                                 label: Text(l10n.auth_signInWithGoogle),
                      ),
                                             const Spacer(),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
