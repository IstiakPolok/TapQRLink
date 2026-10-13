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
import '../models/entitlement.dart';
import 'upgrade_view.dart';

class SubscriptionView extends GetView<SettingsController> {
  const SubscriptionView({super.key});

  @override
  Widget build(BuildContext context) {
    final revenueCatController = Get.put(RevenueCatController());
    revenueCatController.updatePurchaseStatus();
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
                          revenueCatController.entitlement == Entitlement.allFeatures
                              ? 'Your Current Plan: ${revenueCatController.activeProductName.isNotEmpty ? revenueCatController.activeProductName : 'Premium Subscription'}'
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
                      if (revenueCatController.entitlement == Entitlement.allFeatures) ...[
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
                                revenueCatController.renewalDate.isNotEmpty
                                    ? revenueCatController.renewalDate
                                    : 'N/A (Lifetime or auto-renew off)',
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
                                revenueCatController.activeProductPriceString.isNotEmpty
                                    ? revenueCatController.activeProductPriceString
                                    : 'Premium Subscription',
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
                      SizedBox(height: 16.h),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          GestureDetector(
                            onTap: () => _launchURL('https://tapqrlink.com/privacy-policy'),
                            child: Text(
                              'Privacy Policy',
                              style: TextStyle(
                                color: controller.isDarkMode.value == false
                                    ? AppColor.textColor1
                                    : AppColor.whiteColor.withValues(alpha: 0.7),
                                fontSize: 12.sp,
                                fontFamily: 'Nunito Sans',
                                fontWeight: FontWeight.w500,
                                decoration: TextDecoration.underline,
                              ),
                            ),
                          ),
                          Padding(
                            padding: EdgeInsets.symmetric(horizontal: 12.w),
                            child: Text(
                              '|',
                              style: TextStyle(
                                color: controller.isDarkMode.value == false
                                    ? AppColor.textColor2
                                    : AppColor.whiteColor.withValues(alpha: 0.5),
                              ),
                            ),
                          ),
                          GestureDetector(
                            onTap: () => _launchURL('https://www.apple.com/legal/internet-services/itunes/dev/stdeula/'),
                            child: Text(
                              'Terms of Use (EULA)',
                              style: TextStyle(
                                color: controller.isDarkMode.value == false
                                    ? AppColor.textColor1
                                    : AppColor.whiteColor.withValues(alpha: 0.7),
                                fontSize: 12.sp,
                                fontFamily: 'Nunito Sans',
                                fontWeight: FontWeight.w500,
                                decoration: TextDecoration.underline,
                              ),
                            ),
                          ),
                        ],
                      ),
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
                      if (Navigator.canPop(Get.context!)) {
                        Get.back();
                      } else {
                        Get.offAll(() => Navbar());
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
                      if (revenueCatController.entitlement != Entitlement.allFeatures) {
                        Get.to(() => const UpgradeView());
                      } else {
                        _showManageBottomSheet(context, revenueCatController);
                      }
                    },
                    title: revenueCatController.entitlement != Entitlement.allFeatures
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

  void _showManageBottomSheet(
    BuildContext context,
    RevenueCatController revenueCatController,
  ) {
    final isDark = controller.isDarkMode.value;
    Get.bottomSheet(
      Container(
        padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 24.h),
        decoration: BoxDecoration(
          color: isDark ? AppColor.darkThemeColor : AppColor.whiteColor,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(24.r),
            topRight: Radius.circular(24.r),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40.w,
                height: 4.h,
                decoration: BoxDecoration(
                  color: isDark ? Colors.white24 : Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2.r),
                ),
              ),
            ),
            SizedBox(height: 16.h),
            Text(
              'Manage Subscription',
              style: TextStyle(
                color: isDark ? AppColor.whiteColor : AppColor.textColor,
                fontSize: 18.sp,
                fontFamily: 'Nunito Sans',
                fontWeight: FontWeight.w700,
              ),
            ),
            SizedBox(height: 6.h),
            Text(
              revenueCatController.renewalDate.isNotEmpty
                  ? 'Active: ${revenueCatController.activeProductName} (Renews: ${revenueCatController.renewalDate})'
                  : 'Active: ${revenueCatController.activeProductName.isNotEmpty ? revenueCatController.activeProductName : 'Premium Subscription'}',
              style: TextStyle(
                color: isDark
                    ? AppColor.whiteColor.withValues(alpha: 0.7)
                    : AppColor.textColor2,
                fontSize: 13.sp,
                fontFamily: 'Nunito Sans',
                fontWeight: FontWeight.w500,
              ),
            ),
            SizedBox(height: 20.h),
            _manageOptionTile(
              isDark: isDark,
              icon: Icons.swap_horiz_rounded,
              title: 'Change / Switch Plan',
              subtitle: 'Upgrade or switch between Monthly & Yearly',
              onTap: () {
                Get.back();
                Get.to(() => const UpgradeView());
              },
            ),
            SizedBox(height: 12.h),
            _manageOptionTile(
              isDark: isDark,
              icon: Platform.isIOS ? Icons.apple_rounded : Icons.shop_two_rounded,
              title: Platform.isIOS ? 'Manage in App Store' : 'Manage in Google Play',
              subtitle: 'Cancel subscription, view billing or renewal date',
              onTap: () async {
                Get.back();
                await revenueCatController.manageSubscription();
              },
            ),
            SizedBox(height: 16.h),
          ],
        ),
      ),
      isScrollControlled: true,
    );
  }

  Widget _manageOptionTile({
    required bool isDark,
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12.r),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
        decoration: BoxDecoration(
          color: isDark ? AppColor.containerColor4 : AppColor.containerColor,
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(
            color: isDark
                ? AppColor.darkThemeBorderColor
                : AppColor.borderColor,
            width: 1.w,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(8.sp),
              decoration: BoxDecoration(
                color: AppColor.defaultColor.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: AppColor.defaultColor, size: 20.sp),
            ),
            SizedBox(width: 12.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: isDark ? AppColor.whiteColor : AppColor.textColor,
                      fontSize: 14.sp,
                      fontFamily: 'Nunito Sans',
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(height: 2.h),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: isDark
                          ? AppColor.whiteColor.withValues(alpha: 0.6)
                          : AppColor.textColor2,
                      fontSize: 12.sp,
                      fontFamily: 'Nunito Sans',
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              color: isDark
                  ? AppColor.whiteColor.withValues(alpha: 0.5)
                  : AppColor.textColor2,
              size: 20.sp,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _launchURL(String urlString) async {
    final Uri url = Uri.parse(urlString);
    try {
      if (await canLaunchUrl(url)) {
        await launchUrl(url, mode: LaunchMode.externalApplication);
      } else {
        await launchUrl(url, mode: LaunchMode.platformDefault);
      }
    } catch (e) {
      debugPrint('Error launching URL: $e');
    }
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
