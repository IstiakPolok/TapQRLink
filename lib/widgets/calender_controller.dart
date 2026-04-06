import 'package:get/get.dart';
import 'package:intl/intl.dart';

class CalenderController extends GetxController {
  var focusedDay = DateTime(2022, 12, 1).obs;
  var selectedDay = DateTime(2022, 12, 14).obs;

  String getMonthName(DateTime date) {
    return DateFormat('MMMM').format(date);
  }

  void previousMonth() {
    focusedDay.value = DateTime(
      focusedDay.value.year,
      focusedDay.value.month - 1,
    );
  }

  void nextMonth() {
    focusedDay.value = DateTime(
      focusedDay.value.year,
      focusedDay.value.month + 1,
    );
  }

  void onDaySelected(DateTime selected, DateTime focused) {
    selectedDay.value = selected;
    focusedDay.value = focused;
  }

  bool isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }
}
