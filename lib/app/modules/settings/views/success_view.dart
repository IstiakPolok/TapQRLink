import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../../../res/assets/image_assets.dart';
import '../../../../res/colors/app_color.dart';
import '../../../../widgets/custom_button.dart';
import '../../home/views/nav_bar.dart';
import '../controllers/settings_controller.dart';

class SuccessView extends GetView<SettingsController> {
  const SuccessView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: EdgeInsets.all(30.sp),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Center(
              child: Image.asset(ImageAssets.img2, width: 260.w, height: 367.h),
            ),
            SizedBox(height: 25.h),
            Text(
              'Payment Successful!',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColor.defaultColor,
                fontSize: 24.sp,
                fontFamily: 'Nunito Sans',
                fontWeight: FontWeight.w700,
              ),
            ),
            SizedBox(height: 8.h),
            SizedBox(
              width: 272.w,
              child: Text(
                'Premium features are now unlocked — enjoy the enhanced TapQRLink experience.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppColor.textColor2,
                  fontSize: 18.sp,
                  fontFamily: 'Nunito Sans',
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            SizedBox(height: 25.h),
            CustomButton(
              onPress: () async {
                {
                  Get.to(Navbar());
                }
              },
              title: 'Continue',
            ),
            SizedBox(height: 20.h),
          ],
        ),
      ),
    );
  }
}
