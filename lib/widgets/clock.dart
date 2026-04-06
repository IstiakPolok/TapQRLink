import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

class Clock extends StatefulWidget {
  final TimeOfDay initialTime;
  final Function(TimeOfDay) onTimeSelected;

  const Clock({super.key, required this.initialTime, required this.onTimeSelected});

  @override
  State<Clock> createState() => _ClockState();
}

class _ClockState extends State<Clock> {
  late TimeOfDay selectedTime;
  bool isSelectingHour = true;

  @override
  void initState() {
    super.initState();
    selectedTime = widget.initialTime;
  }

  void _toggleAmPm() {
    setState(() {
      final hour = selectedTime.hour;
      final newHour = hour >= 12 ? hour - 12 : hour + 12;
      selectedTime = TimeOfDay(hour: newHour, minute: selectedTime.minute);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20.r),
      ),
      child: Container(
        width: 320.w,
        height: 520.h,
        padding: EdgeInsets.all(24.w),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20.r),
        ),
        child: Column(
          children: [
            // Header
            Text(
              'Select time',
              style: TextStyle(
                fontSize: 16.sp,
                fontWeight: FontWeight.w500,
                color: Colors.black87,
              ),
            ),
            SizedBox(height: 32.h),

            // Digital Time Display
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                GestureDetector(
                  onTap: () => setState(() => isSelectingHour = true),
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
                    decoration: BoxDecoration(
                      color: isSelectingHour ? Colors.blue.shade100 : Colors.transparent,
                      borderRadius: BorderRadius.circular(8.r),
                    ),
                    child: Text(
                      (selectedTime.hour == 0 ? 12 : selectedTime.hour > 12 ? selectedTime.hour - 12 : selectedTime.hour).toString().padLeft(2, '0'),
                      style: TextStyle(
                        fontSize: 48.sp,
                        fontWeight: FontWeight.w300,
                        color: isSelectingHour ? Colors.blue : Colors.black87,
                      ),
                    ),
                  ),
                ),
                Text(
                  ':',
                  style: TextStyle(
                    fontSize: 48.sp,
                    fontWeight: FontWeight.w300,
                    color: Colors.black87,
                  ),
                ),
                GestureDetector(
                  onTap: () => setState(() => isSelectingHour = false),
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
                    decoration: BoxDecoration(
                      color: !isSelectingHour ? Colors.blue.shade100 : Colors.transparent,
                      borderRadius: BorderRadius.circular(8.r),
                    ),
                    child: Text(
                      selectedTime.minute.toString().padLeft(2, '0'),
                      style: TextStyle(
                        fontSize: 48.sp,
                        fontWeight: FontWeight.w300,
                        color: !isSelectingHour ? Colors.blue : Colors.black87,
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 16.w),
                // AM/PM Toggle
                Column(
                  children: [
                    GestureDetector(
                      onTap: () {
                        if (selectedTime.hour >= 12) _toggleAmPm();
                      },
                      child: Container(
                        padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
                        decoration: BoxDecoration(
                          color: selectedTime.hour < 12 ? Colors.blue : Colors.grey.shade200,
                          borderRadius: BorderRadius.circular(8.r),
                        ),
                        child: Text(
                          'AM',
                          style: TextStyle(
                            fontSize: 16.sp,
                            fontWeight: FontWeight.w500,
                            color: selectedTime.hour < 12 ? Colors.white : Colors.black54,
                          ),
                        ),
                      ),
                    ),
                    SizedBox(height: 8.h),
                    GestureDetector(
                      onTap: () {
                        if (selectedTime.hour < 12) _toggleAmPm();
                      },
                      child: Container(
                        padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
                        decoration: BoxDecoration(
                          color: selectedTime.hour >= 12 ? Colors.blue : Colors.grey.shade200,
                          borderRadius: BorderRadius.circular(8.r),
                        ),
                        child: Text(
                          'PM',
                          style: TextStyle(
                            fontSize: 16.sp,
                            fontWeight: FontWeight.w500,
                            color: selectedTime.hour >= 12 ? Colors.white : Colors.black54,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),

            SizedBox(height: 32.h),

            // Analog Clock
            Expanded(
              child: ClockAnalog(
                value: selectedTime,
                isSelectingHour: isSelectingHour,
                onChanged: (time) {
                  setState(() {
                    selectedTime = time;
                  });
                },
              ),
            ),

            SizedBox(height: 24.h),

            // Action Buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(Get.context!),
                  child: Text(
                    'Cancel',
                    style: TextStyle(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w500,
                      color: Colors.blue,
                    ),
                  ),
                ),
                SizedBox(width: 16.w),
                TextButton(
                  onPressed: () {
                    widget.onTimeSelected(selectedTime);
                    Navigator.pop(Get.context!);
                  },
                  child: Text(
                    'OK',
                    style: TextStyle(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w500,
                      color: Colors.blue,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class ClockAnalog extends StatefulWidget {
  final TimeOfDay value;
  final bool isSelectingHour;
  final ValueChanged<TimeOfDay> onChanged;

  const ClockAnalog({
    super.key,
    required this.value,
    required this.isSelectingHour,
    required this.onChanged,
  });

  @override
  State<ClockAnalog> createState() => _ClockAnalogState();
}

class _ClockAnalogState extends State<ClockAnalog> {
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onPanUpdate: (details) {
        final center = Offset(140.w, 140.h);
        final touchPosition = details.localPosition;
        final angle = atan2(touchPosition.dy - center.dy, touchPosition.dx - center.dx);
        final degrees = (angle * 180 / pi + 90) % 360;

        if (widget.isSelectingHour) {
          final hour = ((degrees / 30).round() % 12);
          final adjustedHour = widget.value.hour >= 12 ? hour + 12 : hour;
          final newTime = TimeOfDay(hour: adjustedHour, minute: widget.value.minute);
          widget.onChanged(newTime);
        } else {
          final minute = ((degrees / 6).round() % 60);
          final newTime = TimeOfDay(hour: widget.value.hour, minute: minute);
          widget.onChanged(newTime);
        }
      },
      child: SizedBox(
        width: 280.w,
        height: 280.h,
        child: CustomPaint(
          painter: ClockPainter(
            time: widget.value,
            isSelectingHour: widget.isSelectingHour,
          ),
        ),
      ),
    );
  }
}

class ClockPainter extends CustomPainter {
  final TimeOfDay time;
  final bool isSelectingHour;

  ClockPainter({required this.time, required this.isSelectingHour});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    // Draw clock face background
    canvas.drawCircle(
      center,
      radius,
      Paint()..color = Colors.blue.shade50,
    );

    // Draw hour numbers
    final textPainter = TextPainter(
      textDirection: TextDirection.ltr,
      textAlign: TextAlign.center,
    );

    for (int i = 1; i <= 12; i++) {
      final angle = (i * 30 - 90) * pi / 180;
      final x = center.dx + (radius - 30) * cos(angle);
      final y = center.dy + (radius - 30) * sin(angle);

      textPainter.text = TextSpan(
        text: i.toString(),
        style: TextStyle(
          fontSize: 16.sp,
          fontWeight: FontWeight.w500,
          color: Colors.black87,
        ),
      );
      textPainter.layout();
      textPainter.paint(canvas, Offset(x - textPainter.width / 2, y - textPainter.height / 2));
    }

    // Draw hour hand
    final hourAngle = ((time.hour % 12) * 30 + time.minute * 0.5 - 90) * pi / 180;
    final hourHandEnd = Offset(
      center.dx + radius * 0.5 * cos(hourAngle),
      center.dy + radius * 0.5 * sin(hourAngle),
    );

    canvas.drawLine(
      center,
      hourHandEnd,
      Paint()
        ..color = Colors.black87
        ..strokeWidth = 3.w
        ..strokeCap = StrokeCap.round,
    );

    // Draw minute hand
    final minuteAngle = (time.minute * 6 - 90) * pi / 180;
    final minuteHandEnd = Offset(
      center.dx + radius * 0.7 * cos(minuteAngle),
      center.dy + radius * 0.7 * sin(minuteAngle),
    );

    canvas.drawLine(
      center,
      minuteHandEnd,
      Paint()
        ..color = Colors.black87
        ..strokeWidth = 2.w
        ..strokeCap = StrokeCap.round,
    );

    // Draw selected time indicator
    if (isSelectingHour) {
      canvas.drawCircle(
        hourHandEnd,
        20.w,
        Paint()..color = Colors.blue,
      );
      canvas.drawCircle(
        hourHandEnd,
        20.w,
        Paint()
          ..color = Colors.white
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.w,
      );
    } else {
      canvas.drawCircle(
        minuteHandEnd,
        15.w,
        Paint()..color = Colors.blue,
      );
    }

    // Draw center dot
    canvas.drawCircle(
      center,
      6.w,
      Paint()..color = Colors.black87,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}