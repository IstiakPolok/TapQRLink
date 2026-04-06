import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../app/routes/app_pages.dart';
import '../../../../res/assets/image_assets.dart';
import '../../../../res/colors/app_color.dart';
import '../../../../widgets/custom_button.dart';
import '../../auth/controllers/auth_controller.dart';
import '../../settings/controllers/revenue_cat_controller.dart';
import '../../settings/views/subscription_view.dart';
import '../controllers/home_controller.dart';

class HistoryView extends GetView<HomeController> {
  final AuthController authController = Get.find();
  final RevenueCatController revenueCatController = Get.find();
  final FlutterSecureStorage storage = const FlutterSecureStorage();
  HistoryView({super.key});

  @override
  Widget build(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      authController.isLoggedIn.value == true ||
              authController.isSignedIn.value == true
          ? controller.fetchHistory()
          : controller.loadHistory();
    });
    return Scaffold(
      body: Obx(
        () => SafeArea(
          child: Padding(
            padding: EdgeInsets.all(20.sp),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                SizedBox(height: 20.h),
                Center(
                  child: Text(
                    'History',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Get.isDarkMode
                          ? AppColor.whiteColor
                          : AppColor.textColor,
                      fontSize: 24.sp,
                      fontFamily: 'Nunito Sans',
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                SizedBox(height: 50.h),
                authController.isLoggedIn.value == true ||
                        authController.isSignedIn.value == true
                    ? Expanded(
                        child: controller.isLoading.value
                            ? const Center(child: CircularProgressIndicator())
                            : controller.historyItems.isEmpty
                            ? Center(
                                child: Text(
                                  'No scan history available',
                                  style: TextStyle(
                                    fontSize: 16.sp,
                                    color: Get.isDarkMode
                                        ? AppColor.whiteColor
                                        : AppColor.textColor,
                                  ),
                                ),
                              )
                            : SingleChildScrollView(
                                child: Column(
                                  children: controller.historyItems
                                      .asMap()
                                      .entries
                                      .map((entry) {
                                        final history = entry.value;
                                        return historyWidget(
                                          history.link,
                                          DateFormat(
                                            'hh.mm a, dd MMMM yyyy',
                                          ).format(history.scannedAt),
                                          history.image ?? '',
                                          () => controller.showHistoryDetails(
                                            history.id,
                                          ),
                                          () => deleteDialog(
                                            (history.id).toString(),
                                          ),
                                          history.isRead,
                                        );
                                      })
                                      .toList(),
                                ),
                              ),
                      )
                    : Expanded(
                        child: Obx(
                          () => controller.historyList.isEmpty
                              ? Center(
                                  child: Text(
                                    'No scan history available',
                                    style: TextStyle(
                                      fontSize: 16.sp,
                                      color: Get.isDarkMode
                                          ? AppColor.whiteColor
                                          : AppColor.textColor,
                                    ),
                                  ),
                                )
                              : ListView.builder(
                                  itemCount: controller.historyList.length,
                                  itemBuilder: (context, index) {
                                    final historyItem =
                                        controller.historyList[index];
                                    final link = historyItem['link'];
                                    final scannedAt = DateTime.parse(
                                      historyItem['scanned_at'],
                                    );
                                    final id = historyItem['id'];
                                    return historyWidget(
                                      link,
                                      DateFormat(
                                        'hh:mm a, dd MMMM yyyy',
                                      ).format(scannedAt),
                                      ImageAssets.img,
                                      () => dialogWidget(
                                        link,
                                        DateFormat(
                                          'hh:mm a, dd MMMM yyyy',
                                        ).format(scannedAt),
                                      ),
                                      () => deleteDialog(id),
                                      false,
                                    );
                                  },
                                ),
                        ),
                      ),
                SizedBox(height: 24.h),
                if (revenueCatController.renewalDate.isEmpty) ...[
                  SizedBox(
                    width: 199.w,
                    child: Text(
                      'Scan History – Free Access Limited to 3 Scans',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Get.isDarkMode
                            ? AppColor.whiteColor
                            : AppColor.textColor2,
                        fontSize: 16.sp,
                        fontFamily: 'Nunito Sans',
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ),
                  SizedBox(height: 20.h),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      InkWell(
                        onTap: () {
                          authController.isSignedIn.value == true ||
                                  authController.isLoggedIn.value == true
                              ? Get.to(SubscriptionView())
                              : Get.toNamed(Routes.auth);
                        },
                        child: SizedBox(
                          width: 104.w,
                          child: Text(
                            'Get Premium',
                            style: TextStyle(
                              color: AppColor.defaultColor,
                              fontSize: 16.sp,
                              fontFamily: 'Nunito Sans',
                              fontWeight: FontWeight.w600,
                              decoration: TextDecoration.underline,
                              decorationColor: AppColor.defaultColor,
                            ),
                          ),
                        ),
                      ),
                      Text(
                        '-To Unlock More Features',
                        style: TextStyle(
                          color: Get.isDarkMode
                              ? AppColor.whiteColor
                              : AppColor.textColor2,
                          fontSize: 16.sp,
                          fontFamily: 'Nunito Sans',
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget historyWidget(
    String link,
    String time,
    String? image,
    VoidCallback onTap,
    VoidCallback onDelete,
    bool view,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        height: 88.h,
        child: Column(
          children: [
            Row(
              spacing: 10.w,
              children: [
                Row(
                  spacing: 6.w,
                  children: [
                    Container(
                      width: 62.w,
                      height: 62.h,
                      padding: EdgeInsets.all(10.sp),
                      decoration: ShapeDecoration(
                        shape: RoundedRectangleBorder(
                          side: BorderSide(width: 1.w, color: Colors.white),
                          borderRadius: BorderRadius.circular(8.r),
                        ),
                      ),
                      child:
                          authController.isLoggedIn.value == true ||
                              authController.isSignedIn.value == true
                          ? Image.network(image!)
                          : QrImageView(
                              data: link,
                              version: QrVersions.auto,
                              size: 278.w,
                              backgroundColor: Colors.white,
                              padding: EdgeInsets.all(8.sp),
                            ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(
                          width: 190.w,
                          child: GestureDetector(
                            onTap: onTap,
                            child: Text(
                              'QR Code Scanned',
                              style: TextStyle(
                                color: Get.isDarkMode
                                    ? AppColor.whiteColor
                                    : AppColor.textColor,
                                fontSize: 14.sp,
                                fontFamily: 'Nunito Sans',
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                        SizedBox(height: 4.h),
                        SizedBox(
                          width: 190.w,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.start,
                            children: [
                              Text(
                                time,
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: Get.isDarkMode
                                      ? AppColor.whiteColor
                                      : AppColor.textColor,
                                  fontSize: 12.sp,
                                  fontFamily: 'Nunito Sans',
                                  fontWeight: FontWeight.w400,
                                ),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(height: 6.h),
                        if (!view)
                          Container(
                            width: 70.w,
                            height: 16.h,
                            decoration: ShapeDecoration(
                              color: AppColor.defaultDeepColor,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(4.r),
                              ),
                            ),
                            child: Center(
                              child: Text(
                                'View Details',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: AppColor.defaultColor,
                                  fontSize: 8.sp,
                                  fontFamily: 'Nunito Sans',
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
                GestureDetector(
                  onTap: onDelete,
                  child: Column(
                    children: [
                      SvgPicture.asset(
                        ImageAssets.delete,
                        width: 26.w,
                        height: 30.h,
                      ),
                      Text(
                        'Delete',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Get.isDarkMode
                              ? AppColor.whiteColor
                              : AppColor.textColor2,
                          fontSize: 12.sp,
                          fontFamily: 'Nunito Sans',
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            SizedBox(height: 12.h),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 10.w),
              child: Container(
                width: double.infinity,
                decoration: ShapeDecoration(
                  shape: RoundedRectangleBorder(
                    side: BorderSide(
                      width: .5.sp,
                      strokeAlign: BorderSide.strokeAlignCenter,
                      color: AppColor.borderColor,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future dialogWidget(String link, String scannedAt) {
    return Get.dialog(
      AlertDialog(
        title: Text(
          'QR Code Details',
          style: TextStyle(
            fontFamily: 'Nunito Sans',
            fontWeight: FontWeight.w600,
            fontSize: 18.sp,
            color: Get.isDarkMode ? AppColor.whiteColor : AppColor.textColor,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: 10.h),
            GestureDetector(
              onTap: () => _launchLink(link),
              child: Text(
                'Link: $link',
                style: TextStyle(
                  fontFamily: 'Nunito Sans',
                  fontSize: 16.sp,
                  color: Colors.blue,
                  decoration: TextDecoration.underline,
                ),
              ),
            ),
            SizedBox(height: 10.h),
            Text(
              'Scanned at: $scannedAt',
              style: TextStyle(
                fontFamily: 'Nunito Sans',
                fontSize: 14.sp,
                color: Get.isDarkMode
                    ? AppColor.whiteColor
                    : AppColor.textColor,
              ),
            ),
          ],
        ),
        backgroundColor: Get.isDarkMode
            ? AppColor.darkThemeColor
            : AppColor.backgroundColor,
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(Get.context!),
            child: Text(
              'Close',
              style: TextStyle(
                fontFamily: 'Nunito Sans',
                color: AppColor.viewColor,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _launchLink(String url) async {
    try {
      final Uri linkLaunchUri = Uri.parse(url);

      if (await canLaunchUrl(linkLaunchUri)) {
        await launchUrl(linkLaunchUri, mode: LaunchMode.externalApplication);
      } else {
        await launchUrl(linkLaunchUri, mode: LaunchMode.inAppWebView);
      }
    } catch (e) {
      debugPrint('Error launching link: $e');
      Get.snackbar(
        'Error',
        'Could not open link',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  void deleteDialog(String id) {
    Get.dialog(
      AlertDialog(
        backgroundColor: Get.isDarkMode
            ? AppColor.darkThemeColor
            : AppColor.containerColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12.r),
        ),
        contentPadding: EdgeInsets.all(12.sp),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Are you sure you want to\nDelete History?',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Get.isDarkMode
                    ? AppColor.whiteColor
                    : AppColor.textColor,
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
                  buttonColor: Get.isDarkMode
                      ? AppColor.darkThemeColor
                      : AppColor.backgroundColor,
                ),
                CustomButton(
                  onPress: () async {
                    Navigator.pop(Get.context!);
                    if (authController.isLoggedIn.value == true ||
                        authController.isSignedIn.value == true) {
                      await controller.deleteHistory(int.parse(id));
                      controller.historyItems.refresh();
                    } else {
                      await controller.removeHistoryById(id);
                      controller.historyList.refresh();
                      controller.loadHistory();
                      controller.getHistory();
                    }
                  },
                  title: 'Continue',
                  height: 32,
                  width: 84,
                  fontSize: 12,
                  buttonColor: Get.isDarkMode
                      ? AppColor.default40Color
                      : AppColor.backgroundColor,
                  textColor: Get.isDarkMode
                      ? AppColor.whiteColor
                      : AppColor.defaultColor,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
