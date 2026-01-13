import 'package:flutter/material.dart';
import 'package:pin_code_fields/pin_code_fields.dart';
import '../../core/constants/app_constants.dart';

/// Widget for OTP code input with 6 digit fields
class OtpInputField extends StatelessWidget {
  final TextEditingController controller;
  final Function(String) onCompleted;
  final Function(String)? onChanged;
  final bool hasError;
  final bool enabled;

  const OtpInputField({
    super.key,
    required this.controller,
    required this.onCompleted,
    this.onChanged,
    this.hasError = false,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return PinCodeTextField(
      appContext: context,
      length: AppConstants.otpLength,
      controller: controller,
      enabled: enabled,
      autoFocus: true,
      keyboardType: TextInputType.number,
      animationType: AnimationType.fade,
      animationDuration: const Duration(milliseconds: 200),
      enableActiveFill: true,
      onCompleted: onCompleted,
      onChanged: onChanged ?? (_) {},
      pinTheme: PinTheme(
        shape: PinCodeFieldShape.box,
        borderRadius: BorderRadius.circular(12),
        fieldHeight: 56,
        fieldWidth: 48,
        activeFillColor: hasError ? Colors.red.shade50 : Colors.white,
        inactiveFillColor: Colors.grey.shade100,
        selectedFillColor: Colors.white,
        activeColor: hasError ? Colors.red : theme.primaryColor,
        inactiveColor: Colors.grey.shade300,
        selectedColor: theme.primaryColor,
        errorBorderColor: Colors.red,
      ),
      textStyle: TextStyle(
        fontSize: 24,
        fontWeight: FontWeight.bold,
        color: hasError ? Colors.red : Colors.black87,
      ),
      cursorColor: theme.primaryColor,
    );
  }
}

/// Widget displaying countdown timer for OTP resend
class OtpResendTimer extends StatelessWidget {
  final int secondsRemaining;
  final VoidCallback onResend;
  final bool isLoading;

  const OtpResendTimer({
    super.key,
    required this.secondsRemaining,
    required this.onResend,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    final canResend = secondsRemaining == 0 && !isLoading;

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          'Vous n\'avez pas recu le code ? ',
          style: TextStyle(color: Colors.grey[600]),
        ),
        if (canResend)
          TextButton(
            onPressed: onResend,
            child: isLoading
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Renvoyer'),
          )
        else
          Text(
            'Renvoyer dans ${secondsRemaining}s',
            style: TextStyle(
              color: Theme.of(context).primaryColor,
              fontWeight: FontWeight.w500,
            ),
          ),
      ],
    );
  }
}

/// Helper function to mask email for display
String maskEmail(String email) {
  final parts = email.split('@');
  if (parts.length != 2) return email;

  final localPart = parts[0];
  final domain = parts[1];

  if (localPart.length <= 2) {
    return '${localPart[0]}***@$domain';
  }

  return '${localPart[0]}${'*' * (localPart.length - 2)}${localPart[localPart.length - 1]}@$domain';
}
