import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';

import '../res/colors/app_color.dart';
import 'custom_button.dart';

class Calendar extends StatelessWidget {
  final DateTime initialDate;
  final Function(DateTime) onDateSelected;

  const Calendar({
    super.key,
    required this.initialDate,
    required this.onDateSelected,
  });

  @override
  Widget build(BuildContext context) {
    DateTime selectedDate = initialDate;
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10.r),
      ),
      child: Container(
        padding: EdgeInsets.all(16.w),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TableCalendar(
              locale: Get.locale?.toString(),
              firstDay: DateTime.utc(2020, 1, 1),
              lastDay: DateTime.utc(2030, 12, 31),
              focusedDay: selectedDate,
              selectedDayPredicate: (day) => isSameDay(day, selectedDate),
              onDaySelected: (selectedDay, focusedDay) {
                selectedDate = selectedDay;
                debugPrint('Selected date: ${DateFormat('dd/MM/yyyy', Get.locale?.toString()).format(selectedDay)}');
                onDateSelected(selectedDay);
              },
              calendarStyle: CalendarStyle(
                todayDecoration: BoxDecoration(
                  color: AppColor.defaultColor,
                  shape: BoxShape.circle,
                ),
                selectedDecoration: BoxDecoration(
                  color: AppColor.defaultColor,
                  shape: BoxShape.circle,
                ),
                defaultTextStyle: TextStyle(
                  fontFamily: Get.locale?.languageCode == 'ar' ? 'ArabicFont' : 'ProximaNova',
                ),
                weekendTextStyle: TextStyle(
                  fontFamily: Get.locale?.languageCode == 'ar' ? 'ArabicFont' : 'ProximaNova',
                ),
                selectedTextStyle: TextStyle(
                  color: AppColor.whiteColor,
                  fontFamily: Get.locale?.languageCode == 'ar' ? 'ArabicFont' : 'ProximaNova',
                ),
              ),
              headerStyle: HeaderStyle(
                formatButtonVisible: false,
                titleTextStyle: TextStyle(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w600,
                  fontFamily: Get.locale?.languageCode == 'ar' ? 'ArabicFont' : 'ProximaNova',
                ),
                leftChevronIcon: Icon(Icons.chevron_left, color: AppColor.defaultColor),
                rightChevronIcon: Icon(Icons.chevron_right, color: AppColor.defaultColor),
              ),
            ),
            SizedBox(height: 16.h),
            CustomButton(
              title: 'confirm'.tr,
              onPress: () async{
                onDateSelected(selectedDate);
                Navigator.pop(Get.context!);
              },
              linearGradient: true,
              radius: 5.r,
              buttonColor: AppColor.buttonColor,
              buttonColor1: AppColor.buttonColor,
              textColor: AppColor.whiteColor,
              width: 100.w,
              height: 40.h,
            ),
          ],
        ),
      ),
    );
  }
}