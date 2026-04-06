import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';
import 'package:pin_code_fields/pin_code_fields.dart';

import '../../../../res/assets/image_assets.dart';
import '../../../../res/colors/app_color.dart';
import '../../../../widgets/custom_button.dart';
import '../../settings/controllers/settings_controller.dart';
import '../controllers/auth_controller.dart';

class OtpVerifyView extends StatefulWidget {
  const OtpVerifyView({super.key});

  @override
  State<OtpVerifyView> createState() => _OtpVerifyViewState();
}

class _OtpVerifyViewState extends State<OtpVerifyView> {
  final AuthController authController = Get.find<AuthController>();
  final SettingsController settingsController = Get.find();
  final RxInt secondsRemaining = 60.obs;
  final RxString formattedTime = '01:00'.obs;
  Timer? timer;
  final FocusNode _pinFocusNode = FocusNode();
  final TextEditingController _otpController = TextEditingController();

  @override
  void initState() {
    super.initState();
    startTimer();
    _otpController.clear();
  }

  @override
  void dispose() {
    _pinFocusNode.unfocus();
    timer?.cancel();
    _pinFocusNode.dispose();
    _otpController.dispose();
    super.dispose();
  }

  void startTimer() {
    secondsRemaining.value = 60;
    timer?.cancel();
    timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (secondsRemaining.value > 0 && mounted) {
        secondsRemaining.value--;
        final minutes = (secondsRemaining.value ~/ 60).toString().padLeft(
          2,
          '0',
        );
        final seconds = (secondsRemaining.value % 60).toString().padLeft(
          2,
          '0',
        );
        formattedTime.value = '$minutes:$seconds';
      } else {
        t.cancel();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final String? origin = Get.arguments?['origin'] as String?;
    debugPrint("you are from $origin");
    RxString email = ''.obs;
    origin == 'Signup'
        ? email = authController.signupEmail
        : email = authController.forgetEmail;
    return Scaffold(
      appBar: AppBar(
        leading: Obx(
          () => IconButton(
            onPressed: () => Navigator.pop(Get.context!),
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
      body: SingleChildScrollView(
        child: GestureDetector(
          onTap: () => FocusScope.of(context).unfocus(),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 20.w),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    SizedBox(height: 70.h),
                    Obx(
                      () => Text(
                        'Verify OTP',
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
                    ),
                    SizedBox(height: 8.h),
                    SizedBox(
                      width: 274.w,
                      child: Obx(
                        () => Text(
                          'We’ll help you get back in. Just provide your email address.',
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
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 18.h),
              Obx(
                () => Text(
                  'We have sent 4 digit OTP code at \n $email',
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
              ),
              SizedBox(height: 20.h),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 60.w),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Obx(
                    () => Text(
                      'Enter OTP',
                      style: TextStyle(
                        color: settingsController.isDarkMode.value == false
                            ? AppColor.textColor
                            : AppColor.whiteColor,
                        fontSize: 14.sp,
                        fontFamily: 'Nunito Sans',
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ),
              SizedBox(height: 14.h),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 60.w),
                child: SizedBox(
                  height: 56.h,
                  width: double.infinity,
                  child: PinCodeTextField(
                    appContext: context,
                    length: 4,
                    textStyle: TextStyle(
                      color: AppColor.defaultColor,
                      fontSize: 24.sp,
                      fontFamily: 'Nunito Sans',
                      fontWeight: FontWeight.w800,
                      height: 1.40,
                      letterSpacing: 0.24,
                    ),
                    animationType: AnimationType.fade,
                    cursorColor: settingsController.isDarkMode.value == false
                        ? AppColor.textColor
                        : AppColor.whiteColor,
                    pinTheme: PinTheme(
                      shape: PinCodeFieldShape.box,
                      fieldHeight: 48.5.h,
                      fieldWidth: 48.5.w,
                      activeColor: settingsController.isDarkMode.value == false
                          ? AppColor.borderColor
                          : AppColor.darkThemeBorderColor,
                      selectedColor: AppColor.defaultColor,
                      inactiveColor:
                          settingsController.isDarkMode.value == false
                          ? AppColor.borderColor
                          : AppColor.darkThemeBorderColor,
                      activeFillColor:
                          settingsController.isDarkMode.value == false
                          ? AppColor.backgroundColor
                          : AppColor.darkThemeColor,
                      selectedFillColor:
                          settingsController.isDarkMode.value == false
                          ? AppColor.backgroundColor
                          : AppColor.darkThemeColor,
                      inactiveFillColor:
                          settingsController.isDarkMode.value == false
                          ? AppColor.backgroundColor
                          : AppColor.darkThemeColor,
                      borderRadius: BorderRadius.circular(10.r),
                    ),
                    animationDuration: const Duration(milliseconds: 300),
                    enableActiveFill: true,
                    keyboardType: TextInputType.number,
                    controller: _otpController,
                    focusNode: _pinFocusNode,
                    onChanged: (value) =>
                        authController.otpController.text = value,
                    onCompleted: (value) async {
                      authController.updateOtp(value);
                    },
                  ),
                ),
              ),
              SizedBox(height: 10.h),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Obx(
                    () => Text(
                      'Don’t get the code? ',
                      style: TextStyle(
                        color: settingsController.isDarkMode.value == false
                            ? AppColor.textColor2
                            : AppColor.whiteColor,
                        fontSize: 16.sp,
                        fontFamily: 'Nunito Sans',
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ),
                  Obx(
                    () => InkWell(
                      onTap: secondsRemaining.value == 0
                          ? () {
                              origin == 'Signup'
                                  ? authController.resendOtp()
                                  : authController.resendForgetOtp();
                              startTimer();
                            }
                          : null,
                      child: Obx(
                        () => Text(
                          'Resend',
                          style: TextStyle(
                            color: secondsRemaining.value == 0
                                ? AppColor.defaultColor
                                : settingsController.isDarkMode.value == false
                                ? AppColor.textColor
                                : AppColor.whiteColor,
                            fontWeight: secondsRemaining.value == 0
                                ? FontWeight.bold
                                : FontWeight.w600,
                            fontSize: 16.sp,
                            fontFamily: 'Nunito Sans',
                            letterSpacing: 0.60,
                          ),
                          semanticsLabel: 'resend_button'.tr,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 5.h),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Resend available in',
                    style: TextStyle(
                      color: AppColor.defaultColor,
                      fontSize: 16.sp,
                      fontFamily: 'Nunito Sans',
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.60,
                    ),
                  ),
                  SizedBox(width: 5.w),
                  SizedBox(
                    width: 50.w,
                    child: Obx(
                      () => Text(
                        formattedTime.value,
                        style: TextStyle(
                          color: AppColor.defaultColor,
                          fontSize: 15.sp,
                          fontFamily: 'Nunito Sans',
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.60,
                        ),
                        textAlign: TextAlign.center,
                        semanticsLabel: 'timer'.trParams({
                          'time': formattedTime.value,
                        }),
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 35.h),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 20.w),
                child: Obx(
                  () => CustomButton(
                    onPress: authController.isLoading.value
                        ? null
                        : () async {
                            origin == 'Signup'
                                ? await authController.verifyOtp()
                                : await authController.verifyOtpPassword();
                          },
                    loading: authController.isLoading.value,
                    title: 'Verify Email',
                  ),
                ),
              ),
              SizedBox(height: 20.h),
            ],
          ),
        ),
      ),
    );
  }
}
