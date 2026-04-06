import 'package:dots_indicator/dots_indicator.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:get/get.dart';

import '../../../../res/colors/app_color.dart';
import '../../../../widgets/custom_button.dart';
import '../../../routes/app_pages.dart';
import '../../settings/controllers/settings_controller.dart';
import '../controllers/onboarding_controller.dart';
import 'onboarding_content.dart';

class OnboardingView extends StatelessWidget {
  const OnboardingView({super.key});

  @override
  Widget build(BuildContext context) {
    final SettingsController settingsController = Get.find();
    final OnboardingController controller = Get.find();
    final FlutterSecureStorage storage = const FlutterSecureStorage();

    final List<Map<String, dynamic>> onboardingData = [
      {
        "image": "assets/images/splash/splash.png",
        "title":
            "TapQRLink - Instantly \nScan or open any QR code by tapping your finger",
        "description": "",
      },
      {
        "image": settingsController.isDarkMode.value == false
            ? "assets/images/splash/img.png"
            : "assets/images/splash/img_2.png",
        "title": "One Tap to Open Links",
        "description": "Use your camera or choose an image from your gallery",
      },
      {
        "image": settingsController.isDarkMode.value == false
            ? "assets/images/splash/img_1.png"
            : "assets/images/splash/img_3.png",
        "title": "Fast and Easy QR Scanning",
        "description":
            "Scan any QR code in seconds and access your content instantly",
      },
    ];

    final PageController pageController = PageController();

    return Scaffold(
      body: Obx(() {
        return Container(
          color: controller.currentPage.value == 0
              ? AppColor.backgroundColor1
              : settingsController.isDarkMode.value == false
              ? AppColor.whiteColor
              : AppColor.darkThemeColor,
          child: SafeArea(
            child: Column(
              children: <Widget>[
                Expanded(
                  child: PageView.builder(
                    controller: pageController,
                    onPageChanged: (int page) {
                      controller.currentPage.value = page;
                    },
                    itemCount: onboardingData.length,
                    itemBuilder: (context, index) => OnboardingContent(
                      imagePath: onboardingData[index]['image']!,
                      title: onboardingData[index]['title']!,
                      description: onboardingData[index]['description']!,
                    ),
                  ),
                ),
                Padding(
                  padding: EdgeInsets.only(top: 20.h),
                  child: Obx(
                    () => DotsIndicator(
                      dotsCount: onboardingData.length,
                      position: controller.currentPage.value.toDouble(),
                      decorator: DotsDecorator(
                        color: controller.currentPage.value == 0
                            ? AppColor.whiteColor
                            : AppColor.inactiveColor,
                        activeColor: controller.currentPage.value == 0
                            ? AppColor.whiteColor
                            : AppColor.inactiveColor,
                        size: Size.square(10.sp),
                        activeSize: Size(40.sp, 10.sp),
                        activeShape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(5.r),
                        ),
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: EdgeInsets.only(
                    bottom: 105.h,
                    left: controller.currentPage.value == 2 ? 210 : 270.w,
                    top: 70.h,
                  ),
                  child: Obx(
                    () => InkWell(
                      onTap: () {
                        storage.write(key: 'onboarding', value: 'true');
                        Get.toNamed(Routes.home);
                      },
                      child: controller.currentPage.value == 2
                          ? CustomButton(
                              onPress: () async {
                                storage.write(key: 'onboarding', value: 'true');
                                Get.toNamed(Routes.home);
                              },
                              title: 'Get Started',
                              width: 143,
                              height: 38,
                            )
                          : SizedBox(
                              height: 38.h,
                              child: Text(
                                'Skip',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: controller.currentPage.value == 0
                                      ? AppColor.whiteColor
                                      : AppColor.backgroundColor1,
                                  fontSize: 24.sp,
                                  fontFamily: 'Nunito Sans',
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      }),
    );
  }
}
