import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:get/get.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:mobile_scanner/mobile_scanner.dart' as ms;
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../../../res/assets/image_assets.dart';
import '../../../../res/colors/app_color.dart';
import '../../../../widgets/custom_button.dart';
import '../../../routes/app_pages.dart';
import '../../auth/controllers/auth_controller.dart';
import '../../settings/controllers/revenue_cat_controller.dart';
import '../../settings/controllers/settings_controller.dart';
import '../../settings/views/subscription_view.dart';
import '../controllers/home_controller.dart';
import 'qr_code_view.dart';

class HomeView extends GetView<HomeController> {
  const HomeView({super.key});

  @override
  Widget build(BuildContext context) {
    final SettingsController settingsController = Get.find();
    final AuthController authController = Get.find();
    final revenueCatController = Get.put(RevenueCatController());
    controller.getCheckPopup();
    Future.delayed(const Duration(seconds: 1), () async {
      if (!controller.popups.value) {
        showPaymentDialog();
      }
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      controller.loadBanner();
    });
    debugPrint('Popups value: ${controller.popups.value}');
    debugPrint('renewalDate value: ${revenueCatController.renewalDate}');
    return Obx(
      () => Scaffold(
        backgroundColor: settingsController.isDarkMode.value
            ? AppColor.darkThemeColor
            : AppColor.backgroundColor,
        body: SafeArea(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 20.w),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    SizedBox(height: 20.h),
                    Obx(() {
                      bool showAd =
                          revenueCatController.renewalDate.isEmpty &&
                          controller.isBannerLoaded.value &&
                          controller.bannerAd != null;

                      if (showAd) {
                        return Container(
                          alignment: Alignment.center,
                          width: controller.bannerAd!.size.width.toDouble(),
                          height: controller.bannerAd!.size.height.toDouble(),
                          child: AdWidget(
                            key: Key(controller.bannerAd.hashCode.toString()),
                            ad: controller.bannerAd!,
                          ),
                        );
                      }
                      return const SizedBox.shrink();
                    }),
                    SizedBox(height: 15.h),
                    Obx(() {
                      if (revenueCatController.renewalDate.isEmpty) {
                        return CustomButton(
                          onPress: () async {
                            authController.isSignedIn.value ||
                                    authController.isLoggedIn.value
                                ? Get.to(SubscriptionView())
                                : Get.toNamed(Routes.auth);
                          },
                          title: 'Remove Ads',
                          fontSize: 10,
                          buttonColor: settingsController.isDarkMode.value
                              ? AppColor.default40Color
                              : AppColor.backgroundColor,
                          textColor: settingsController.isDarkMode.value
                              ? AppColor.whiteColor
                              : AppColor.defaultColor,
                          borderColor: settingsController.isDarkMode.value
                              ? AppColor.default40Color
                              : AppColor.defaultColor,
                          width: 102.w,
                          height: 24.h,
                        );
                      }
                      return const SizedBox.shrink();
                    }),
                    SizedBox(height: 15.h),
                  ],
                ),
                Obx(
                  () => controller.isScanning.value
                      ? Expanded(
                          child: Container(
                            color: settingsController.isDarkMode.value
                                ? AppColor.darkThemeColor
                                : AppColor.whiteColor,
                            child: MobileScanner(
                              controller: controller.mobileScannerController,
                              onDetect: (ms.BarcodeCapture capture) {
                                for (final b in capture.barcodes) {
                                  final code = b.rawValue;
                                  if (code != null && code.isNotEmpty) {
                                    controller.qrCode.value = code;
                                    controller.stopScanning();
                                    Get.snackbar('QR Code Scanned', code);
                                    Get.to(() => const QrCodeView());
                                    break;
                                  }
                                }
                              },
                            ),
                          ),
                        )
                      : SizedBox(
                          height: .4.sh,
                          width: .8.sw,
                          child: Obx(() {
                            return controller.selectedImage.value;
                          }),
                        ),
                ),
                Column(
                  children: [
                    SizedBox(height: 15.h),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        IconButton(
                          icon: Icon(Icons.remove, size: 25.sp),
                          onPressed: () => controller.decreaseValue(),
                          color: settingsController.isDarkMode.value
                              ? AppColor.whiteColor
                              : AppColor.blackColor,
                        ),
                        SizedBox(
                          width: 225.w,
                          child: Obx(
                            () => Slider(
                              value: controller.sliderValue.value,
                              min: 0,
                              max: 100,
                              onChanged: (value) =>
                                  controller.updateSliderValue(value),
                              activeColor: settingsController.isDarkMode.value
                                  ? AppColor.whiteColor
                                  : AppColor.blackColor,
                              inactiveColor: settingsController.isDarkMode.value
                                  ? AppColor.white30Color
                                  : AppColor.inactiveColor,
                            ),
                          ),
                        ),
                        IconButton(
                          icon: Icon(Icons.add, size: 25.sp),
                          onPressed: () => controller.increaseValue(),
                          color: settingsController.isDarkMode.value
                              ? AppColor.whiteColor
                              : AppColor.blackColor,
                        ),
                      ],
                    ),
                    SizedBox(height: 15.h),
                    Obx(
                      () => GestureDetector(
                        onTap: () async {
                          if (controller.isScanning.value ||
                              controller.isScanning1.value) {
                            controller.stopScanning();
                            await controller.cancelScanning();
                          } else {
                            await controller.startScanning();
                          }
                        },
                        child: Container(
                          width: 160.w,
                          height: 32.h,
                          padding: EdgeInsets.symmetric(horizontal: 10.w),
                          decoration: ShapeDecoration(
                            color: AppColor.containerColor3,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(24.r),
                            ),
                          ),
                          child: Row(
                            spacing: 5.w,
                            children: [
                              Icon(
                                Icons.camera_alt_outlined,
                                color: AppColor.textColor1,
                              ),
                              SizedBox(
                                width: 110.w,
                                child: Text(
                                  controller.isScanning.value ||
                                          controller.isScanning1.value
                                      ? 'Cancel Scanning'
                                      : 'Start Scanning',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: AppColor.textColor1,
                                    fontSize: 14.sp,
                                    fontFamily: 'Nunito Sans',
                                    fontWeight: FontWeight.w400,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    SizedBox(height: 15.h),
                    CustomButton(
                      onPress: () async {
                        debugPrint(
                          'Ad Click Count: ${controller.adClickCount.value}',
                        );

                        bool isPremium =
                            (authController.isLoggedIn.value ||
                                authController.isSignedIn.value) &&
                            revenueCatController.renewalDate.isNotEmpty;

                        if (controller.adClickCount.value > 0 &&
                            !isPremium &&
                            controller.adClickCount.value <= 2) {
                          debugPrint('Showing Interstitial Ad');
                          controller.showInterstitial();
                        }
                        controller.handleScan();
                      },
                      title: 'Scan Images',
                      leading: true,
                      leadingIcon: ImageAssets.file,
                      loading: controller.isLoading.value,
                    ),
                    SizedBox(height: 20.h),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

void showPaymentDialog() async {
  final FlutterSecureStorage storage = const FlutterSecureStorage();
  final SettingsController settingsController = Get.find();
  final HomeController controller = Get.find();
  Get.dialog(
    AlertDialog(
      backgroundColor: settingsController.isDarkMode.value
          ? AppColor.darkThemeColor
          : AppColor.containerColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
      contentPadding: EdgeInsets.all(12.sp),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Payment Information',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: settingsController.isDarkMode.value
                  ? AppColor.whiteColor
                  : AppColor.textColor,
              fontSize: 16.sp,
              fontFamily: 'Nunito Sans',
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 8.h),
          Text(
            'Would you like to upgrade to premium?',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: settingsController.isDarkMode.value
                  ? AppColor.whiteColor
                  : AppColor.textColor,
              fontSize: 14.sp,
              fontFamily: 'Nunito Sans',
              fontWeight: FontWeight.w400,
            ),
          ),
          SizedBox(height: 16.h),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              CustomButton(
                onPress: () async {
                  storage.write(key: 'popup', value: 'true');
                  Navigator.of(Get.context!).pop();
                  showTapQRLinkDialog();
                },
                title: 'Cancel',
                textColor: AppColor.defaultColor,
                height: 32,
                width: 84,
                fontSize: 12,
                borderColor: AppColor.defaultColor,
                buttonColor: settingsController.isDarkMode.value
                    ? AppColor.darkThemeColor
                    : AppColor.backgroundColor,
              ),
              CustomButton(
                onPress: () async {
                  storage.write(key: 'popup', value: 'true');
                  Navigator.of(Get.context!).pop();
                  controller.isPlane.toggle();
                  showTapQRLinkDialog();
                },
                title: 'Continue',
                height: 32,
                width: 84,
                fontSize: 12,
                buttonColor: settingsController.isDarkMode.value
                    ? AppColor.default40Color
                    : AppColor.backgroundColor,
                textColor: settingsController.isDarkMode.value
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

void showTapQRLinkDialog() async {
  final SettingsController settingsController = Get.find();
  Get.dialog(
    AlertDialog(
      backgroundColor: settingsController.isDarkMode.value
          ? AppColor.darkThemeColor
          : AppColor.containerColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
      contentPadding: EdgeInsets.all(12.sp),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'TapQRLink – Would Like to\nAccess Your Photo Library',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: settingsController.isDarkMode.value
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
                  Navigator.of(Get.context!).pop();
                  showGuideDialog();
                },
                title: 'Cancel',
                textColor: AppColor.defaultColor,
                height: 32,
                width: 84,
                fontSize: 12,
                buttonColor: settingsController.isDarkMode.value
                    ? AppColor.darkThemeColor
                    : AppColor.backgroundColor,
              ),
              CustomButton(
                onPress: () async {
                  Navigator.of(Get.context!).pop();
                  showGuideDialog();
                },
                title: 'Allow',
                height: 32,
                width: 84,
                fontSize: 12,
                buttonColor: settingsController.isDarkMode.value
                    ? AppColor.default40Color
                    : AppColor.backgroundColor,
                textColor: settingsController.isDarkMode.value
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

void showGuideDialog() async {
  final SettingsController settingsController = Get.find();
  final HomeController controller = Get.find();
  Get.dialog(
    AlertDialog(
      backgroundColor: settingsController.isDarkMode.value
          ? AppColor.darkThemeColor
          : AppColor.containerColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
      contentPadding: EdgeInsets.all(12.sp),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Do you want help\ngetting started?',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: settingsController.isDarkMode.value
                  ? AppColor.whiteColor
                  : AppColor.textColor,
              fontSize: 16.sp,
              fontFamily: 'Nunito Sans',
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 16.h),
          Text(
            'Choose a quick guide or\njump right in.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: settingsController.isDarkMode.value
                  ? AppColor.whiteColor
                  : AppColor.textColor,
              fontSize: 14.sp,
              fontFamily: 'Nunito Sans',
              fontWeight: FontWeight.w400,
            ),
          ),
          SizedBox(height: 16.h),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              CustomButton(
                onPress: () async {
                  Navigator.of(Get.context!).pop();
                  if (controller.isPlane.value == true) {
                    Get.toNamed(Routes.auth);
                  }
                },
                title: 'Skip',
                textColor: AppColor.defaultColor,
                height: 32,
                width: 84,
                fontSize: 12,
                borderColor: AppColor.defaultColor,
                buttonColor: settingsController.isDarkMode.value
                    ? AppColor.darkThemeColor
                    : AppColor.backgroundColor,
              ),
              Obx(
                () => CustomButton(
                  onPress: () async {
                    controller.fetchGuides();
                  },
                  title: 'Take Guide',
                  height: 32,
                  width: 104,
                  fontSize: 12,
                  buttonColor: settingsController.isDarkMode.value
                      ? AppColor.default40Color
                      : AppColor.backgroundColor,
                  textColor: settingsController.isDarkMode.value
                      ? AppColor.whiteColor
                      : AppColor.defaultColor,
                ),
              ),
            ],
          ),
        ],
      ),
    ),
  );
}
