import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:msupperlimbs/core/network/api_error_messages.dart';
import 'package:msupperlimbs/core/widgets/brand_logo.dart';
import 'package:msupperlimbs/core/widgets/locale_switcher.dart';
import 'package:msupperlimbs/features/auth/application/auth_notifier.dart';
import 'package:msupperlimbs/features/auth/domain/password_policy.dart';
import 'package:msupperlimbs/l10n/generated/app_localizations.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _name = TextEditingController();
  bool _isRegister = false;
  bool _busy = false;

  static const _appVersion = '0.1.0';

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    _name.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final l10n = AppLocalizations.of(context);
    if (!_formKey.currentState!.validate()) return;

    setState(() => _busy = true);
    final auth = ref.read(authProvider.notifier);
    if (_isRegister) {
      await auth.register(
        email: _email.text.trim(),
        password: _password.text,
        name: _name.text.trim(),
      );
    } else {
      await auth.login(_email.text.trim(), _password.text);
    }
    if (!mounted) return;
    setState(() => _busy = false);

    final state = ref.read(authProvider);
    if (state.status == AuthStatus.authenticated) {
      context.go('/home');
    } else if (state.error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(apiErrorMessage(l10n, state.error!))),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(_isRegister ? l10n.auth_createAccount : l10n.auth_login),
        actions: const [LocaleSwitcher()],
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
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const SizedBox(height: 8),
                        const BrandLogo(height: 100),
                        const SizedBox(height: 16),
                        Text(
                          l10n.app_title,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          l10n.app_versionLabel(_appVersion),
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: Theme.of(
                              context,
                            ).colorScheme.onSurface.withValues(alpha: 0.6),
                          ),
                        ),
                        const SizedBox(height: 24),
                        if (_isRegister) ...[
                          TextFormField(
                            controller: _name,
                            decoration: InputDecoration(
                              labelText: l10n.common_name,
                            ),
                            validator: (v) => (v == null || v.trim().isEmpty)
                                ? l10n.auth_nameRequired
                                : null,
                          ),
                          const SizedBox(height: 10),
                        ],
                        TextFormField(
                          controller: _email,
                          keyboardType: TextInputType.emailAddress,
                          decoration: InputDecoration(
                            labelText: l10n.common_email,
                          ),
                          validator: (v) => (v == null || !v.contains('@'))
                              ? l10n.auth_emailInvalid
                              : null,
                        ),
                        const SizedBox(height: 10),
                        TextFormField(
                          controller: _password,
                          obscureText: true,
                          decoration: InputDecoration(
                            labelText: l10n.common_password,
                          ),
                          validator: (v) {
                            if (v == null || v.isEmpty) {
                              return l10n.auth_passwordRequired;
                            }
                            if (_isRegister && !meetsPasswordPolicy(v)) {
                              return l10n.auth_passwordPolicy;
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 20),
                        if (_busy)
                          const Center(child: CircularProgressIndicator())
                        else
                          ElevatedButton(
                            onPressed: _submit,
                            style: ElevatedButton.styleFrom(
                              minimumSize: const Size(double.infinity, 48),
                            ),
                            child: Text(
                              _isRegister ? l10n.auth_signup : l10n.auth_login,
                            ),
                          ),
                        TextButton(
                          onPressed: _busy
                              ? null
                              : () =>
                                    setState(() => _isRegister = !_isRegister),
                          child: Text(
                            _isRegister
                                ? l10n.auth_haveAccountQuestion
                                : l10n.auth_noAccountQuestion,
                          ),
                        ),
                        const Spacer(),
                      ],
                    ),
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
