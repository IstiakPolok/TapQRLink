import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:shimmer/shimmer.dart';

import '../../../../res/assets/image_assets.dart';
import '../../../../res/colors/app_color.dart';
import '../../../../widgets/custom_button.dart';
import '../../auth/controllers/auth_controller.dart';
import '../controllers/home_controller.dart';

class NotificationView extends GetView<HomeController> {
  final ScrollController _scrollController = ScrollController();

  NotificationView({super.key}) {
    _scrollController.addListener(() {
      if (_scrollController.position.pixels >=
          _scrollController.position.maxScrollExtent - 100) {
        if (!controller.isLoading.value &&
            controller.nextNotificationUrl.value != null) {
          debugPrint(
            "Loading next notifications: ${controller.nextNotificationUrl.value}",
          );
          controller.fetchNotifications(isLoadMore: true);
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final AuthController authController = Get.find();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if ((authController.isSignedIn.value ||
              authController.isLoggedIn.value) &&
          controller.notifications.isEmpty &&
          !controller.isLoading.value) {
        controller.fetchNotifications();
      }
    });

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.all(20.sp),
          child: Column(
            children: [
              SizedBox(height: 20.h),
              Text(
                'Notifications',
                style: TextStyle(fontSize: 24.sp, fontWeight: FontWeight.w600),
              ),
              SizedBox(height: 50.h),
              Expanded(
                child: Obx(() {
                  bool isAuth =
                      authController.isSignedIn.value ||
                      authController.isLoggedIn.value;

                  if (!isAuth) {
                    return const Center(
                      child: Text('Please sign in to view notifications'),
                    );
                  }

                  if (controller.isLoading.value &&
                      controller.notifications.isEmpty) {
                    return ListView.builder(
                      itemCount: 10,
                      itemBuilder: (_, _) => _shimmerItem(),
                    );
                  }

                  if (controller.notifications.isEmpty) {
                    return const Center(
                      child: Text('No notifications available'),
                    );
                  }

                  return ListView.builder(
                    controller: _scrollController,
                    itemCount:
                        controller.notifications.length +
                        (controller.nextNotificationUrl.value != null ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (index < controller.notifications.length) {
                        final item = controller.notifications[index];
                        return notificationItem(
                          item.title,
                          item.message,
                          () => controller.showNotificationDetails(item.id),
                          () => deleteDialog(item.id),
                        );
                      } else {
                        return _shimmerItem();
                      }
                    },
                  );
                }),
              ),
            ],
          ),
        ),
      ),
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

  Widget _shimmerItem() {
    return Shimmer.fromColors(
      baseColor: Get.isDarkMode ? Colors.grey[800]! : Colors.grey[300]!,
      highlightColor: Get.isDarkMode ? Colors.grey[700]! : Colors.grey[100]!,
      child: Padding(
        padding: EdgeInsets.only(bottom: 20.h),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(width: 24.w, height: 24.h, color: Colors.white),
            SizedBox(width: 10.w),
            Expanded(
              child: Column(
                spacing: 4.h,
                children: [
                  Container(
                    margin: EdgeInsets.only(right: 50.w),
                    height: 16.h,
                    color: Colors.white,
                  ),
                  Container(
                    margin: EdgeInsets.only(right: 50.w),
                    height: 16.h,
                    color: Colors.white,
                  ),
                  Container(
                    margin: EdgeInsets.only(right: 100.w),
                    height: 16.h,
                    color: Colors.white,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget notificationItem(
    String title,
    String message,
    VoidCallback onTap,
    VoidCallback onDelete,
  ) {
    return Column(
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: GestureDetector(
                onTap: onTap,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SvgPicture.asset(ImageAssets.notify1, width: 24.w),
                    SizedBox(width: 10.w),
                    Expanded(
                      child: Text(
                        '$title: $message',
                        style: TextStyle(
                          fontSize: 16.sp,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            IconButton(
              onPressed: onDelete,
              icon: SvgPicture.asset(ImageAssets.delete, width: 25.w),
            ),
          ],
        ),
        const Divider(),
        SizedBox(height: 10.h),
      ],
    );
  }
}
