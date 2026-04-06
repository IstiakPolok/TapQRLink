import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';

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
                              children: [
                                Obx(() {
                                  profileController.pickedImage.value =
                                      as.pickedImage.value;
                                  final pickedImage =
                                      profileController.pickedImage.value;
                                  return ClipRRect(
                                    borderRadius: BorderRadius.circular(200.r),
                                    child: pickedImage != null
                                        ? Image.file(
                                            pickedImage,
                                            width: 120.w,
                                            height: 120.w,
                                            fit: BoxFit.cover,
                                            errorBuilder:
                                                (context, error, stackTrace) {
                                                  return SvgPicture.asset(
                                                    ImageAssets.img,
                                                    width: 120.w,
                                                    height: 120.w,
                                                    fit: BoxFit.cover,
                                                  );
                                                },
                                          )
                                        : profileController
                                              .profile
                                              .value!
                                              .profilePicture
                                              .isNotEmpty
                                        ? Container(
                                            width: 120.w,
                                            height: 120.w,
                                            color: AppColor.defaultColor,
                                            child: Image.network(
                                              profileController
                                                  .profile
                                                  .value!
                                                  .profilePicture,
                                              fit: BoxFit.cover,
                                            ),
                                          )
                                        : Container(
                                            width: 120.w,
                                            height: 120.w,
                                            color: AppColor.defaultColor,
                                            child: SvgPicture.asset(
                                              ImageAssets.img,
                                              fit: BoxFit.cover,
                                            ),
                                          ),
                                  );
                                }),
                                Positioned(
                                  bottom: 0.h,
                                  right: 0.w,
                                  child: Container(
                                    width: 30.w,
                                    height: 30.w,
                                    decoration: BoxDecoration(
                                      color: AppColor.buttonColor,
                                      borderRadius: BorderRadius.circular(
                                        100.r,
                                      ),
                                    ),
                                    child: Center(
                                      child: IconButton(
                                        icon: Icon(
                                          Icons.camera_alt,
                                          size: 18.sp,
                                          color:
                                              controller.isDarkMode.value ==
                                                  false
                                              ? AppColor.backgroundColor
                                              : AppColor.darkThemeColor,
                                        ),
                                        onPressed: as.getBottomSheet,
                                        padding: EdgeInsets.all(4.w),
                                        constraints: BoxConstraints(),
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
                            'Mobile Number:',
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
                            hintText: 'Enter your phone number',

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
}
