import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';
import 'package:qr_code/app/routes/app_pages.dart';
import 'package:shimmer/shimmer.dart';

import '../../../../res/assets/image_assets.dart';
import '../../../../res/colors/app_color.dart';
import '../../../../widgets/custom_button.dart';
import '../../../../widgets/show_custom_snack_bar.dart';
import '../../auth/controllers/auth_controller.dart';
import '../../auth/views/auth_view.dart';
import '../../home/controllers/home_controller.dart';
import '../controllers/profile_controller.dart';
import '../controllers/settings_controller.dart';
import 'edit_profile_view.dart';
import 'subscription_view.dart';

class SettingsView extends GetView<SettingsController> {
  final AuthController authController = Get.find<AuthController>();
  final ProfileController profileController = Get.find<ProfileController>();
  final HomeController homeController = Get.find<HomeController>();
  SettingsView({super.key});

  @override
  Widget build(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      profileController.fetchProfile();
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (authController.isLoggedIn.value == true ||
          authController.isSignedIn.value == true) {
        homeController.updateHistoryOnLogin();
      }
    });
    return Scaffold(
      body: RefreshIndicator(
        onRefresh: () => profileController.fetchProfile(),
        child: SafeArea(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 20.w),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    SizedBox(height: 40.h),
                    Obx(() {
                      if (profileController.errorMessage.value.isNotEmpty) {
                        return SizedBox(
                          height: 102.h,
                          child: Center(
                            child: Text(
                              'No Profile available',
                              style: TextStyle(
                                fontSize: 16.sp,
                                color: controller.isDarkMode.value
                                    ? AppColor.whiteColor
                                    : AppColor.textColor,
                              ),
                            ),
                          ),
                        );
                      }
                      return Column(
                        children: [
                          Obx(() {
                            if (profileController.isLoading.value) {
                              return Shimmer.fromColors(
                                baseColor: Colors.grey[300]!,
                                highlightColor: Colors.grey[100]!,
                                child: CircleAvatar(
                                  radius: 60.r,
                                  backgroundColor: Colors.white,
                                ),
                              );
                            }

                            final profile = profileController.profile.value;
                            final hasImage =
                                profile?.profilePicture != null &&
                                profile!.profilePicture.isNotEmpty;

                            return CircleAvatar(
                              radius: 60.r,
                              backgroundColor: AppColor.backgroundColor,
                              child: ClipOval(
                                child: hasImage
                                    ? CachedNetworkImage(
                                        imageUrl: profile.profilePicture,
                                        fit: BoxFit.cover,
                                        width: double.infinity,
                                        height: double.infinity,
                                        placeholder: (context, url) =>
                                            Shimmer.fromColors(
                                              baseColor: Colors.grey[300]!,
                                              highlightColor: Colors.grey[100]!,
                                              child: Container(
                                                width: double.infinity,
                                                height: double.infinity,
                                                color: Colors.white,
                                              ),
                                            ),
                                        errorWidget: (context, url, error) =>
                                            SvgPicture.asset(
                                              ImageAssets.img,
                                              fit: BoxFit.cover,
                                              width: double.infinity,
                                              height: double.infinity,
                                            ),
                                      )
                                    : SvgPicture.asset(
                                        ImageAssets.img,
                                        fit: BoxFit.cover,
                                        width: double.infinity,
                                        height: double.infinity,
                                      ),
                              ),
                            );
                          }),
                          SizedBox(height: 10.h),

                          Obx(() {
                            if (profileController.isLoading.value) {
                              return Shimmer.fromColors(
                                baseColor: Colors.grey[300]!,
                                highlightColor: Colors.grey[100]!,
                                child: Container(
                                  height: 16.h,
                                  width: 120.w,
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(4.r),
                                  ),
                                ),
                              );
                            }

                            final profile = profileController.profile.value;
                            return Text(
                              '${profile?.firstName ?? ''} ${profile?.lastName ?? ''}'
                                  .trim(),
                              style: TextStyle(
                                color: controller.isDarkMode.value
                                    ? AppColor.whiteColor
                                    : AppColor.textColor1,
                                fontSize: 16.sp,
                                fontFamily: 'Nunito Sans',
                                fontWeight: FontWeight.w500,
                              ),
                            );
                          }),
                        ],
                      );
                    }),
                    SizedBox(height: 40.h),
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        item(
                          'Profile Management',
                          ImageAssets.profile,
                          false,
                          null,
                        ),
                        SizedBox(height: 20.h),
                        item(
                          'Subscription',
                          ImageAssets.subs,
                          false,
                          authController.isSignedIn.value == true ||
                                  authController.isLoggedIn.value == true
                              ? SubscriptionView()
                              : AuthView(),
                        ),
                        SizedBox(height: 13.h),
                        item('Dark Mode', ImageAssets.dark, true, null),
                      ],
                    ),
                  ],
                ),
                authController.isSignedIn.value == true ||
                        authController.isLoggedIn.value == true
                    ? Column(
                        children: [
                          CustomButton(
                            onPress: () async {
                              showLogoutDialog();
                            },
                            title: 'Log Out',
                          ),
                          SizedBox(height: 40.h),
                        ],
                      )
                    : Column(
                        children: [
                          CustomButton(
                            onPress: () async {
                              Get.toNamed(Routes.auth);
                            },
                            title: 'Log In',
                          ),
                          SizedBox(height: 40.h),
                        ],
                      ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget item(String title, String icons, bool toggle, Widget? navigate) {
    return InkWell(
      onTap: toggle
          ? null
          : () {
              title == 'Profile Management'
                  ? authController.isSignedIn.value == true ||
                            authController.isLoggedIn.value == true
                        ? Get.to(EditProfileView())
                        : showCustomSnackBar(
                            title: 'Error',
                            message: 'Must login to access profile',
                            isSuccess: false,
                          )
                  : title == 'App Info'
                  ? showCustomSnackBar(
                      title: 'Be Patient',
                      message: 'It Will Be Updated Soon',
                      isSuccess: false,
                    )
                  : Get.to(navigate);
            },
      child: SizedBox(
        width: double.infinity,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.center,
              spacing: 13.w,
              children: [
                SvgPicture.asset(icons, width: 24.w, height: 24.h),
                Text(
                  title,
                  style: TextStyle(
                    color: AppColor.textColor2,
                    fontSize: 14.sp,
                    fontFamily: 'Nunito Sans',
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            if (!toggle)
              SvgPicture.asset(ImageAssets.forward, width: 24.w, height: 24.h),
            if (toggle)
              Obx(
                () => Switch(
                  value: controller.isDarkMode.value,
                  onChanged: (value) => controller.toggleDarkMode(value),
                  activeThumbColor: AppColor.defaultColor,
                ),
              ),
          ],
        ),
      ),
    );
  }

  void showLogoutDialog() {
    Get.dialog(
      AlertDialog(
        backgroundColor: controller.isDarkMode.value
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
              'Are you sure you want to\nLog Out?',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: controller.isDarkMode.value
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
                  buttonColor: controller.isDarkMode.value
                      ? AppColor.darkThemeColor
                      : AppColor.backgroundColor,
                ),
                CustomButton(
                  onPress: () async {
                    await authController.logout();
                  },
                  title: 'Continue',
                  height: 32,
                  width: 84,
                  fontSize: 12,
                  buttonColor: controller.isDarkMode.value
                      ? AppColor.default40Color
                      : AppColor.backgroundColor,
                  textColor: controller.isDarkMode.value
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
