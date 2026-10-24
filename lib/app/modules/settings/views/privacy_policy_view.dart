import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';

import '../controllers/settings_controller.dart';
import '../../../../res/assets/image_assets.dart';
import '../../../../res/colors/app_color.dart';
import '../../../../widgets/custom_button.dart';
import '../../../../widgets/show_custom_snack_bar.dart';

class PrivacyPolicyView extends GetView<SettingsController> {
  const PrivacyPolicyView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final SettingsController settingsController = Get.find<SettingsController>();
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          onPressed: () => Navigator.pop(Get.context!),
          icon: SvgPicture.asset(
            ImageAssets.backward,
            colorFilter: ColorFilter.mode(
              settingsController.isDarkMode.value ? AppColor.whiteColor : AppColor.textColor,
              BlendMode.srcIn,
            ),
          ),
        ),
        title: Text(
          'Privacy Policy',
          style: TextStyle(
            color: settingsController.isDarkMode.value ? AppColor.whiteColor : AppColor.textColor,
            fontSize: 20.sp,
            fontFamily: 'Nunito Sans',
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: settingsController.isDarkMode.value ? AppColor.darkThemeColor : AppColor.containerColor,
        elevation: 0,
      ),
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 20.h),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Your privacy is important to us. This privacy policy explains how we collect, use, and protect your information.',
                  style: TextStyle(
                    color: settingsController.isDarkMode.value ? AppColor.whiteColor : AppColor.textColor,
                    fontSize: 14.sp,
                    fontFamily: 'Nunito Sans',
                    height: 1.5,
                  ),
                ),
                SizedBox(height: 20.h),
                Text(
                  'Data Collection',
                  style: TextStyle(
                    color: settingsController.isDarkMode.value ? AppColor.whiteColor : AppColor.textColor1,
                    fontSize: 16.sp,
                    fontFamily: 'Nunito Sans',
                    fontWeight: FontWeight.w700,
                  ),
                ),
                SizedBox(height: 8.h),
                Text(
                  'We may collect personal data such as email, device identifiers, and usage statistics to improve the app experience.',
                  style: TextStyle(
                    color: settingsController.isDarkMode.value ? AppColor.whiteColor : AppColor.textColor,
                    fontSize: 14.sp,
                    fontFamily: 'Nunito Sans',
                    height: 1.5,
                  ),
                ),
                SizedBox(height: 20.h),
                Text(
                  'Data Usage',
                  style: TextStyle(
                    color: settingsController.isDarkMode.value ? AppColor.whiteColor : AppColor.textColor1,
                    fontSize: 16.sp,
                    fontFamily: 'Nunito Sans',
                    fontWeight: FontWeight.w700,
                  ),
                ),
                SizedBox(height: 8.h),
                Text(
                  'Collected data is used solely for providing and enhancing the service, and is never sold to third parties.',
                  style: TextStyle(
                    color: settingsController.isDarkMode.value ? AppColor.whiteColor : AppColor.textColor,
                    fontSize: 14.sp,
                    fontFamily: 'Nunito Sans',
                    height: 1.5,
                  ),
                ),
                SizedBox(height: 30.h),
                Center(
                  child: CustomButton(
                    onPress: () async => Navigator.pop(Get.context!),
                    title: 'Back',
                    height: 40,
                    width: 120,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
