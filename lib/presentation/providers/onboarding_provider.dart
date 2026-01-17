import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

final onboardingProvider = StateNotifierProvider<OnboardingNotifier, bool>((ref) {
  return OnboardingNotifier();
});

class OnboardingNotifier extends StateNotifier<bool> {
  OnboardingNotifier() : super(false) {
    checkOnboardingStatus();
  }

  final _storage = const FlutterSecureStorage();
  static const _keyOnboardingComplete = 'onboarding_complete';

  Future<void> checkOnboardingStatus() async {
    final value = await _storage.read(key: _keyOnboardingComplete);
    state = value == 'true';
  }

  Future<void> completeOnboarding() async {
    await _storage.write(key: _keyOnboardingComplete, value: 'true');
    state = true;
  }
}
