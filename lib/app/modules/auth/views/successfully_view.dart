import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../../../res/assets/image_assets.dart';
import '../../../../res/colors/app_color.dart';
import '../../../../widgets/custom_button.dart';
import '../../home/views/nav_bar.dart';

class SuccessfullyView extends GetView {
  const SuccessfullyView({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 55.w, vertical: 40.h),
              child: Column(
                spacing: 24.h,
                children: [
                  Container(
                    width: double.infinity,
                    height: 388.w,
                    decoration: BoxDecoration(
                      image: DecorationImage(
                        image: AssetImage(ImageAssets.success),
                        fit: BoxFit.fill,
                      ),
                    ),
                  ),
                  SizedBox(
                    width: 264.w,
                    child: Text(
                      'Congratulations! You have successfully signed up',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: AppColor.defaultColor,
                        fontSize: 24.sp,
                        fontFamily: 'Nunito Sans',
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 20.w),
              child: CustomButton(
                onPress: () async {
                  Get.offAll(() => Navbar());
                },
                title: 'Skip',
                width: 105,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
