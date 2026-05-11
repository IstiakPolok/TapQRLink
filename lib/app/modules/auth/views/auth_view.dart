import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';

import '../../../../res/assets/image_assets.dart';
import '../../../../res/colors/app_color.dart';
import '../../../../widgets/custom_button.dart';
import '../../../../widgets/input_text_widget.dart';
import '../../../../widgets/show_custom_snack_bar.dart';
import '../../settings/controllers/settings_controller.dart';
import '../controllers/auth_controller.dart';
import 'forget_password_view.dart';
import 'sign_up_view.dart';

class AuthView extends GetView<AuthController> {
  const AuthView({super.key});

  @override
  Widget build(BuildContext context) {
    final SettingsController settingsController = Get.find();
    final isKeyboardOpen = MediaQuery.of(context).viewInsets.bottom != 0;
    return GestureDetector(
      onTap: () {
        FocusScope.of(context).unfocus();
      },
      child: Scaffold(
        appBar: AppBar(
          leading: Obx(
            () => IconButton(
              onPressed: () {
                Navigator.pop(Get.context!);
              },
              icon: SvgPicture.asset(
                ImageAssets.backward,
                colorFilter: ColorFilter.mode(
                  settingsController.isDarkMode.value == false
                      ? AppColor.textColor
                      : AppColor.whiteColor,
                  BlendMode.srcIn,
                ),
              ),
            ),
          ),
        ),
        body: SafeArea(
          child: Stack(
            children: [
              Positioned(
                top: 0.04.sh,
                width: 1.sw,
                child: Column(spacing: 10.h, children: []),
              ),
              AnimatedPositioned(
                duration: Duration(milliseconds: 200),
                curve: Curves.easeIn,
                top: isKeyboardOpen ? 0.h : 50.h,
                left: 0,
                right: 0,
                bottom: 0,
                child: ListView(
                  padding: EdgeInsets.symmetric(horizontal: 35.w),
                  children: [
                    SizedBox(height: 20.h),
                    Text(
                      'Login',
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
                      'Welcome back! Please sign in\nto continue.',
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
                    SizedBox(height: 20.h),
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
                      textEditingController: controller.emailController,
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
                    SizedBox(height: 17.h),
                    Text(
                      'Password:',
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
                      hintText: 'Enter your password',
                      obscureText: true,
                      textEditingController: controller.passwordController,
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
                    SizedBox(height: 16.h),
                    Row(
                      children: [
                        GestureDetector(
                          onTap: () {
                            controller.isRemembered.toggle();
                          },
                          child: Obx(
                            () => Container(
                              width: 17.w,
                              height: 17.h,
                              decoration: BoxDecoration(
                                color: controller.isRemembered.value
                                    ? AppColor.defaultColor
                                    : Colors.transparent,
                                border: Border.all(
                                  color: controller.isRemembered.value
                                      ? AppColor.defaultColor
                                      : AppColor.greyColor,
                                ),
                              ),
                              child: Center(
                                child: Icon(
                                  Icons.check,
                                  color: controller.isRemembered.value
                                      ? AppColor.whiteColor
                                      : Colors.transparent,
                                  size: 16.sp,
                                ),
                              ),
                            ),
                          ),
                        ),
                        SizedBox(width: 10.w),
                        Text(
                          'Remember me',
                          style: TextStyle(
                            color: settingsController.isDarkMode.value == false
                                ? AppColor.textColor
                                : AppColor.whiteColor,
                            fontSize: 14.sp,
                            fontFamily: 'Roboto',
                            fontWeight: FontWeight.w500,
                            letterSpacing: 0.50,
                          ),
                        ),
                        Spacer(),
                        InkWell(
                          onTap: () {
                            Get.to(
                              ForgetPasswordView(),
                              transition: Transition.rightToLeft,
                            );
                          },
                          child: Text(
                            'Forget Password?',
                            style: TextStyle(
                              color: AppColor.defaultColor,
                              fontSize: 14.sp,
                              fontFamily: 'Roboto',
                              fontWeight: FontWeight.w600,
                              decoration: TextDecoration.underline,
                              letterSpacing: 0.50,
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 50.h),
                    Obx(
                      () => CustomButton(
                        onPress: () async {
                          final email = controller.emailController.text.trim();
                          final password = controller.passwordController.text;

                          if (email.isEmpty) {
                            showCustomSnackBar(
                              title: 'Warning',
                              message: 'Email is required',
                              backgroundColor: AppColor.orangeColor,
                              isSuccess: false,
                            );
                          } else if (!GetUtils.isEmail(email)) {
                            showCustomSnackBar(
                              title: 'Warning',
                              message: 'Please enter a valid email address',
                              backgroundColor: AppColor.orangeColor,
                              isSuccess: false,
                            );
                          } else if (password.isEmpty) {
                            showCustomSnackBar(
                              title: 'Warning',
                              message: 'Password is required',
                              backgroundColor: AppColor.orangeColor,
                              isSuccess: false,
                            );
                          } else if (password.length < 6) {
                            showCustomSnackBar(
                              title: 'Warning',
                              message: 'Password must be at least 6 characters',
                              backgroundColor: AppColor.orangeColor,
                              isSuccess: false,
                            );
                          } else if (!password.contains(RegExp(r'[A-Z]'))) {
                            showCustomSnackBar(
                              title: 'Warning',
                              message: 'Password must contain at least one uppercase letter',
                              backgroundColor: AppColor.orangeColor,
                              isSuccess: false,
                            );
                          } else if (!password.contains(RegExp(r'[a-z]'))) {
                            showCustomSnackBar(
                              title: 'Warning',
                              message: 'Password must contain at least one lowercase letter',
                              backgroundColor: AppColor.orangeColor,
                              isSuccess: false,
                            );
                          } else if (!password.contains(RegExp(r'[0-9]'))) {
                            showCustomSnackBar(
                              title: 'Warning',
                              message: 'Password must contain at least one numeric character',
                              backgroundColor: AppColor.orangeColor,
                              isSuccess: false,
                            );
                          } else if (!password.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'))) {
                            showCustomSnackBar(
                              title: 'Warning',
                              message: 'Password must contain at least one special character',
                              backgroundColor: AppColor.orangeColor,
                              isSuccess: false,
                            );
                          } else {
                            await controller.login();
                          }
                        },
                        loading: controller.isLoading.value,
                        title: 'Log In',
                      ),
                    ),
                    SizedBox(height: 20.h),
                    Row(
                      spacing: 12.w,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Don’t have an account?',
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
                              SignUpView(),
                              transition: Transition.rightToLeft,
                            );
                          },
                          child: Text(
                            'Sign Up',
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
                      onTap: controller.signInWithGoogle,
                      child: Obx(
                        () => Container(
                          height: 40.h,
                          decoration: ShapeDecoration(
                            shape: RoundedRectangleBorder(
                              side: BorderSide(
                                width: 1.w,
                                color: AppColor.defaultColor,
                              ),
                              borderRadius: BorderRadius.circular(8.r),
                            ),
                          ),
                          child: controller.isSocialLoading.value
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
                      onTap: controller.signInWithGoogle,
                      child: Obx(
                        () => Container(
                          height: 40.h,
                          decoration: ShapeDecoration(
                            shape: RoundedRectangleBorder(
                              side: BorderSide(
                                width: 1.w,
                                color: AppColor.defaultColor,
                              ),
                              borderRadius: BorderRadius.circular(8.r),
                            ),
                          ),
                          child: controller.isSocialLoading.value
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
