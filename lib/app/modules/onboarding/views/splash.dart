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
    Future.delayed(const Duration(seconds: 3), () {
      try {
        controller.isLoggedIn.value ||
                controller.isSignedIn.value ||
                Get.find<OnboardingController>().isSkip
            ? Get.off(() => Navbar())
            : Get.off(() => OnboardingView());
      } catch (e) {
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
