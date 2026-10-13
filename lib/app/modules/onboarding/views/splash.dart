import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../../../res/assets/image_assets.dart';
import '../../../../res/colors/app_color.dart';
import '../../../../widgets/show_custom_snack_bar.dart';
import '../../auth/controllers/auth_controller.dart';
import '../../home/views/nav_bar.dart';
import '../controllers/onboarding_controller.dart';
import 'onboarding_view.dart';

class SplashView extends GetView<AuthController> {
  const SplashView({super.key});

  @override
  Widget build(BuildContext context) {
    Get.find<OnboardingController>().getCheck();
    debugPrint('SplashView: build called, starting 3-second delay...');
    Future.delayed(const Duration(seconds: 3), () {
      try {
        final isLoggedInVal = controller.isLoggedIn.value;
        final isSignedInVal = controller.isSignedIn.value;
        final isSkipVal = Get.find<OnboardingController>().isSkip;
        
        debugPrint('SplashView: 3s delay completed. Flags - isLoggedIn: $isLoggedInVal, isSignedIn: $isSignedInVal, isSkip: $isSkipVal');
        
        if (isLoggedInVal || isSignedInVal || isSkipVal) {
          debugPrint('SplashView: Navigating to Navbar...');
          Get.off(() => Navbar());
        } else {
          debugPrint('SplashView: Navigating to OnboardingView...');
          Get.off(() => OnboardingView());
        }
      } catch (e, stack) {
        debugPrint('SplashView: Navigation error: $e\n$stack');
        showCustomSnackBar(
          title: 'Navigation Error',
          message: 'Failed to navigate to Home screen: $e',
          isSuccess: false,
        );
      }
    });
    return Scaffold(
      backgroundColor: AppColor.defaultColor,
      body: Center(
        child: Image.asset(ImageAssets.splash, width: 190.w, height: 180.h),
      ),
    );
  }
}
