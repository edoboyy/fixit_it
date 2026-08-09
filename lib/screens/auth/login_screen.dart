import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_constants.dart';
import '../../core/utils/helpers.dart';
import '../../core/utils/validators.dart';
import '../../models/user_model.dart';
import '../../core/utils/post_login_navigation.dart';
import '../../providers/auth_provider.dart';
import '../../routes/app_routes.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_text_field.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key, this.initialRole});

  final UserRole? initialRole;

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _identifierController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void dispose() {
    _identifierController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  String get _roleLabel {
    return switch (widget.initialRole) {
      UserRole.artisan => 'Artisan',
      UserRole.admin => 'Admin',
      UserRole.customer => 'Customer',
      null => 'Fixit GH',
    };
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    final authProvider = context.read<AuthProvider>();
    authProvider.clearError();

    final success = await authProvider.login(
      emailOrUsername: _identifierController.text.trim(),
      password: _passwordController.text,
      expectedRole: widget.initialRole,
    );

    if (!mounted) return;

    // Clear autofill context so credentials are not re-applied later.
    TextInput.finishAutofillContext(shouldSave: false);

    if (success) {
      _passwordController.clear();
      await navigateAfterAuth(context);
    } else if (authProvider.errorMessage != null) {
      Helpers.showSnackBar(context, authProvider.errorMessage!, isError: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final theme = Theme.of(context);
    final canRegister = widget.initialRole != UserRole.admin;

    return Scaffold(
      appBar: AppBar(
        title: Text('$_roleLabel sign in'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pushReplacementNamed(context, AppRoutes.welcome);
          },
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: AutofillGroup(
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 8),
                  Icon(
                    switch (widget.initialRole) {
                      UserRole.artisan => Icons.handyman_rounded,
                      UserRole.admin => Icons.admin_panel_settings_rounded,
                      _ => Icons.person_rounded,
                    },
                    size: 56,
                    color: AppConstants.primaryGreen,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Welcome back',
                    style: theme.textTheme.headlineMedium,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Sign in with your email or username',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: Colors.grey.shade600,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 32),
                  CustomTextField(
                    label: 'Email or Username',
                    hint: 'Email address or your full name',
                    controller: _identifierController,
                    keyboardType: TextInputType.text,
                    textInputAction: TextInputAction.next,
                    prefixIcon: Icons.person_outline,
                    autofillHints: const [],
                    enableSuggestions: false,
                    autocorrect: false,
                    validator: Validators.emailOrUsername,
                  ),
                  const SizedBox(height: 16),
                  CustomTextField(
                    label: 'Password',
                    hint: 'Enter your password',
                    controller: _passwordController,
                    obscureText: true,
                    textInputAction: TextInputAction.done,
                    prefixIcon: Icons.lock_outline,
                    autofillHints: const [],
                    validator: Validators.password,
                    onSubmitted: (_) => _handleLogin(),
                  ),
                  const SizedBox(height: 8),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: () {
                        Navigator.pushNamed(context, AppRoutes.forgotPassword);
                      },
                      child: const Text('Forgot password?'),
                    ),
                  ),
                  const SizedBox(height: 24),
                  CustomButton(
                    label: 'Sign In',
                    icon: Icons.login,
                    isLoading: authProvider.isLoading,
                    onPressed: _handleLogin,
                  ),
                  if (canRegister) ...[
                    const SizedBox(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          "Don't have an account?",
                          style: theme.textTheme.bodyMedium,
                        ),
                        TextButton(
                          onPressed: () {
                            Navigator.pushReplacementNamed(
                              context,
                              AppRoutes.register,
                              arguments:
                                  widget.initialRole ?? UserRole.customer,
                            );
                          },
                          child: const Text('Register'),
                        ),
                      ],
                    ),
                  ] else ...[
                    const SizedBox(height: 16),
                    Text(
                      'Admin accounts are provisioned by the system.',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
