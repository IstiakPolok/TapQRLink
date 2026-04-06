import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/svg.dart';

import '../res/colors/app_color.dart';

class CustomButton extends StatelessWidget {
  const CustomButton({
    super.key,
    this.buttonColor = AppColor.defaultColor,
    this.buttonColor1 = AppColor.defaultLightColor,
    this.textColor = AppColor.whiteColor,
    this.subtextColor = AppColor.whiteColor,
    this.borderColor = Colors.transparent,
    this.trailingColor = false,
    this.borderShadowColor = const Color(0x1E000000),
    required this.onPress,
    this.height = 43,
    this.leadingIconHeight = 25,
    this.leadingIconWeight = 25,
    this.leadingPaddingLeft = 8,
    this.leadingPaddingRight = 8,
    this.trailingIconHeight = 25,
    this.trailingIconWeight = 25,
    this.trailingPaddingLeft = 8,
    this.trailingPaddingRight = 8,
    this.width = double.infinity,
    this.loading = false,
    this.center = true,
    this.leading = false,
    this.trailing = false,
    this.linearGradient = false,
    this.leadingIcon = '',
    this.trailingIcon = '',
    required this.title,
    this.fontSize = 16,
    this.fontWeight = FontWeight.w600,
    this.fontFamily = 'Nunito Sans',
    this.radius = 8,
    this.subtitle = '',
    this.subfontSize = 12,
    this.horizontal = 0,
    this.subfontWeight = FontWeight.w400,
    this.subfontFamily = 'Proxima Nova',
  });

  final bool loading, center, leading, linearGradient, trailing, trailingColor;
  final String title,
      subtitle,
      fontFamily,
      subfontFamily,
      leadingIcon,
      trailingIcon;
  final double height,
      fontSize,
      radius,
      subfontSize,
      width,
      leadingIconHeight,
      leadingIconWeight,
      leadingPaddingLeft,
      leadingPaddingRight,
      trailingIconHeight,
      trailingIconWeight,
      trailingPaddingLeft,
      trailingPaddingRight,
      horizontal;
  final Future<void> Function()? onPress;
  final Color textColor,
      subtextColor,
      buttonColor,
      buttonColor1,
      borderColor,
      borderShadowColor;
  final FontWeight fontWeight, subfontWeight;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: (onPress != null && !loading) ? () => onPress!() : null,
      child: Container(
        height: height.h,
        width: width.w,
        decoration:
            linearGradient
                ? ShapeDecoration(
                  gradient: LinearGradient(
                    begin: Alignment(1.00, -1.22),
                    end: Alignment(-0.20, 2.10),
                    colors: [buttonColor, buttonColor1],
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(radius.r),
                  ),
                )
                : ShapeDecoration(
                  color: buttonColor,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(radius.r),
                    side: BorderSide(color: borderColor,width: 1.w),
                  ),
                ),
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: horizontal.w),
          child:
              loading
                  ? Center(child: CircularProgressIndicator(color: textColor))
                  : center
                  ? Center(
                    child:
                        subtitle.isEmpty
                            ? Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                if (leading)
                                  Padding(
                                    padding: EdgeInsets.only(
                                      left: leadingPaddingLeft,
                                      right: leadingPaddingRight,
                                    ),
                                    child: SvgPicture.asset(
                                      leadingIcon,
                                      width: leadingIconWeight,
                                      height: leadingIconHeight,
                                    ),
                                  ),
                                Text(
                                  title,
                                  style: TextStyle(
                                    color: textColor,
                                    fontSize: fontSize.sp,
                                    fontWeight: fontWeight,
                                    fontFamily: fontFamily,
                                  ),
                                ),
                              ],
                            )
                            : Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                if (leading)
                                  Padding(
                                    padding: EdgeInsets.only(
                                      left: leadingPaddingLeft,
                                      right: leadingPaddingRight,
                                    ),
                                    child: SvgPicture.asset(
                                      leadingIcon,
                                      width: leadingIconWeight,
                                      height: leadingIconHeight,
                                    ),
                                  ),
                                Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      title,
                                      style: TextStyle(
                                        color: textColor,
                                        fontSize: fontSize.sp,
                                        fontWeight: fontWeight,
                                        fontFamily: fontFamily,
                                      ),
                                    ),
                                    Text(
                                      subtitle,
                                      style: TextStyle(
                                        color: subtextColor,
                                        fontSize: subfontSize.sp,
                                        fontWeight: subfontWeight,
                                        fontFamily: subfontFamily,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                  )
                  : Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      if (leading)
                        Padding(
                          padding: EdgeInsets.only(
                            left: leadingPaddingLeft,
                            right: leadingPaddingRight,
                          ),
                          child: SvgPicture.asset(
                            leadingIcon,
                            width: leadingIconWeight,
                            height: leadingIconHeight,
                          ),
                        ),
                      SizedBox(width: 10.w),
                      Expanded(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              title,
                              style: TextStyle(
                                color: textColor,
                                fontSize: fontSize.sp,
                                fontWeight: fontWeight,
                                fontFamily: fontFamily,
                              ),
                            ),
                            if (subtitle.isNotEmpty)
                              Text(
                                subtitle,
                                style: TextStyle(
                                  color: subtextColor,
                                  fontSize: subfontSize.sp,
                                  fontWeight: subfontWeight,
                                  fontFamily: subfontFamily,
                                ),
                              ),
                          ],
                        ),
                      ),
                      if (trailing)
                        Padding(
                          padding: EdgeInsets.only(
                            left: trailingPaddingLeft,
                            right: trailingPaddingRight,
                          ),
                          child: SvgPicture.asset(
                            colorFilter:
                                trailingColor
                                    ? ColorFilter.mode(
                                      AppColor.textColor,
                                      BlendMode.srcIn,
                                    )
                                    : null,
                            trailingIcon,
                            width: trailingIconWeight,
                            height: trailingIconHeight,
                          ),
                        ),
                    ],
                  ),
        ),
      ),
    );
  }
}
