import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../../res/colors/app_color.dart';
import 'nav_bar_painter.dart';

class CurvedBottomNavBar extends StatefulWidget {
  final int selectedIndex;
  final Function(int) onItemTapped;
  final List<String> svgIcons;
  final List<String> labels;

  const CurvedBottomNavBar({
    super.key,
    required this.selectedIndex,
    required this.onItemTapped,
    required this.svgIcons,
    required this.labels,
  });

  @override
  State<CurvedBottomNavBar> createState() => _CurvedBottomNavBarState();
}

class _CurvedBottomNavBarState extends State<CurvedBottomNavBar>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  double _currentPos = 0;
  double _targetPos = 0;
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 300),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      _currentPos = _calculatePos(widget.selectedIndex);
      _targetPos = _currentPos;
      _animation =
          Tween<double>(begin: _currentPos, end: _targetPos).animate(
            CurvedAnimation(parent: _controller, curve: Curves.easeOut),
          )..addListener(() {
            setState(() {});
          });
      _initialized = true;
    }
  }

  double _calculatePos(int index) {
    final width = MediaQuery.of(context).size.width;
    final segmentWidth = width / widget.svgIcons.length;
    return (segmentWidth * index) + (segmentWidth / 2);
  }

  void _onTap(int index) {
    widget.onItemTapped(index);
    setState(() {
      _currentPos = _animation.value;
      _targetPos = _calculatePos(index);
      _animation = Tween<double>(
        begin: _currentPos,
        end: _targetPos,
      ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));
      _controller.forward(from: 0);
    });
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    double dipCenter = _animation.value;

    return SizedBox(
      height: 55.h,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.bottomCenter,
        children: [
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: CustomPaint(
              size: Size(size.width, 57.h),
              painter: NavBarPainter(dipCenter: dipCenter),
            ),
          ),

          Positioned(
            bottom: 15.h,
            left: dipCenter - 18.w,
            child: Column(
              children: [
                Container(
                  height: 35.h,
                  width: 35.w,
                  decoration: BoxDecoration(
                    color: AppColor.defaultLightColor,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(color: Colors.black26, blurRadius: 6.r),
                    ],
                  ),
                  child: Padding(
                    padding: EdgeInsets.all(6.w),
                    child: SvgPicture.asset(
                      widget.svgIcons[widget.selectedIndex],
                      colorFilter: ColorFilter.mode(
                        Colors.white,
                        BlendMode.srcIn,
                      ),
                      width: 28.w,
                      height: 28.h,
                    ),
                  ),
                ),
                SizedBox(height: 8.h),
              ],
            ),
          ),

          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: SizedBox(
              height: 65.h,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: List.generate(widget.svgIcons.length, (index) {
                  if (index == widget.selectedIndex) {
                    return SizedBox(width: 55.w);
                  }
                  return GestureDetector(
                    onTap: () => _onTap(index),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Padding(
                          padding: EdgeInsets.only(
                            left: 1.w,
                            right: 1.w,
                            bottom: 1.h,
                            top: 8.h,
                          ),
                          child: SvgPicture.asset(
                            widget.svgIcons[index],
                            colorFilter: ColorFilter.mode(
                              Colors.white,
                              BlendMode.srcIn,
                            ),
                            height: 24.h,
                            width: 24.w,
                          ),
                        ),
                        Text(
                          widget.labels[index],
                          style: TextStyle(
                            fontSize: 10.sp,
                            color: AppColor.whiteColor,
                          ),
                        ),
                      ],
                    ),
                  );
                }),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}
