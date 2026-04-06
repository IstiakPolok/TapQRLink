import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:get/get.dart';

class OnboardingController extends GetxController {
  final storage = const FlutterSecureStorage();
  var currentPage = 0.obs;
  var isLoading = false.obs;
  bool isSkip = false;
  Future<void> getCheck() async {
    final onboarding = await storage.read(key: 'onboarding');
    if (onboarding.toString() == 'true') {
      isSkip = true;
    }
  }
}
