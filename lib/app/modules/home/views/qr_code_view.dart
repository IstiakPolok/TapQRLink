import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../res/assets/image_assets.dart';
import '../../../../res/colors/app_color.dart';
import '../../../../widgets/show_custom_snack_bar.dart';
import '../controllers/home_controller.dart';

class QrCodeView extends GetView<HomeController> {
  const QrCodeView({super.key});
  @override
  Widget build(BuildContext context) {
    final String qrCodeLink = controller.qrCode.value;
    controller.onQrCodeScanned(qrCodeLink);
    debugPrint('QR code history saved');
    return Scaffold(
      body: Stack(
        children: [
          SizedBox(
            height: 1.sh,
            width: 1.sw,
            child: Image.asset(ImageAssets.bg, fit: BoxFit.cover),
          ),
          Positioned(
            top: 50.h,
            left: 10.w,
            child: InkWell(
              onTap: () {
                controller.changePage(0);
                Navigator.pop(Get.context!);
              },
              child: SvgPicture.asset(
                ImageAssets.backward,
                width: 25.w,
                height: 25.h,
                colorFilter: ColorFilter.mode(
                  AppColor.whiteColor,
                  BlendMode.srcIn,
                ),
              ),
            ),
          ),
          Positioned(
            top: 55.h,
            left: 20.w,
            child: SafeArea(
              child: SizedBox(
                width: 1.sw - 40.w,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    SizedBox(
                      width: 236.w,
                      child: Text(
                        'QR Code Scanned Successfully',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: AppColor.whiteColor,
                          fontSize: 28.sp,
                          fontFamily: 'Nunito Sans',
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    SizedBox(height: 10.h),
                    SizedBox(
                      width: 282.w,
                      child: Text(
                        'Decode Link:',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: AppColor.whiteColor,
                          fontSize: 24.sp,
                          fontFamily: 'Nunito Sans',
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    SizedBox(height: 10.h),
                    InkWell(
                      onTap: _launchLink,
                      child: Container(
                        width: 272.w,
                        height: 43.h,
                        padding: EdgeInsets.symmetric(
                          horizontal: 10.w,
                          vertical: 5.h,
                        ),
                        decoration: ShapeDecoration(
                          color: AppColor.containerColor6,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20.r),
                          ),
                        ),
                        child: SizedBox(
                          width: 272.w,
                          height: 43.h,
                          child: Text(
                            controller.qrCode.value.isEmpty
                                ? 'No QR Code Data'
                                : controller.qrCode.value,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: AppColor.whiteColor,
                              fontSize: 20.sp,
                              fontFamily: 'Nunito Sans',
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ),
                    SizedBox(height: 30.h),
                    Obx(
                      () => controller.qrCode.value.isEmpty
                          ? Container(
                              width: 278.w,
                              height: 282.h,
                              color: Colors.grey,
                              child: Center(
                                child: Text(
                                  'No Qr Code Data',
                                  style: TextStyle(
                                    fontSize: 16.sp,
                                    color: Get.isDarkMode
                                        ? AppColor.whiteColor
                                        : AppColor.textColor,
                                  ),
                                ),
                              ),
                            )
                          : QrImageView(
                              data: controller.qrCode.value,
                              version: QrVersions.auto,
                              size: 278.w,
                              backgroundColor: Colors.white,
                              padding: EdgeInsets.all(8.sp),
                            ),
                    ),
                    SizedBox(height: 20.h),
                    SizedBox(
                      width: 247.w,
                      child: Text(
                        'Tap the link to open',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: AppColor.whiteColor,
                          fontSize: 18.sp,
                          fontFamily: 'Nunito Sans',
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    SizedBox(height: 50.h),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        GestureDetector(
                          onTap: () {
                            controller.changePage(0);
                            controller.startScanning();
                            Navigator.pop(Get.context!);
                          },
                          child: Container(
                            width: 104.w,
                            height: 40.h,
                            decoration: ShapeDecoration(
                              color: AppColor.containerColor5,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8.r),
                              ),
                            ),
                            child: Center(
                              child: Text(
                                'Rescan',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: AppColor.textColor,
                                  fontSize: 14.sp,
                                  fontFamily: 'Nunito Sans',
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                        ),
                        GestureDetector(
                          onTap: () {
                            if (controller.qrCode.value.isNotEmpty) {
                              controller.copyToClipboard(
                                controller.qrCode.value,
                              );
                            } else {
                              showCustomSnackBar(
                                title: 'Error',
                                message: 'No QR code data to copy',
                                isSuccess: false,
                              );
                            }
                          },
                          child: Container(
                            width: 104.w,
                            height: 40.h,
                            decoration: ShapeDecoration(
                              color: AppColor.containerColor5,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8.r),
                              ),
                            ),
                            child: Center(
                              child: Text(
                                'Copy Link',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: AppColor.textColor,
                                  fontSize: 14.sp,
                                  fontFamily: 'Nunito Sans',
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                        ),
                        GestureDetector(
                          onTap: () {
                            controller.changePage(0);
                            Navigator.pop(Get.context!);
                          },
                          child: Container(
                            width: 104.w,
                            height: 40.h,
                            decoration: ShapeDecoration(
                              color: AppColor.containerColor5,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8.r),
                              ),
                            ),
                            child: Center(
                              child: Text(
                                'Cancel',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: AppColor.textColor,
                                  fontSize: 14.sp,
                                  fontFamily: 'Nunito Sans',
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
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
          ),
        ],
      ),
    );
  }

  Future<void> _launchLink() async {
    final Uri linkLaunchUri = Uri.parse(controller.qrCode.value);

    if (await canLaunchUrl(linkLaunchUri)) {
      await launchUrl(linkLaunchUri);
    } else {
      await launchUrl(Uri.parse(controller.qrCode.value));
    }
  }
}
