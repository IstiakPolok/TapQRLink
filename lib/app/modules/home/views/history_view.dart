import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:shimmer/shimmer.dart';

import '../../../../res/assets/image_assets.dart';
import '../../../../res/colors/app_color.dart';
import '../../auth/controllers/auth_controller.dart';
import '../../settings/controllers/revenue_cat_controller.dart';
import '../../settings/views/subscription_view.dart';
import '../controllers/home_controller.dart';

class HistoryView extends GetView<HomeController> {
  final AuthController authController = Get.find();
  final RevenueCatController revenueCatController = Get.find();
  final ScrollController _scrollController = ScrollController();

  HistoryView({super.key}) {
    _scrollController.addListener(() {
      if (_scrollController.position.pixels >=
          _scrollController.position.maxScrollExtent - 100) {
        if (!controller.isLoading.value &&
            controller.nextPageUrl.value != null) {
          debugPrint("Fetching next page: ${controller.nextPageUrl.value}");
          controller.fetchHistory(isLoadMore: true);
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      authController.isLoggedIn.value ||
              authController.isSignedIn.value && controller.historyItems.isEmpty
          ? controller.fetchHistory()
          : controller.loadHistory();
    });

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.all(20.sp),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              SizedBox(height: 20.h),
              Center(
                child: Text(
                  'History',
                  style: TextStyle(
                    color: Get.isDarkMode
                        ? AppColor.whiteColor
                        : AppColor.textColor,
                    fontSize: 24.sp,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              SizedBox(height: 50.h),
              Expanded(
                child: Obx(() {
                  bool isUserLoggedIn =
                      authController.isLoggedIn.value ||
                      authController.isSignedIn.value;

                  if (isUserLoggedIn) {
                    return _buildAuthenticatedList();
                  } else {
                    return _buildGuestList();
                  }
                }),
              ),
              _buildPremiumPromo(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAuthenticatedList() {
    if (controller.isLoading.value && controller.historyItems.isEmpty) {
      return ListView.builder(
        itemCount: 8,
        itemBuilder: (_, _) => _historyShimmer(),
      );
    }

    if (controller.historyItems.isEmpty) {
      return const Center(child: Text('No scan history available'));
    }

    return ListView.builder(
      controller: _scrollController,
      itemCount:
          controller.historyItems.length +
          (controller.nextPageUrl.value != null ? 1 : 0),
      itemBuilder: (context, index) {
        if (index < controller.historyItems.length) {
          final history = controller.historyItems[index];
          return historyWidget(
            history.link,
            DateFormat('hh.mm a, dd MMMM yyyy').format(history.scannedAt),
            history.image ?? '',
            () => controller.showHistoryDetails(history.id),
            () => deleteDialog(history.id.toString()),
            history.isRead,
          );
        } else {
          return _historyShimmer();
        }
      },
    );
  }

  Widget _buildGuestList() {
    if (controller.historyList.isEmpty) {
      return const Center(child: Text('No scan history available'));
    }
    return ListView.builder(
      itemCount: controller.historyList.length,
      itemBuilder: (context, index) {
        final item = controller.historyList[index];
        final scannedAt = DateTime.parse(item['scanned_at']);
        return historyWidget(
          item['link'],
          DateFormat('hh:mm a, dd MMMM yyyy').format(scannedAt),
          null,
          () {},
          () => deleteDialog(item['id'].toString()),
          false,
        );
      },
    );
  }

  Widget _historyShimmer() {
    return Shimmer.fromColors(
      baseColor: Get.isDarkMode ? Colors.grey[800]! : Colors.grey[300]!,
      highlightColor: Get.isDarkMode ? Colors.grey[700]! : Colors.grey[100]!,
      child: Padding(
        padding: EdgeInsets.only(bottom: 12.h),
        child: Row(
          children: [
            Container(
              width: 62.w,
              height: 62.h,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8.r),
              ),
            ),
            SizedBox(width: 10.w),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(width: 150.w, height: 14.h, color: Colors.white),
                SizedBox(height: 6.h),
                Container(width: 100.w, height: 12.h, color: Colors.white),
              ],
            ),
          ],
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
      child: Container(
        margin: EdgeInsets.only(bottom: 12.h),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  width: 62.w,
                  height: 62.h,
                  padding: EdgeInsets.all(6.sp),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.white),
                    borderRadius: BorderRadius.circular(8.r),
                  ),
                  child: image != null
                      ? Image.network(
                          image,
                          loadingBuilder: (context, child, loadingProgress) {
                            if (loadingProgress == null) return child;
                            return _shimmerBox();
                          },
                        )
                      : (link.isEmpty)
                      ? _shimmerBox()
                      : QrImageView(
                          data: link,
                          version: QrVersions.auto,
                          size: 50,
                          eyeStyle: const QrEyeStyle(color: Colors.white),
                          dataModuleStyle: const QrDataModuleStyle(
                            color: Colors.white,
                          ),
                        ),
                ),
                SizedBox(width: 10.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'QR Code Scanned',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 14.sp,
                        ),
                      ),
                      Text(
                        time,
                        style: TextStyle(fontSize: 12.sp, color: Colors.grey),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: onDelete,
                  icon: SvgPicture.asset(ImageAssets.delete, width: 24.w),
                ),
              ],
            ),
            const Divider(),
          ],
        ),
      ),
    );
  }

  Widget _shimmerBox() {
    return Shimmer.fromColors(
      baseColor: Get.isDarkMode ? Colors.grey[800]! : Colors.grey[300]!,
      highlightColor: Get.isDarkMode ? Colors.grey[700]! : Colors.grey[100]!,
      child: Container(
        width: 50,
        height: 50,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(4.r),
        ),
      ),
    );
  }

  void deleteDialog(String id) {
    Get.dialog(
      AlertDialog(
        content: const Text('Are you sure you want to delete this?'),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              Get.back();
              controller.deleteHistory(int.parse(id));
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  Widget _buildPremiumPromo() {
    if (revenueCatController.renewalDate.isNotEmpty) {
      return const SizedBox.shrink();
    }
    return Column(
      children: [
        SizedBox(height: 10.h),
        Text(
          'Scan History – Free Access Limited to 3 Scans',
          textAlign: TextAlign.center,
        ),
        TextButton(
          onPressed: () => Get.to(SubscriptionView()),
          child: Text(
            'Get Premium',
            style: TextStyle(decoration: TextDecoration.underline),
          ),
        ),
      ],
    );
  }
}
