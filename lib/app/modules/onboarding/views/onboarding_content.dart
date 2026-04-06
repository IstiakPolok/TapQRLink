import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../../../res/colors/app_color.dart';
import '../../settings/controllers/settings_controller.dart';
import '../controllers/onboarding_controller.dart';

class OnboardingContent extends StatelessWidget {
  final SettingsController settingsController = Get.find();
  final String imagePath;
  final String title;
  final String description;

  OnboardingContent({
    super.key,
    required this.imagePath,
    required this.title,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    final OnboardingController controller = Get.find();

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        Expanded(
          child: Center(child: Image.asset(imagePath, fit: BoxFit.contain)),
        ),
        Column(
          children: [
            SizedBox(
              width: 350.w,
              child: Text(
                title,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 24.sp,
                  fontWeight: FontWeight.w900,
                  color: controller.currentPage.value == 0
                      ? AppColor.whiteColor
                      : AppColor.defaultColor,
                  fontFamily: 'Nunito Sans',
                ),
              ),
            ),
            SizedBox(height: 8.h),
            SizedBox(
              width: 247.w,
              child: Text(
                description,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: settingsController.isDarkMode.value == false
                      ? AppColor.textColor1
                      : AppColor.whiteColor,
                  fontSize: 16.sp,
                  fontFamily: 'Nunito Sans',
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
