import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';
import '../res/assets/image_assets.dart';
import '../res/colors/app_color.dart';

class InputTextController extends GetxController {
  final RxBool isObscured;
  final TextEditingController textController;
  final bool _isInternalController;

  InputTextController({
    required this.textController,
    required bool obscureText,
    bool isInternalController = false,
  }) : isObscured = obscureText.obs,
       _isInternalController = isInternalController;

  void toggleObscure() {
    isObscured.value = !isObscured.value;
  }

  void updateText(String text) {
    textController.text = text;
  }

  @override
  void onClose() {
    if (_isInternalController) {
      textController.dispose();
    }
    super.onClose();
  }
}

class InputTextWidget extends StatelessWidget {
  const InputTextWidget({
    super.key,
    this.hintText = '',
    this.backicontap2,
    this.backicontap,
    required this.onChanged,
    this.onTap,
    this.validator,
    this.obscureText = false,
    this.readOnly = false,
    this.leading = false,
    this.backIcon = false,
    this.backIcon2 = false,
    this.textAlign = false,
    this.leadingIcon = ImageAssets.scan,
    this.imageIcon = '',
    this.backimage = '',
    this.backimagetap,
    this.backimageadd = false,
    this.contentPadding = false,
    this.clock = false,
    this.shadow = false,
    this.linearGradient = false,
    this.passwordIcon = '',
    this.borderRadius = 8.0,
    this.borderColor = AppColor.borderColor,
    this.keyboardType = TextInputType.text,
    this.hintTextColor = AppColor.greyColor,
    this.borderShadowColor = AppColor.borderColor,
    this.textColor = AppColor.textColor,
    this.leadingHeight = 14.0,
    this.leadingWidth = 17.0,
    this.height = 40.0,
    this.width = double.infinity,
    this.hintfontFamily = 'Nunito Sans',
    this.hintfontSize = 12.0,
    this.hintfontWeight = FontWeight.w500,
    this.fontSize = 16.0,
    this.fontWeight = FontWeight.w700,
    this.fontFamily = 'Nunito Sans',
    this.vertical = 5.0,
    this.horizontal = 0.0,
    this.leadingright = 0.0,
    this.leadingtop = 0.0,
    this.leadingleft = 0.0,
    this.backimagewidth = 24.0,
    this.backimageheight = 24.0,
    this.borderWidth = .5,
    this.backgroundColor = AppColor.backgroundColor,
    this.leadingColor = AppColor.greyColor,
    this.maxLines = 1,
    this.textEditingController,
    this.settingsIconWidget,
  });

  final String hintText, hintfontFamily, fontFamily;
  final double borderRadius,
      fontSize,
      hintfontSize,
      leadingHeight,
      leadingWidth,
      leadingright,
      leadingtop,
      leadingleft,
      backimagewidth,
      backimageheight;
  final Color borderColor,
      textColor,
      hintTextColor,
      backgroundColor,
      leadingColor,
      borderShadowColor;
  final double height, width, horizontal, vertical, borderWidth;
  final bool obscureText,
      readOnly,
      contentPadding,
      leading,
      clock,
      backIcon,
      backIcon2,
      backimageadd,
      linearGradient,
      shadow,
      textAlign;
  final String passwordIcon, leadingIcon, imageIcon, backimage;
  final ValueChanged<String> onChanged;
  final VoidCallback? onTap, backicontap, backicontap2, backimagetap;
  final String? Function(String?)? validator;
  final FontWeight fontWeight, hintfontWeight;
  final int maxLines;
  final TextEditingController? textEditingController;
  final Widget? settingsIconWidget;
  final TextInputType keyboardType;

  @override
  Widget build(BuildContext context) {
    final inputController = Get.put(
      InputTextController(
        textController: textEditingController ?? TextEditingController(),
        obscureText: obscureText,
        isInternalController: textEditingController == null,
      ),
      tag: key?.toString() ?? UniqueKey().toString(),
    );

    return Container(
      height: height.h, // Reduced height for all Android versions
      width: width == double.infinity ? double.infinity : width.w,
      decoration: shadow
          ? ShapeDecoration(
              color: backgroundColor,
              shape: RoundedRectangleBorder(
                side: BorderSide(width: borderWidth.w, color: borderColor),
                borderRadius: BorderRadius.circular(borderRadius.r),
              ),
              shadows: [
                BoxShadow(
                  color: borderShadowColor,
                  blurRadius: 4,
                  offset: Offset(0, 0),
                  spreadRadius: 0,
                ),
              ],
            )
          : ShapeDecoration(
              color: backgroundColor,
              shape: RoundedRectangleBorder(
                side: BorderSide(width: borderWidth.w, color: borderColor),
                borderRadius: BorderRadius.circular(borderRadius.r),
              ),
            ),
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 10.w),
        child: Row(
          mainAxisAlignment:
              MainAxisAlignment.center, // Centers children horizontally
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            if (leading)
              Padding(
                padding: EdgeInsets.only(
                  right: leadingright.w,
                  top: leadingtop.h,
                  left: leadingleft.w,
                ),
                child: SvgPicture.asset(
                  leadingIcon,
                  width: leadingWidth.w,
                  height: leadingHeight.h,
                  colorFilter: ColorFilter.mode(leadingColor, BlendMode.srcIn),
                ),
              ),
            Expanded(
              child: Obx(
                () => TextField(

                  keyboardType: keyboardType,
                  controller: inputController.textController,
                  onChanged: onChanged,
                  onTap: onTap,
                  readOnly: readOnly,
                  maxLines: 1,
                  textAlign: textAlign ? TextAlign.right : TextAlign.left,
                  obscureText: inputController.isObscured.value,
                  decoration: InputDecoration(
                    hintText: hintText,
                    hintStyle: TextStyle(
                      color: hintTextColor,
                      fontSize: hintfontSize.sp,
                      fontWeight: hintfontWeight,
                      fontFamily: hintfontFamily,
                    ),
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: contentPadding
                        ? EdgeInsets.symmetric(
                            horizontal: horizontal.w,
                            vertical: vertical.h,
                          )
                        : null,
                  ),
                  style: Theme.of(context).textTheme.titleMedium!.copyWith(
                    fontSize: fontSize.sp,
                    fontWeight: fontWeight,
                    fontFamily: fontFamily,
                    color: textColor,
                  ),
                ),
              ),
            ),
            if (obscureText)
              Obx(
                () => Padding(
                  padding: EdgeInsets.only(right: 10.w),
                  child: GestureDetector(
                    onTap: inputController.toggleObscure,
                    child: Icon(
                      inputController.isObscured.value
                          ? Icons.visibility_off
                          : Icons.visibility,
                      size: 22.sp,
                      color: hintTextColor,
                    ),
                  ),
                ),
              ),
            if (backIcon)
              Padding(
                padding: EdgeInsets.only(left: 10.w),
                child: GestureDetector(
                  onTap: backicontap,
                  child: settingsIconWidget ?? SvgPicture.asset(imageIcon),
                ),
              ),
            if (backIcon2)
              Padding(
                padding: EdgeInsets.only(left: 10.w),
                child: GestureDetector(
                  onTap: backicontap2,
                  child: SvgPicture.asset(imageIcon),
                ),
              ),
            if (backimageadd)
              GestureDetector(
                onTap: backimagetap,
                child: Image.asset(
                  backimage,
                  height: backimageheight.h,
                  width: backimagewidth.w,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
