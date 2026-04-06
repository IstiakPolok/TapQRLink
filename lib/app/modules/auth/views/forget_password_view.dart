import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';

import '../../../../res/assets/image_assets.dart';
import '../../../../res/colors/app_color.dart';
import '../../../../widgets/custom_button.dart';
import '../../../../widgets/input_text_widget.dart';
import '../../settings/controllers/settings_controller.dart';
import '../controllers/auth_controller.dart';

class ForgetPasswordView extends StatelessWidget {
  final AuthController authController = Get.find();
  final SettingsController settingsController = Get.find();
  ForgetPasswordView({super.key});

  @override
  Widget build(BuildContext context) {
    final isKeyboardOpen = MediaQuery.of(context).viewInsets.bottom != 0;
    return GestureDetector(
      onTap: () {
        FocusScope.of(context).unfocus();
      },
      child: Scaffold(
        body: SafeArea(
          child: Stack(
            children: [
              Positioned(
                top: 0,
                left: 10.w,
                child: Column(
                  children: [
                    InkWell(
                      onTap: () => Navigator.pop(Get.context!),
                      child: SvgPicture.asset(
                        ImageAssets.backward,
                        colorFilter: ColorFilter.mode(
                          settingsController.isDarkMode.value == false
                              ? AppColor.textColor
                              : AppColor.whiteColor,
                          BlendMode.srcIn,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Positioned(
                top: 0.04.sh,
                width: 1.sw,
                child: Column(spacing: 10.h, children: []),
              ),
              AnimatedPositioned(
                duration: Duration(milliseconds: 200),
                curve: Curves.easeIn,
                top: isKeyboardOpen ? 80.h : 80.h,
                left: 0,
                right: 0,
                bottom: 0,
                child: ListView(
                  padding: EdgeInsets.symmetric(horizontal: 35.w),
                  children: [
                    SizedBox(height: 20.h),
                    Text(
                      'Forgot Password?',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: settingsController.isDarkMode.value == false
                            ? AppColor.textColor
                            : AppColor.whiteColor,
                        fontSize: 24.sp,
                        fontFamily: 'Nunito Sans',
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    SizedBox(height: 10.h),
                    Text(
                      'We’ll help you get back in. Just \nprovide your email address.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: settingsController.isDarkMode.value == false
                            ? AppColor.textColor1
                            : AppColor.whiteColor,
                        fontSize: 16.sp,
                        fontFamily: 'Nunito Sans',
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    SizedBox(height: 32.h),
                    Text(
                      'E-mail:',
                      style: TextStyle(
                        color: settingsController.isDarkMode.value == false
                            ? AppColor.textColor
                            : AppColor.whiteColor,
                        fontSize: 14.sp,
                        fontFamily: 'Nunito Sans',
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(height: 4.h),
                    InputTextWidget(
                      hintText: 'Enter your e-mail address',
                      textEditingController:
                          authController.forgetEmailController,
                      onChanged: (value1) => (),
                      backgroundColor:
                          settingsController.isDarkMode.value == false
                          ? AppColor.backgroundColor
                          : AppColor.darkThemeColor,
                      borderColor: settingsController.isDarkMode.value == false
                          ? AppColor.borderColor
                          : AppColor.darkThemeBorderColor,
                      textColor: settingsController.isDarkMode.value == false
                          ? AppColor.textColor
                          : AppColor.whiteColor,
                    ),
                    SizedBox(height: 30.h),
                    Obx(
                      () => CustomButton(
                        title: 'Next',
                        onPress: authController.isLoading.value
                            ? null
                            : authController.forget,
                        loading: authController.isLoading.value,
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    SizedBox(height: 20.h),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
