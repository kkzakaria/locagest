import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/router/app_router.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/auth_widgets.dart';
import '../../widgets/otp_input_field.dart';

/// Page for OTP verification
/// Used for signup confirmation, password recovery, and email change
class OtpVerificationPage extends ConsumerStatefulWidget {
  final String email;
  final String otpType; // 'signup', 'recovery', 'email_change'
  final String? redirectTo;

  const OtpVerificationPage({
    super.key,
    required this.email,
    required this.otpType,
    this.redirectTo,
  });

  @override
  ConsumerState<OtpVerificationPage> createState() => _OtpVerificationPageState();
}

class _OtpVerificationPageState extends ConsumerState<OtpVerificationPage> {
  final _otpController = TextEditingController();
  Timer? _resendTimer;
  int _resendCountdown = AppConstants.otpResendDelaySeconds;
  bool _hasError = false;
  bool _isVerifying = false;
  bool _isResending = false;

  @override
  void initState() {
    super.initState();
    _startResendTimer();
  }

  @override
  void dispose() {
    _otpController.dispose();
    _resendTimer?.cancel();
    super.dispose();
  }

  void _startResendTimer() {
    _resendCountdown = AppConstants.otpResendDelaySeconds;
    _resendTimer?.cancel();
    _resendTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_resendCountdown > 0) {
        setState(() {
          _resendCountdown--;
        });
      } else {
        timer.cancel();
      }
    });
  }

  Future<void> _verifyOtp(String code) async {
    if (_isVerifying) return;

    setState(() {
      _isVerifying = true;
      _hasError = false;
    });

    ref.read(authProvider.notifier).clearError();

    final user = await ref.read(authProvider.notifier).verifyOtp(
          type: widget.otpType,
          email: widget.email,
          token: code,
        );

    if (!mounted) return;

    final error = ref.read(authProvider).value?.error;

    if (error != null) {
      setState(() {
        _isVerifying = false;
        _hasError = true;
        _otpController.clear();
      });
      return;
    }

    setState(() {
      _isVerifying = false;
    });

    // Navigate based on OTP type
    _handleSuccessNavigation(user != null);
  }

  void _handleSuccessNavigation(bool hasUser) {
    switch (widget.otpType) {
      case 'signup':
        // Signup verified, go to dashboard
        context.go(AppRoutes.dashboard);
        break;
      case 'recovery':
        // Recovery verified, go to reset password page
        context.go(AppRoutes.resetPassword);
        break;
      case 'email_change':
        // Email change verified, go back or to specified redirect
        if (widget.redirectTo != null) {
          context.go(widget.redirectTo!);
        } else {
          context.go(AppRoutes.profile);
        }
        break;
      default:
        context.go(AppRoutes.dashboard);
    }
  }

  Future<void> _resendOtp() async {
    if (_resendCountdown > 0 || _isResending) return;

    setState(() {
      _isResending = true;
      _hasError = false;
    });

    ref.read(authProvider.notifier).clearError();

    final success = await ref.read(authProvider.notifier).resendOtp(
          type: widget.otpType,
          email: widget.email,
        );

    if (!mounted) return;

    setState(() {
      _isResending = false;
    });

    if (success) {
      _startResendTimer();
      _showSnackBar('Un nouveau code a ete envoye');
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  String get _pageTitle {
    switch (widget.otpType) {
      case 'signup':
        return 'Verification de l\'email';
      case 'recovery':
        return 'Reinitialisation';
      case 'email_change':
        return 'Changement d\'email';
      default:
        return 'Verification';
    }
  }

  String get _pageSubtitle {
    switch (widget.otpType) {
      case 'signup':
        return 'Entrez le code a 6 chiffres envoye a votre adresse email pour activer votre compte.';
      case 'recovery':
        return 'Entrez le code a 6 chiffres envoye a votre adresse email pour reinitialiser votre mot de passe.';
      case 'email_change':
        return 'Entrez le code a 6 chiffres envoye a votre nouvelle adresse email pour confirmer le changement.';
      default:
        return 'Entrez le code de verification.';
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final error = authState.value?.error;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            if (widget.otpType == 'signup') {
              context.go(AppRoutes.register);
            } else if (widget.otpType == 'recovery') {
              context.go(AppRoutes.forgotPassword);
            } else {
              context.pop();
            }
          },
        ),
        title: Text(_pageTitle),
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 400),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Icon
                  Icon(
                    Icons.email_outlined,
                    size: 80,
                    color: Theme.of(context).primaryColor,
                  ),
                  const SizedBox(height: 24),

                  // Title
                  Text(
                    _pageTitle,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),

                  // Subtitle
                  Text(
                    _pageSubtitle,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.grey[600],
                        ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),

                  // Email display (masked)
                  Text(
                    maskEmail(widget.email),
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: Theme.of(context).primaryColor,
                        ),
                    textAlign: TextAlign.center,
                  ),

                  const SizedBox(height: 32),

                  // Error display
                  if (error != null) ...[
                    ErrorDisplay(message: error.messageFr),
                    const SizedBox(height: 16),
                  ],

                  // OTP input
                  OtpInputField(
                    controller: _otpController,
                    onCompleted: _verifyOtp,
                    onChanged: (_) {
                      if (_hasError) {
                        setState(() {
                          _hasError = false;
                        });
                        ref.read(authProvider.notifier).clearError();
                      }
                    },
                    hasError: _hasError,
                    enabled: !_isVerifying,
                  ),

                  const SizedBox(height: 24),

                  // Verify button
                  AuthButton(
                    label: 'Verifier',
                    isLoading: _isVerifying,
                    onPressed: _otpController.text.length == AppConstants.otpLength
                        ? () => _verifyOtp(_otpController.text)
                        : null,
                  ),

                  const SizedBox(height: 24),

                  // Resend timer
                  OtpResendTimer(
                    secondsRemaining: _resendCountdown,
                    onResend: _resendOtp,
                    isLoading: _isResending,
                  ),

                  const SizedBox(height: 16),

                  // Help text
                  Text(
                    'Le code expire dans ${AppConstants.otpExpiryMinutes} minutes',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.grey[500],
                        ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
