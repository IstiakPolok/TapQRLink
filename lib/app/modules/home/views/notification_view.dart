import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';

import '../../../../res/assets/image_assets.dart';
import '../../../../res/colors/app_color.dart';
import '../../../../widgets/custom_button.dart';
import '../../auth/controllers/auth_controller.dart';
import '../controllers/home_controller.dart';

class NotificationView extends GetView<HomeController> {
  const NotificationView({super.key});

  @override
  Widget build(BuildContext context) {
    final AuthController authController = Get.find();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (authController.isSignedIn.value == true ||
          authController.isLoggedIn.value == true) {
        controller.fetchNotifications();
      }
    });
    return Obx(
      () => Scaffold(
        body: SafeArea(
          child: Padding(
            padding: EdgeInsets.all(20.sp),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                SizedBox(height: 20.h),
                Center(
                  child: Text(
                    'Notifications',
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
                Expanded(
                  child:
                      !(authController.isSignedIn.value ||
                          authController.isLoggedIn.value)
                      ? Center(
                          child: Text(
                            'Please sign in to view notifications',
                            style: TextStyle(
                              fontSize: 16.sp,
                              color: Get.isDarkMode
                                  ? AppColor.whiteColor
                                  : AppColor.textColor,
                            ),
                          ),
                        )
                      : controller.isLoading.value
                      ? const Center(child: CircularProgressIndicator())
                      : controller.notifications.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                'No notifications available',
                                style: TextStyle(
                                  fontSize: 16.sp,
                                  color: Get.isDarkMode
                                      ? AppColor.whiteColor
                                      : AppColor.textColor,
                                ),
                              ),
                              SizedBox(height: 50.h),
                            ],
                          ),
                        )
                      : SingleChildScrollView(
                          child: Column(
                            children: controller.notifications
                                .asMap()
                                .entries
                                .map((entry) {
                                  final notification = entry.value;
                                  return history(
                                    notification.title,
                                    notification.message,
                                    () => controller.showNotificationDetails(
                                      notification.id,
                                    ),
                                    () => deleteDialog(notification.id),
                                  );
                                })
                                .toList(),
                          ),
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget history(
    String title,
    String message,
    VoidCallback onTap,
    VoidCallback onDelete,
  ) {
    return Column(
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: GestureDetector(
                onTap: onTap,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SvgPicture.asset(
                      ImageAssets.notify1,
                      width: 24.w,
                      height: 24.h,
                    ),
                    SizedBox(width: 10.w),
                    Expanded(
                      child: Text(
                        '$title: $message',
                        style: TextStyle(
                          color: Get.isDarkMode
                              ? AppColor.whiteColor
                              : AppColor.textColor,
                          fontSize: 16.sp,
                          fontFamily: 'Nunito Sans',
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            GestureDetector(
              onTap: onDelete,
              child: Column(
                children: [
                  SvgPicture.asset(
                    ImageAssets.delete,
                    width: 25.w,
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
        SizedBox(height: 15.h),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 9.w),
          child: Container(
            width: double.infinity,
            decoration: ShapeDecoration(
              shape: RoundedRectangleBorder(
                side: BorderSide(
                  width: .5.w,
                  strokeAlign: BorderSide.strokeAlignCenter,
                  color: AppColor.borderColor,
                ),
              ),
            ),
          ),
        ),
        SizedBox(height: 20.h),
      ],
    );
  }

  void deleteDialog(int id) {
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
              'Are you sure you want to\nDelete Notification?',
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
                    await controller.deleteNotification(id);
                    controller.notifications.refresh();
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
