import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/app_router.dart';
import '../../../core/utils/validators.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/auth_widgets.dart';

/// Page for requesting a password reset email
class ForgotPasswordPage extends ConsumerStatefulWidget {
  const ForgotPasswordPage({super.key});

  @override
  ConsumerState<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends ConsumerState<ForgotPasswordPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  bool _emailSent = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _handleResetRequest() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    // Clear any previous error
    ref.read(authProvider.notifier).clearError();

    await ref.read(authProvider.notifier).resetPasswordForEmail(
          email: _emailController.text.trim(),
        );

    // Check if widget is still mounted before using ref/setState
    if (!mounted) return;

    // Check if request was successful (no error)
    final error = ref.read(authProvider).value?.error;
    if (error == null) {
      // Redirect to OTP verification page
      final email = Uri.encodeComponent(_emailController.text.trim());
      context.go('${AppRoutes.otpVerification}?email=$email&type=recovery');
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final isLoading = authState.value?.isLoading ?? false;
    final error = authState.value?.error;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go(AppRoutes.login),
        ),
        title: const Text('Mot de passe oublie'),
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 400),
              child: _emailSent
                  ? _buildSuccessContent()
                  : _buildFormContent(isLoading, error),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFormContent(bool isLoading, dynamic error) {
    return Form(
      key: _formKey,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Icon and title
          const Icon(
            Icons.lock_reset,
            size: 80,
            color: Colors.grey,
          ),
          const SizedBox(height: 24),
          Text(
            'Reinitialiser votre mot de passe',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'Entrez votre adresse email et nous vous enverrons un lien pour reinitialiser votre mot de passe.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.grey[600],
                ),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: 32),

          // Error display
          if (error != null) ...[
            ErrorDisplay(message: error.messageFr),
            const SizedBox(height: 16),
          ],

          // Email field
          TextFormField(
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.done,
            autocorrect: false,
            enabled: !isLoading,
            onFieldSubmitted: (_) => _handleResetRequest(),
            decoration: const InputDecoration(
              labelText: 'Email',
              hintText: 'exemple@email.com',
              prefixIcon: Icon(Icons.email_outlined),
            ),
            validator: Validators.validateEmail,
          ),

          const SizedBox(height: 24),

          // Submit button
          AuthButton(
            label: 'Envoyer le lien',
            isLoading: isLoading,
            onPressed: _handleResetRequest,
          ),

          const SizedBox(height: 16),

          // Back to login
          TextButton(
            onPressed: isLoading ? null : () => context.go(AppRoutes.login),
            child: const Text('Retour a la connexion'),
          ),
        ],
      ),
    );
  }

  Widget _buildSuccessContent() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(
          Icons.mark_email_read_outlined,
          size: 80,
          color: Colors.green,
        ),
        const SizedBox(height: 24),
        Text(
          'Email envoye!',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Text(
          'Un email de reinitialisation a ete envoye a ${_emailController.text}. Verifiez votre boite de reception et suivez les instructions.',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.grey[600],
              ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Text(
          'Le lien expirera dans 1 heure.',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Colors.grey[500],
              ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 32),
        ElevatedButton(
          onPressed: () => context.go(AppRoutes.login),
          child: const Text('Retour a la connexion'),
        ),
        const SizedBox(height: 16),
        TextButton(
          onPressed: () {
            setState(() {
              _emailSent = false;
            });
          },
          child: const Text('Renvoyer l\'email'),
        ),
      ],
    );
  }
}
