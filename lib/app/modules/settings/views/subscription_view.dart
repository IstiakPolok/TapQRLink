import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../res/assets/image_assets.dart';
import '../../../../res/colors/app_color.dart';
import '../../../../widgets/custom_button.dart';
import '../../home/views/nav_bar.dart';
import '../controllers/revenue_cat_controller.dart';
import '../controllers/settings_controller.dart';
import 'upgrade_view.dart';

class SubscriptionView extends GetView<SettingsController> {
  const SubscriptionView({super.key});

  @override
  Widget build(BuildContext context) {
    final revenueCatController = Get.put(RevenueCatController());
    return Obx(
      () => Scaffold(
        appBar: AppBar(
          title: Text(
            'Subscription',
            style: TextStyle(
              color: controller.isDarkMode.value == false
                  ? AppColor.textColor
                  : AppColor.whiteColor,
              fontSize: 18.sp,
              fontFamily: 'Nunito Sans',
              fontWeight: FontWeight.w700,
            ),
          ),
          centerTitle: true,
          leading: InkWell(
            onTap: () => Navigator.pop(Get.context!),
            child: SvgPicture.asset(
              ImageAssets.backward,
              width: 15.w,
              height: 15.h,
              colorFilter: ColorFilter.mode(
                controller.isDarkMode.value == false
                    ? AppColor.textColor
                    : AppColor.whiteColor,
                BlendMode.srcIn,
              ),
            ),
          ),
          toolbarHeight: 25.h,
        ),
        body: Padding(
          padding: EdgeInsets.all(30.sp),
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(
                        width: 317.w,
                        child: Text(
                          revenueCatController.renewalDate != ''
                              ? 'Your Current Plan: Yearly Subscription'
                              : 'Your Current Plan: Free Subscription',
                          style: TextStyle(
                            color: controller.isDarkMode.value == false
                                ? AppColor.textColor
                                : AppColor.whiteColor,
                            fontSize: 18.sp,
                            fontFamily: 'Nunito Sans',
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      SizedBox(height: 25.h),
                      if (revenueCatController.renewalDate != '') ...[
                        Text(
                          'Next Renewal',
                          style: TextStyle(
                            color: controller.isDarkMode.value == false
                                ? AppColor.textColor
                                : AppColor.whiteColor,
                            fontSize: 14.sp,
                            fontFamily: 'Nunito Sans',
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        SizedBox(height: 8.h),
                        Container(
                          width: double.infinity,
                          height: 39.h,
                          decoration: ShapeDecoration(
                            color: controller.isDarkMode.value == false
                                ? AppColor.containerColor
                                : AppColor.containerColor4,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8.r),
                            ),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              SizedBox(width: 16.w),
                              Text(
                                revenueCatController.renewalDate,
                                style: TextStyle(
                                  color: controller.isDarkMode.value == false
                                      ? AppColor.textColor2
                                      : AppColor.whiteColor,
                                  fontSize: 12.sp,
                                  fontFamily: 'Nunito Sans',
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(height: 16.h),
                        Text(
                          'Billed',
                          style: TextStyle(
                            color: controller.isDarkMode.value == false
                                ? AppColor.textColor
                                : AppColor.whiteColor,
                            fontSize: 14.sp,
                            fontFamily: 'Nunito Sans',
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        SizedBox(height: 8.h),
                        Container(
                          width: double.infinity,
                          height: 39.h,
                          decoration: ShapeDecoration(
                            color: controller.isDarkMode.value == false
                                ? AppColor.containerColor
                                : AppColor.containerColor4,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8.r),
                            ),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              SizedBox(width: 16.w),
                              Text(
                                '\$35.99 per year',
                                style: TextStyle(
                                  color: controller.isDarkMode.value == false
                                      ? AppColor.textColor2
                                      : AppColor.whiteColor,
                                  fontSize: 12.sp,
                                  fontFamily: 'Nunito Sans',
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(height: 26.h),
                      ],
                      Text(
                        'Premium Features',
                        style: TextStyle(
                          color: controller.isDarkMode.value == false
                              ? AppColor.textColor1
                              : AppColor.whiteColor,
                          fontSize: 18,
                          fontFamily: 'Nunito Sans',
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      SizedBox(height: 16.h),
                      row('Unlimited Scan History'),
                      row('Ad-Free Experience'),
                      row('Auto-Link Opening'),
                      row('Early Access to New Features'),
                      row('More Scanning Access'),
                      SizedBox(height: 20.h),
                    ],
                  ),
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  CustomButton(
                    onPress: () async {
                      {
                        Get.to(Navbar());
                      }
                    },
                    title: 'Cancel',
                    height: 41,
                    width: 146,
                  ),
                  CustomButton(
                    height: 41,
                    width: 146,
                    onPress: () async {
                      if (revenueCatController.renewalDate.isEmpty) {
                        Get.to(() => const UpgradeView());
                      } else {
                        try {
                          if (Platform.isAndroid) {
                            final Uri url = Uri.parse(
                              "https://play.google.com/store/account/subscriptions",
                            );
                            await launchUrl(url);
                          } else if (Platform.isIOS) {
                            final Uri url = Uri.parse(
                              "https://apps.apple.com/account/subscriptions",
                            );
                            await launchUrl(url);
                          }
                        } catch (e) {
                          debugPrint("Error opening management page: $e");
                          Get.snackbar(
                            'Manage Subscription',
                            'Please open the Play Store to manage your active plan.',
                            snackPosition: SnackPosition.BOTTOM,
                          );
                        }
                      }
                    },
                    title: revenueCatController.renewalDate.isEmpty
                        ? 'Upgrade'
                        : 'Manage',
                  ),
                ],
              ),
              SizedBox(height: 20.h),
            ],
          ),
        ),
      ),
    );
  }

  Widget row(String title) {
    return Row(
      spacing: 8.w,
      children: [
        SvgPicture.asset(ImageAssets.tic, height: 24.h, width: 24.w),
        SizedBox(
          width: 195.w,
          child: Text(
            title,
            style: TextStyle(
              color: controller.isDarkMode.value == false
                  ? AppColor.textColor1
                  : AppColor.whiteColor,
              fontSize: 14.sp,
              fontFamily: 'Nunito Sans',
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }
}
