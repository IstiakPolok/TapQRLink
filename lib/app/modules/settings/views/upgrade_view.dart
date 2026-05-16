import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:qr_code/app/modules/auth/views/auth_view.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../res/assets/image_assets.dart';
import '../../../../res/colors/app_color.dart';
import '../../../../widgets/custom_button.dart';
import '../../../../widgets/show_custom_snack_bar.dart';
import '../../auth/controllers/auth_controller.dart';
import '../controllers/settings_controller.dart';
import 'paywall_page.dart';
import 'purchasea_api.dart';

class UpgradeView extends GetView<SettingsController> {
  const UpgradeView({super.key});
  @override
  Widget build(BuildContext context) {
    return Obx(
      () => Scaffold(
        appBar: AppBar(
          title: Text(
            'Upgrade to Premium',
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
                      Center(
                        child: Image.asset(
                          ImageAssets.img1,
                          width: 213.w,
                          height: 303.h,
                        ),
                      ),
                      SizedBox(height: 30.h),
                      plan(context, '1 Year', 35.99, 'Yearly', 1),
                      SizedBox(height: 25.h),
                      Text(
                        'Premium Features',
                        style: TextStyle(
                          color: controller.isDarkMode.value == false
                              ? AppColor.textColor
                              : AppColor.whiteColor,
                          fontSize: 18.sp,
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
                      SizedBox(height: 25.h),
                      Text(
                        'Got an issue? Let us know.',
                        style: TextStyle(
                          color: controller.isDarkMode.value == false
                              ? AppColor.textColor
                              : AppColor.whiteColor,
                          fontSize: 18.sp,
                          fontFamily: 'Nunito Sans',
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      SizedBox(height: 10.h),
                      Row(
                        spacing: 8.w,
                        children: [
                          Icon(Icons.mail_outline),
                          GestureDetector(
                            onTap: () => _launchEmail(),
                            child: Text(
                              'Help@tapqrlink.com',
                              style: TextStyle(
                                color: controller.isDarkMode.value == false
                                    ? AppColor.textColor
                                    : AppColor.whiteColor,
                                fontSize: 14.sp,
                                fontFamily: 'Nunito Sans',
                                fontWeight: FontWeight.w500,
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
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _launchEmail() async {
    const String email = 'help@tapqrlink.com';
    const String subject = 'Support Request';
    const String body = 'Please describe your issue.';

    final Uri gmailUri = Uri.parse(
      'intent://sendto/$email'
      '?subject=${Uri.encodeComponent(subject)}'
      '&body=${Uri.encodeComponent(body)}'
      '#Intent;package=com.google.android.gm;end',
    );

    final Uri emailLaunchUri = Uri(
      scheme: 'mailto',
      path: email,
      query:
          'subject=${Uri.encodeComponent(subject)}&body=${Uri.encodeComponent(body)}',
    );

    try {
      if (await canLaunchUrl(gmailUri)) {
        await launchUrl(gmailUri, mode: LaunchMode.externalApplication);
      } else if (await canLaunchUrl(emailLaunchUri)) {
        await launchUrl(emailLaunchUri, mode: LaunchMode.externalApplication);
      } else {
        await launchUrl(
          Uri.parse('mailto:$email'),
          mode: LaunchMode.externalApplication,
        );
      }
    } catch (e) {
      debugPrint('Error sending email: $e');
      Get.snackbar(
        'Error',
        'An error occurred while trying to open the email client.',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  Widget plan(
    BuildContext context,
    String title,
    double price,
    String duration,
    int index,
  ) {
    return GestureDetector(
      onTap: () {
        controller.selectedPlanIndex.value = index;
        showUpgradeDialog(context);
      },
      child: Obx(
        () => Container(
          width: double.infinity,
          height: 64.h,
          padding: EdgeInsets.symmetric(horizontal: 17.w),
          decoration: ShapeDecoration(
            color: controller.selectedPlanIndex.value == index
                ? AppColor.defaultColor
                : AppColor.containerColor,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16.r),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Column(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: controller.selectedPlanIndex.value == index
                          ? AppColor.whiteColor
                          : AppColor.textColor,
                      fontSize: 18.sp,
                      fontFamily: 'Nunito Sans',
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    'Total Price- \$$price',
                    style: TextStyle(
                      color: controller.selectedPlanIndex.value == index
                          ? AppColor.whiteColor
                          : AppColor.textColor2,
                      fontSize: 14.sp,
                      fontFamily: 'Nunito Sans',
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
              Column(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '\$$price',
                    textAlign: TextAlign.right,
                    style: TextStyle(
                      color: controller.selectedPlanIndex.value == index
                          ? AppColor.whiteColor
                          : AppColor.textColor,
                      fontSize: 18.sp,
                      fontFamily: 'Nunito Sans',
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    duration,
                    textAlign: TextAlign.right,
                    style: TextStyle(
                      color: controller.selectedPlanIndex.value == index
                          ? AppColor.whiteColor
                          : AppColor.textColor2,
                      fontSize: 14.sp,
                      fontFamily: 'Nunito Sans',
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
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

  void showUpgradeDialog(BuildContext context) {
    final AuthController authController = Get.find();
    Get.dialog(
      AlertDialog(
        backgroundColor: controller.isDarkMode.value == false
            ? AppColor.containerColor
            : AppColor.darkThemeColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12.r),
        ),
        contentPadding: EdgeInsets.all(12.sp),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Are you sure you want to\nupgrade to the Premium plan?',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: controller.isDarkMode.value == false
                    ? AppColor.textColor
                    : AppColor.whiteColor,
                fontSize: 16.sp,
                fontFamily: 'Nunito Sans',
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: 16.h),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                CustomButton(
                  onPress: () async {
                    Navigator.pop(Get.context!);
                  },
                  title: 'Cancel',
                  textColor: AppColor.defaultColor,
                  height: 32,
                  width: 84,
                  fontSize: 12,
                  borderColor: AppColor.defaultColor,
                  buttonColor: controller.isDarkMode.value == false
                      ? AppColor.backgroundColor
                      : AppColor.darkThemeColor,
                ),
                CustomButton(
                  onPress: () async {
                    Navigator.pop(Get.context!);
                    if (authController.isLoggedIn.value ||
                        authController.isSignedIn.value) {
                      await fetchOffers(context);
                    } else {
                      showCustomSnackBar(
                        title: 'Lon In First',
                        message: 'Create An Account First Then Purchase',
                        isSuccess: false,
                      );
                      Get.to(AuthView());
                    }
                  },
                  title: 'Continue',
                  height: 32,
                  width: 84,
                  fontSize: 12,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> fetchOffers(BuildContext context) async {
    final offerings = await PurchaseApi.fetchOffers();
    if (offerings.isEmpty) {
      ScaffoldMessenger.of(
        Get.context!,
      ).showSnackBar(const SnackBar(content: Text('No offers found')));
      return;
    }

    final packages = offerings
        .map((offer) => offer.availablePackages)
        .expand((element) => element)
        .toList();

    Get.bottomSheet(
      Padding(
        padding: EdgeInsets.symmetric(vertical: 10.h),
        child: PaywallPage(
          packages: packages,
          title: 'Upgrade to Premium',
          description: 'Unlock Premium Features',
          onPackageSelected: (package) async {
            await PurchaseApi.purchasePackage(context, package);
            Navigator.pop(Get.context!);
          },
        ),
      ),

      backgroundColor: Colors.white,
      isScrollControlled: true,
    );

    final offer = offerings.first;
    debugPrint('Offer: $offer');
  }
}
