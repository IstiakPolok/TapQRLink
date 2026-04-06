import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:purchases_flutter/models/package_wrapper.dart';
import 'package:qr_code/res/colors/app_color.dart';

import '../controllers/settings_controller.dart';

class PaywallPage extends GetView<SettingsController> {
  final String title;
  final String description;
  final List<Package> packages;
  final ValueChanged<Package> onPackageSelected;
  const PaywallPage({
    super.key,
    required this.title,
    required this.description,
    required this.packages,
    required this.onPackageSelected,
  });

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<SettingsController>();
    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.75,
      ),
      child: Obx(() {
        final currentOffering = controller.offerings.value?.current;
        if (currentOffering == null) {
          return Center(child: CircularProgressIndicator());
        }
        return SingleChildScrollView(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 15.w),
            child: Column(
              children: [
                Text(title),
                SizedBox(height: 10.h),
                Text(description),
                SizedBox(height: 20.h),
                buildPackageList(),
              ],
            ),
          ),
        );
      }),
    );
  }

  Widget buildPackageList() => ListView.builder(
    shrinkWrap: true,
    primary: false,
    itemCount: packages.length,
    itemBuilder: (context, index) {
      final package = packages[index];
      return buildPackage(context, package);
    },
  );
  Card buildPackage(BuildContext context, Package package) {
    return Card(
      color: AppColor.defaultColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.r)),
      child: Theme(
        data: ThemeData.light(),
        child: ListTile(
          contentPadding: EdgeInsets.all(10.r),
          title: Text(
            package.storeProduct.title,
            style: TextStyle(
              color: AppColor.whiteColor,
              fontSize: 16.sp,
              fontFamily: 'Nunito Sans',
              fontWeight: FontWeight.w700,
            ),
          ),
          subtitle: Text(
            package.storeProduct.description,
            style: TextStyle(
              color: AppColor.whiteColor,
              fontSize: 12.sp,
              fontFamily: 'Nunito Sans',
              fontWeight: FontWeight.w500,
            ),
          ),
          trailing: Text(
            package.storeProduct.priceString,
            style: TextStyle(
              color: AppColor.whiteColor,
              fontSize: 16.sp,
              fontFamily: 'Nunito Sans',
              fontWeight: FontWeight.w700,
            ),
          ),
          onTap: () => onPackageSelected(package),
        ),
      ),
    );
  }
}
