import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../res/colors/app_color.dart';
import 'settings_controller.dart';

class BottomSheetController extends GetxController {
  final SettingsController settingsController = Get.find();
  final ImagePicker _picker = ImagePicker();
  Rxn<File> pickedImage = Rxn<File>();

  void getBottomSheet() {
    Get.bottomSheet(
      SafeArea(
        child: Container(
          margin: EdgeInsets.all(20.sp),
          height: 120.h,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(30.r),
            color: settingsController.isDarkMode.value == false
                ? AppColor.backgroundColor
                : AppColor.darkThemeColor,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                spacing: 10.h,
                children: [
                  Container(
                    width: 58.sp,
                    height: 58.sp,
                    decoration: BoxDecoration(
                      color: AppColor.buttonColor,
                      borderRadius: BorderRadius.circular(100.r),
                    ),
                    child: Center(
                      child: IconButton(
                        onPressed: () {
                          Navigator.pop(Get.context!);
                          _pickImage(ImageSource.camera);
                        },
                        icon: Icon(
                          Icons.camera_alt,
                          size: 32.sp,
                          color: settingsController.isDarkMode.value == false
                              ? AppColor.backgroundColor
                              : AppColor.darkThemeColor,
                        ),
                      ),
                    ),
                  ),
                  Text(
                    'Camera',
                    style: TextStyle(
                      fontSize: 16.sp,
                      color: AppColor.defaultColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                spacing: 10.h,
                children: [
                  Container(
                    width: 58.sp,
                    height: 58.sp,
                    decoration: BoxDecoration(
                      color: AppColor.buttonColor,
                      borderRadius: BorderRadius.circular(100.r),
                    ),
                    child: Center(
                      child: IconButton(
                        onPressed: () {
                          Navigator.pop(Get.context!);
                          _pickVideoOrImageFromGallery();
                        },
                        icon: Icon(
                          Icons.photo_library_rounded,
                          size: 32.sp,
                          color: settingsController.isDarkMode.value == false
                              ? AppColor.backgroundColor
                              : AppColor.darkThemeColor,
                        ),
                      ),
                    ),
                  ),
                  Text(
                    'Gallery',
                    style: TextStyle(
                      fontSize: 16.sp,
                      color: AppColor.defaultColor,
                      fontWeight: FontWeight.bold,
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

  Future<void> _pickImage(ImageSource source) async {
    final XFile? pickedFile = await _picker.pickImage(source: source);
    if (pickedFile != null) {
      pickedImage.value = File(pickedFile.path);
    }
  }

  Future<void> _pickVideoOrImageFromGallery() async {
    final XFile? file = await _picker.pickImage(source: ImageSource.gallery);
    if (file != null) {
      pickedImage.value = File(file.path);
    }
  }
}
