import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';
import 'package:shimmer/shimmer.dart';

import '../../../../res/assets/image_assets.dart';
import '../../../../res/colors/app_color.dart';
import '../../../../widgets/custom_button.dart';
import '../../../../widgets/input_text_widget.dart';
import '../controllers/bottom_sheet_controller.dart';
import '../controllers/profile_controller.dart';
import '../controllers/settings_controller.dart';

class EditProfileView extends GetView<SettingsController> {
  final ProfileController profileController = Get.find();
  final BottomSheetController as = Get.find();
  EditProfileView({super.key});
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        FocusScope.of(context).unfocus();
      },
      child: Obx(
        () => Scaffold(
          appBar: AppBar(
            leading: InkWell(
              onTap: () {
                Get.closeCurrentSnackbar();
                Navigator.pop(Get.context!);
              },
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
          body: SafeArea(
            child: Padding(
              padding: EdgeInsets.all(32.sp),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SizedBox(height: 10.h),
                          Center(
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                Obx(() {
                                  profileController.pickedImage.value =
                                      as.pickedImage.value;
                                  final pickedImage =
                                      profileController.pickedImage.value;
                                  final profile =
                                      profileController.profile.value;
                                  final networkUrl =
                                      profile?.profilePicture ?? '';

                                  return ClipOval(
                                    child: SizedBox(
                                      width: 120.w,
                                      height: 120.w,
                                      child: _buildImageContent(
                                        pickedImage,
                                        networkUrl,
                                      ),
                                    ),
                                  );
                                }),

                                Positioned(
                                  bottom: 5.h,
                                  right: 5.w,
                                  child: GestureDetector(
                                    onTap: as.getBottomSheet,
                                    child: Container(
                                      width: 34.w,
                                      height: 34.w,
                                      decoration: BoxDecoration(
                                        color: AppColor.buttonColor,
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                          color: Colors.white,
                                          width: 2.w,
                                        ),
                                      ),
                                      child: Icon(
                                        Icons.camera_alt,
                                        size: 18.sp,
                                        color: controller.isDarkMode.value
                                            ? AppColor.darkThemeColor
                                            : AppColor.backgroundColor,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          SizedBox(height: 40.h),
                          Text(
                            'First Name:',
                            style: TextStyle(
                              color: controller.isDarkMode.value == false
                                  ? AppColor.textColor
                                  : AppColor.whiteColor,
                              fontSize: 14.sp,
                              fontFamily: 'Nunito Sans',
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          SizedBox(height: 4.h),
                          InputTextWidget(
                            textEditingController:
                                profileController.firstnameController,
                            hintText: 'Enter your first name',
                            onChanged: (value) {
                              profileController.firstname.value = value;
                            },
                            backgroundColor:
                                controller.isDarkMode.value == false
                                ? AppColor.backgroundColor
                                : AppColor.darkThemeColor,
                            textColor: controller.isDarkMode.value == false
                                ? AppColor.textColor
                                : AppColor.whiteColor,
                          ),
                          SizedBox(height: 16.h),
                          Text(
                            'Last Name:',
                            style: TextStyle(
                              color: controller.isDarkMode.value == false
                                  ? AppColor.textColor
                                  : AppColor.whiteColor,
                              fontSize: 14.sp,
                              fontFamily: 'Nunito Sans',
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          SizedBox(height: 4.h),
                          InputTextWidget(
                            textEditingController:
                                profileController.lastNameController,
                            hintText: 'Enter your last name',

                            onChanged: (value) => (),
                            backgroundColor:
                                controller.isDarkMode.value == false
                                ? AppColor.backgroundColor
                                : AppColor.darkThemeColor,
                            textColor: controller.isDarkMode.value == false
                                ? AppColor.textColor
                                : AppColor.whiteColor,
                          ),
                          SizedBox(height: 16.h),
                          Text(
                            'Email:',
                            style: TextStyle(
                              color: controller.isDarkMode.value == false
                                  ? AppColor.textColor
                                  : AppColor.whiteColor,
                              fontSize: 14.sp,
                              fontFamily: 'Nunito Sans',
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          SizedBox(height: 4.h),
                          InputTextWidget(
                            readOnly: true,
                            textEditingController:
                                profileController.emailController,
                            hintText: 'Enter your e-mail address',

                            onChanged: (value) => (),
                            backgroundColor:
                                controller.isDarkMode.value == false
                                ? AppColor.backgroundColor
                                : AppColor.darkThemeColor,
                            textColor: controller.isDarkMode.value == false
                                ? AppColor.textColor
                                : AppColor.whiteColor,
                          ),
                          SizedBox(height: 16.h),
                          Text(
                            'Mobile Number (Optional):',
                            style: TextStyle(
                              color: controller.isDarkMode.value == false
                                  ? AppColor.textColor
                                  : AppColor.whiteColor,
                              fontSize: 14.sp,
                              fontFamily: 'Nunito Sans',
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          SizedBox(height: 4.h),
                          InputTextWidget(
                            textEditingController:
                                profileController.mobileController,
                            hintText: 'Enter your phone number (optional)',

                            onChanged: (value) => (),
                            backgroundColor:
                                controller.isDarkMode.value == false
                                ? AppColor.backgroundColor
                                : AppColor.darkThemeColor,
                            textColor: controller.isDarkMode.value == false
                                ? AppColor.textColor
                                : AppColor.whiteColor,
                          ),
                          SizedBox(height: 16.h),
                        ],
                      ),
                    ),
                  ),
                  Obx(
                    () => CustomButton(
                      title: 'Save',
                      onPress: profileController.isLoading.value
                          ? null
                          : profileController.updateProfile,
                      loading: profileController.isLoading.value,
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildImageContent(File? pickedImage, String networkUrl) {
    if (pickedImage != null) {
      return Image.file(
        pickedImage,
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) => _errorAsset(),
      );
    }

    if (networkUrl.isNotEmpty) {
      return CachedNetworkImage(
        imageUrl: networkUrl,
        fit: BoxFit.cover,
        placeholder: (context, url) => Shimmer.fromColors(
          baseColor: Colors.grey[300]!,
          highlightColor: Colors.grey[100]!,
          child: Container(color: Colors.white),
        ),
        errorWidget: (context, url, error) => _errorAsset(),
      );
    }

    return _errorAsset();
  }

  Widget _errorAsset() {
    return Container(
      color: AppColor.defaultColor.withAlpha(26),
      child: SvgPicture.asset(ImageAssets.img, fit: BoxFit.cover),
    );
  }
}
