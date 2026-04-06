import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

class ClockController extends GetxController {
  var selectedDate = DateTime(2022, 12, 16).obs;
  var selectedHour = 1.obs;
  var selectedMinute = 0.obs;
  var isAM = true.obs;
  var reminderText = ''.obs;

  String getFormattedDate() {
    return '${selectedDate.value.year} ${selectedDate.value.day}, ${DateFormat('MMMM').format(selectedDate.value)}';
  }

  String getFormattedHour() {
    return selectedHour.value.toString().padLeft(2, '0');
  }

  String getFormattedMinute() {
    return selectedMinute.value.toString().padLeft(2, '0');
  }

  String getFormattedTime() {
    return '${getFormattedHour()}:${getFormattedMinute()} ${isAM.value ? 'AM' : 'PM'}';
  }

  void onHourChanged(int hour) {
    selectedHour.value = hour % 12 == 0 ? 12 : hour % 12;
  }

  void onMinuteChanged(int minute) {
    selectedMinute.value = minute % 60;
  }

  void toggleAMPM() {
    isAM.value = !isAM.value;
  }

  void onTextChanged(String text) {
    reminderText.value = text;
  }

  void onDone() {
    Get.back(
      result: {
        'date': selectedDate.value,
        'time': getFormattedTime(),
        'text': reminderText.value,
      },
    );
  }

  void onCancel() {
    Navigator.pop(Get.context!);
  }
}
