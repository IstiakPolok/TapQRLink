import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';
import 'package:qr_code/app/modules/auth/views/auth_view.dart';

import '../../../../res/assets/image_assets.dart';
import '../../../../res/colors/app_color.dart';
import '../../../../widgets/custom_button.dart';
import '../../../../widgets/input_text_widget.dart';
import '../../home/views/nav_bar.dart';
import '../../settings/controllers/settings_controller.dart';
import '../controllers/auth_controller.dart';

class SignUpView extends GetView<AuthController> {
  const SignUpView({super.key});

  @override
  Widget build(BuildContext context) {
    final SettingsController settingsController = Get.find();
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
                      onTap: () {
                        Get.offAll(Navbar());
                      },
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
                top: isKeyboardOpen ? 0.h : 20.h,
                left: 0,
                right: 0,
                bottom: 0,
                child: ListView(
                  padding: EdgeInsets.symmetric(horizontal: 35.w),
                  children: [
                    SizedBox(height: 20.h),
                    Text(
                      'Create Account',
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
                      'Sign Up to Unlock Premium Features',
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
                      'First Name:',
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
                      textEditingController: controller.firstNameController,
                      hintText: 'Enter your first name',
                      onChanged: (value) => (),
                      keyboardType: TextInputType.name,
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
                    SizedBox(height: 12.h),
                    Text(
                      'Last Name:',
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
                      hintText: 'Enter your last name',
                      textEditingController: controller.lastNameController,
                      onChanged: (value) => (),
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
                    SizedBox(height: 12.h),
                    Text(
                      'Email:',
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
                      textEditingController: controller.signupEmailController,
                      onChanged: (value) => (),
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
                    SizedBox(height: 37.h),
                    Obx(
                      () => CustomButton(
                        onPress: controller.isLoading.value
                            ? null
                            : () async {
                                await controller.signup();
                              },
                        loading: controller.isLoading.value,
                        title: 'Next',
                      ),
                    ),
                    SizedBox(height: 20.h),
                    Row(
                      spacing: 12.w,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'If you already have an account?',
                          style: TextStyle(
                            color: settingsController.isDarkMode.value == false
                                ? AppColor.textColor1
                                : AppColor.whiteColor,
                            fontSize: 16.sp,
                            fontFamily: 'Nunito Sans',
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        GestureDetector(
                          onTap: () {
                            Get.to(
                              AuthView(),
                              transition: Transition.rightToLeft,
                            );
                          },
                          child: Text(
                            'Sign In',
                            style: TextStyle(
                              color: AppColor.defaultColor,
                              fontSize: 16.sp,
                              fontFamily: 'Nunito Sans',
                              fontWeight: FontWeight.w600,
                              decorationColor: AppColor.defaultColor,
                              decoration: TextDecoration.underline,
                              letterSpacing: 0.70,
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 20.h),
                    Row(
                      children: [
                        Expanded(
                          child: Divider(
                            thickness: 1.h,
                            color: settingsController.isDarkMode.value == false
                                ? AppColor.textColor2
                                : AppColor.whiteColor,
                          ),
                        ),
                        SizedBox(
                          width: 30.w,
                          child: Center(
                            child: Text(
                              'Or',
                              style: TextStyle(
                                color:
                                    settingsController.isDarkMode.value == false
                                    ? AppColor.textColor2
                                    : AppColor.whiteColor,
                                fontSize: 16.sp,
                                fontFamily: 'Nunito Sans',
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ),
                        Expanded(
                          child: Divider(
                            thickness: 1.h,
                            color: settingsController.isDarkMode.value == false
                                ? AppColor.textColor2
                                : AppColor.whiteColor,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 20.h),
                    GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () {
                        if (!controller.isGoogleLoading.value &&
                            !controller.isSocialLoading.value) {
                          controller.signInWithGoogle();
                        }
                      },
                      child: Obx(
                        () => Container(
                          height: 40.h,
                          decoration: ShapeDecoration(
                            color: settingsController.isDarkMode.value
                                ? AppColor.darkThemeColor
                                : AppColor.whiteColor,
                            shape: RoundedRectangleBorder(
                              side: BorderSide(
                                width: 1.w,
                                color: AppColor.defaultColor,
                              ),
                              borderRadius: BorderRadius.circular(8.r),
                            ),
                          ),
                          child: controller.isGoogleLoading.value
                              ? SizedBox(
                                  width: 20.sp,
                                  height: 20.sp,
                                  child: Center(
                                    child: CircularProgressIndicator(
                                      color: AppColor.defaultColor,
                                    ),
                                  ),
                                )
                              : Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  spacing: 10.w,
                                  children: [
                                    SvgPicture.asset(
                                      ImageAssets.ggl,
                                      width: 16.w,
                                      height: 16.h,
                                    ),
                                    Text(
                                      'Log In With Google',
                                      style: TextStyle(
                                        color: AppColor.defaultColor,
                                        fontSize: 14.sp,
                                        fontFamily: 'Nunito Sans',
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                        ),
                      ),
                    ),
                    SizedBox(height: 20.h),
                    GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () {
                        if (!controller.isAppleLoading.value &&
                            !controller.isSocialLoading.value) {
                          controller.signInWithApple();
                        }
                      },
                      child: Obx(
                        () => Container(
                          height: 40.h,
                          decoration: ShapeDecoration(
                            color: settingsController.isDarkMode.value
                                ? AppColor.darkThemeColor
                                : AppColor.whiteColor,
                            shape: RoundedRectangleBorder(
                              side: BorderSide(
                                width: 1.w,
                                color: AppColor.defaultColor,
                              ),
                              borderRadius: BorderRadius.circular(8.r),
                            ),
                          ),
                          child: controller.isAppleLoading.value
                              ? SizedBox(
                                  width: 20.sp,
                                  height: 20.sp,
                                  child: Center(
                                    child: CircularProgressIndicator(
                                      color: AppColor.defaultColor,
                                    ),
                                  ),
                                )
                              : Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  spacing: 10.w,
                                  children: [
                                    SvgPicture.asset(
                                      ImageAssets.apple,
                                      width: 24.w,
                                      height: 24.h,
                                      colorFilter: ColorFilter.mode(
                                        settingsController.isDarkMode.value ==
                                                false
                                            ? AppColor.blackColor
                                            : AppColor.whiteColor,
                                        BlendMode.srcIn,
                                      ),
                                    ),
                                    Text(
                                      'Log In With Apple ID',
                                      style: TextStyle(
                                        color: AppColor.defaultColor,
                                        fontSize: 14.sp,
                                        fontFamily: 'Nunito Sans',
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                        ),
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
