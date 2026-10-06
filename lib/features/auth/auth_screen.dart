import 'package:flutter/material.dart';

import '../../shared/localized_form_validation.dart';

import '../../localization/formatters.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({
    super.key,
    required this.onGoogle,
    required this.onApple,
    required this.onEmail,
    required this.onLocale,
  });
  final Future<void> Function() onGoogle, onApple;
  final Future<void> Function(String email) onEmail;
  final ValueChanged<Locale> onLocale;
  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen>
    with LocalizedFormValidation<AuthScreen> {
  final email = TextEditingController();
  @override
  final form = GlobalKey<FormState>();
  bool busy = false, sent = false, failed = false;
  @override
  void dispose() {
    email.dispose();
    super.dispose();
  }

  Future<void> run(
    Future<void> Function() action, {
    bool emailLink = false,
  }) async {
    setState(() {
      busy = true;
      failed = false;
      sent = false;
    });
    try {
      await action();
      if (mounted) setState(() => sent = emailLink);
    } catch (_) {
      if (mounted) setState(() => failed = true);
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = context.strings;
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 460),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(28),
              child: Form(
                key: form,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.trending_up_rounded, size: 36),
                        const SizedBox(width: 10),
                        Text(
                          s.appName,
                          style: Theme.of(context).textTheme.headlineMedium,
                        ),
                        const Spacer(),
                        DropdownButton<String>(
                          value: Localizations.localeOf(context).languageCode,
                          items: const [
                            DropdownMenuItem(
                              value: 'en',
                              child: Text('English'),
                            ),
                            DropdownMenuItem(
                              value: 'fr',
                              child: Text('Français'),
                            ),
                            DropdownMenuItem(
                              value: 'es',
                              child: Text('Español'),
                            ),
                          ],
                          onChanged: busy
                              ? null
                              : (v) => widget.onLocale(Locale(v!)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 64),
                    Text(
                      s.welcome,
                      style: Theme.of(context).textTheme.displaySmall
                          ?.copyWith(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      s.welcomeBody,
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                    const SizedBox(height: 40),
                    OutlinedButton.icon(
                      onPressed: busy ? null : () => run(widget.onGoogle),
                      icon: const Text(
                        'G',
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF4285F4),
                        ),
                      ),
                      label: Text(s.google),
                    ),
                    const SizedBox(height: 12),
                    FilledButton.icon(
                      style: FilledButton.styleFrom(
                        backgroundColor: Colors.black,
                        foregroundColor: Colors.white,
                      ),
                      onPressed: busy ? null : () => run(widget.onApple),
                      icon: const Icon(Icons.apple),
                      label: Text(s.apple),
                    ),
                    const SizedBox(height: 28),
                    TextFormField(
                      controller: email,
                      decoration: InputDecoration(labelText: s.email),
                      keyboardType: TextInputType.emailAddress,
                      autofillHints: const [AutofillHints.email],
                      validator: (v) =>
                          v != null &&
                              RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$')
                                  .hasMatch(v.trim())
                          ? null
                          : s.required,
                    ),
                    const SizedBox(height: 12),
                    TextButton(
                      onPressed: busy
                          ? null
                          : () {
                              if (validateForm()) {
                                run(
                                  () => widget.onEmail(email.text.trim()),
                                  emailLink: true,
                                );
                              }
                            },
                      child: Text(s.emailContinue),
                    ),
                    if (busy) const Center(child: CircularProgressIndicator()),
                    if (sent) Text(s.linkSent, textAlign: TextAlign.center),
                    if (failed)
                      Text(
                        s.authError,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.error,
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
