import 'dart:math';

import 'package:flutter/material.dart';

enum VerticalScrollMode { centimeters, feetInches }

class VerticalScrollController extends ChangeNotifier {
  VerticalScrollMode _mode;

  double topValue;
  double bottomValue;
  final double height;
  final double itemGap;

  double _scrollOffset = 0;
  AxisDirection dragDirection = AxisDirection.up;

  double _currentValue;

  VerticalScrollController({
    required VerticalScrollMode mode,
    required this.topValue,
    required this.bottomValue,
    required this.height,
    this.itemGap = 20,
    double? initialValue,
  }) : _mode = mode,
       _currentValue = initialValue ?? bottomValue {
    _scrollOffset = (topValue - _currentValue) * itemGap;
  }

  VerticalScrollMode get mode => _mode;

  int get itemHeight => itemGap.round();

  int get totalLineCount => (topValue - bottomValue).abs().ceil();

  double get scrollOffset => _scrollOffset;

  double get pickValuePrecise {
    double centerOffset = _scrollOffset / itemHeight;
    double value = topValue - centerOffset;
    return value.clamp(bottomValue, topValue);
  }

  int get pickedValue {
    final precise = pickValuePrecise;
    return dragDirection == AxisDirection.up ? precise.ceil() : precise.floor();
  }

  double get currentValue => _currentValue;

  set currentValue(double val) {
    _currentValue = val.clamp(bottomValue, topValue);
    _scrollOffset = (topValue - _currentValue) * itemHeight;
    notifyListeners();
  }

  void scroll(double pixels) {
    final prev = _scrollOffset;
    _scrollOffset = pixels.clamp(0, totalLineCount * itemHeight).toDouble();
    if (_scrollOffset != prev) {
      _currentValue = topValue - (_scrollOffset / itemHeight);
      notifyListeners();
    }
  }

  void updateDirection(AxisDirection direction) {
    dragDirection = direction;
  }

  void switchToCentimeters() {
    if (_mode == VerticalScrollMode.centimeters) return;
    _currentValue = inchesToCentimeters(_currentValue);
    _mode = VerticalScrollMode.centimeters;
    _updateBoundsForMode();
    _scrollOffset = (topValue - _currentValue) * itemHeight;
    notifyListeners();
  }

  void switchToFeetInches() {
    if (_mode == VerticalScrollMode.feetInches) return;
    _currentValue = centimetersToInches(_currentValue);
    _mode = VerticalScrollMode.feetInches;
    _updateBoundsForMode();
    _scrollOffset = (topValue - _currentValue) * itemHeight;
    notifyListeners();
  }

  void _updateBoundsForMode() {
    if (_mode == VerticalScrollMode.centimeters) {
      bottomValue = 0;
      topValue = 300;
    } else {
      bottomValue = 0;
      topValue = 118;
    }
  }

  static double centimetersToInches(double cm) => cm / 2.54;

  static double inchesToCentimeters(double inch) => inch * 2.54;
}

class VerticalScrollPickerStyle {
  final Color? backgroundItemColor;
  final Color? foregroundItemColor;

  const VerticalScrollPickerStyle({
    this.backgroundItemColor,
    this.foregroundItemColor,
  });

  static const VerticalScrollPickerStyle defaultStyle =
      VerticalScrollPickerStyle(
        backgroundItemColor: Color(0xFF9A9A9A),
        foregroundItemColor: Color(0xFF444444),
      );
}

class VerticalScrollPicker extends StatefulWidget {
  final double? height;
  final double? width;
  final double bottomValue;
  final double topValue;
  final double Function() interval;
  final double lineGap;
  final ValueChanged<double>? onChanged;
  final VerticalScrollPickerStyle style;
  final String Function(double value)? onPickedValueFormat;
  final String Function(double value)? onScaleValueFormat;
  final Key nKey;
  final VerticalScrollController controller;

  const VerticalScrollPicker({
    required this.nKey,
    required this.controller,
    this.height,
    this.width,
    required this.bottomValue,
    required this.topValue,
    required this.interval,
    this.onPickedValueFormat,
    this.onScaleValueFormat,
    this.onChanged,
    this.style = VerticalScrollPickerStyle.defaultStyle,
    this.lineGap = 20,
  }) : super(key: nKey);

  @override
  State<VerticalScrollPicker> createState() => _VerticalScrollPickerState();
}

class _VerticalScrollPickerState extends State<VerticalScrollPicker> {
  late VerticalScrollController controller;

  @override
  void initState() {
    super.initState();
    controller = widget.controller;
    controller.addListener(_controllerListener);
  }

  @override
  void didUpdateWidget(covariant VerticalScrollPicker oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller.removeListener(_controllerListener);
      controller = widget.controller;
      controller.addListener(_controllerListener);
    }
  }

  @override
  void dispose() {
    controller.removeListener(_controllerListener);
    super.dispose();
  }

  void _controllerListener() {}

  void _onDragVertically(DragUpdateDetails details) {
    bool isUp = details.delta.dy < 0;
    controller.updateDirection(isUp ? AxisDirection.up : AxisDirection.down);

    if (!isUp && controller.pickValuePrecise < controller.bottomValue) return;
    if (isUp && controller.pickValuePrecise >= controller.topValue) return;

    double invertedDelta = details.primaryDelta!;

    double newScrollOffset = controller.scrollOffset - invertedDelta;
    controller.scroll(newScrollOffset);
  }

  void _onDragEnd(DragEndDetails details) {
    final double precise = controller.pickValuePrecise;
    final int snappedValue = controller.dragDirection == AxisDirection.up
        ? precise.ceil()
        : precise.floor();
    controller.currentValue = snappedValue.toDouble();
    widget.onChanged?.call(controller.currentValue);
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: widget.height,
      width: widget.width,
      child: GestureDetector(
        onVerticalDragEnd: _onDragEnd,
        onVerticalDragUpdate: _onDragVertically,
        child: _RangeSlide(
          key: widget.nKey,
          controller: controller,
          interval: widget.interval,
          style: widget.style,
          onPickedValueFormat: widget.onPickedValueFormat,
          onScaleValueFormat: widget.onScaleValueFormat,
        ),
      ),
    );
  }
}

class _RangeSlide extends StatefulWidget {
  final String Function(double value)? onPickedValueFormat;
  final String Function(double value)? onScaleValueFormat;
  final double Function() interval;
  final VerticalScrollPickerStyle style;
  final VerticalScrollController controller;

  static double defaultInterval() => 10.0;

  const _RangeSlide({
    super.key,
    required this.controller,
    this.interval = defaultInterval,
    this.onPickedValueFormat,
    this.onScaleValueFormat,
    this.style = VerticalScrollPickerStyle.defaultStyle,
  });

  @override
  State<_RangeSlide> createState() => _RangeSlideState();
}

class _RangeSlideState extends State<_RangeSlide> {
  VerticalScrollController get controller => widget.controller;

  @override
  Widget build(BuildContext context) {
    return ClipRect(
      child: ListenableBuilder(
        listenable: controller,
        builder: (_, _) => CustomPaint(
          painter: ScalePainter(
            topValue: controller.topValue,
            totalLineCount: controller.totalLineCount,
            pickedValue: controller.pickedValue,
            color: widget.style.backgroundItemColor,
            itemHeight: controller.itemHeight,
            interval: widget.interval,
            scrollOffset: controller.scrollOffset,
            offsetLeft: 18,
            valueFormatter:
                widget.onScaleValueFormat ?? (value) => value.toString(),
            bottomValue: controller.bottomValue,
          ),
          foregroundPainter: MarkPainter(
            interval: widget.interval,
            color: widget.style.foregroundItemColor,
            pickedValue: controller.pickedValue,
            offsetLeft: 18,
            valueFormatter:
                widget.onPickedValueFormat ?? (value) => value.toString(),
          ),
        ),
      ),
    );
  }
}

class ScalePainter extends CustomPainter {
  final Color? color;
  final int totalLineCount;
  final double Function() interval;
  final double topValue;
  final double bottomValue;
  final int pickedValue;
  final double scrollOffset;
  final double offsetLeft;
  final String Function(double value) valueFormatter;
  final int itemHeight;

  ScalePainter({
    required this.totalLineCount,
    required this.pickedValue,
    required this.topValue,
    required this.bottomValue,
    required this.interval,
    required this.scrollOffset,
    required this.valueFormatter,
    this.color,
    this.offsetLeft = 12,
    required this.itemHeight,
  });

  final int extraLines = 40;

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()
      ..color = color ?? const Color(0xFF717171)
      ..strokeWidth = 2;

    final double startY = size.height / 2 - scrollOffset;

    for (int i = -extraLines; i <= totalLineCount + extraLines; i++) {
      final double y = startY + i * itemHeight;

      if (y < 0 || y > size.height) continue;

      bool isInterval = ((topValue - i.toDouble()) % interval()) == 0;

      if (isInterval) {
        canvas.drawLine(
          Offset(offsetLeft * 2, y),
          Offset(offsetLeft * 2, y),
          paint,
        );
        canvas.drawLine(
          Offset(offsetLeft * 2, y),
          Offset(offsetLeft * 4, y),
          paint,
        );

        final labelValue = topValue - i;
        if (labelValue.toInt() != pickedValue) {
          _drawText(
            canvas,
            valueFormatter(labelValue),
            Offset(offsetLeft * 4 + 8, y - 7),
            paint.color,
          );
        }
      } else {
        canvas.drawLine(
          Offset(offsetLeft * 2, y),
          Offset(offsetLeft * 2 + offsetLeft, y),
          paint,
        );
      }
    }

    canvas.drawLine(
      Offset(offsetLeft * 2, 0),
      Offset(offsetLeft * 2, size.height),
      paint,
    );
  }

  void _drawText(Canvas canvas, String text, Offset position, Color textColor) {
    final TextSpan span = TextSpan(
      text: text,
      style: TextStyle(
        color: textColor,
        fontSize: 12,
        fontWeight: FontWeight.bold,
      ),
    );
    final TextPainter tp = TextPainter(
      text: span,
      textDirection: TextDirection.ltr,
    );
    tp.layout();
    tp.paint(canvas, position);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class MarkPainter extends CustomPainter {
  final double Function() interval;
  final int pickedValue;
  final double offsetLeft;
  final Color? color;
  final String Function(double) valueFormatter;

  MarkPainter({
    required this.interval,
    required this.pickedValue,
    required this.valueFormatter,
    this.offsetLeft = 12,
    this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final Paint arrowPaint = Paint()
      ..color = color ?? Colors.black
      ..strokeWidth = 3
      ..style = PaintingStyle.fill;

    double arrowHandle = 80;
    double arrowHeadSize = 6;
    double gap = 50;

    Offset center = Offset(size.width / 2, size.height / 2);

    Offset upStart = Offset(6, center.dy - gap / 2);
    Offset upEnd = Offset(6, upStart.dy - arrowHandle);
    canvas.drawLine(upStart, upEnd, arrowPaint);

    Path upArrowHead = Path();
    upArrowHead.moveTo(upEnd.dx, upEnd.dy - 2);
    upArrowHead.lineTo(upEnd.dx - arrowHeadSize, upEnd.dy + arrowHeadSize);
    upArrowHead.lineTo(upEnd.dx + arrowHeadSize, upEnd.dy + arrowHeadSize);
    upArrowHead.close();
    canvas.drawPath(upArrowHead, arrowPaint);

    Offset downStart = Offset(6, center.dy + gap / 2);
    Offset downEnd = Offset(6, downStart.dy + arrowHandle);
    canvas.drawLine(downStart, downEnd, arrowPaint);

    Path downArrowHead = Path();
    downArrowHead.moveTo(downEnd.dx, downEnd.dy + 2);
    downArrowHead.lineTo(
      downEnd.dx - arrowHeadSize,
      downEnd.dy - arrowHeadSize,
    );
    downArrowHead.lineTo(
      downEnd.dx + arrowHeadSize,
      downEnd.dy - arrowHeadSize,
    );
    downArrowHead.close();
    canvas.drawPath(downArrowHead, arrowPaint);

    drawStaticMid(canvas, arrowPaint, center, arrowHeadSize);
  }

  void drawStaticMid(
    Canvas canvas,
    Paint arrowPaint,
    Offset center,
    double arrowHeadSize,
  ) {
    Offset horStart = Offset(offsetLeft * 2, center.dy);
    Offset horEnd = Offset(6 + offsetLeft * 4, horStart.dy);
    canvas.drawLine(horStart, horEnd, arrowPaint);

    Path horizontalArrowHead = Path();
    horizontalArrowHead.moveTo(horStart.dx, horStart.dy - arrowHeadSize);
    horizontalArrowHead.lineTo(horStart.dx, horStart.dy + arrowHeadSize);
    horizontalArrowHead.lineTo(horStart.dx + arrowHeadSize, horStart.dy);
    horizontalArrowHead.close();
    canvas.drawPath(horizontalArrowHead, arrowPaint);

    double finalValue = double.parse(pickedValue.toStringAsFixed(1));
    final TextSpan textSpan = TextSpan(
      text: valueFormatter(max(finalValue, 0)),
      style: TextStyle(
        color: color ?? Colors.black,
        fontSize: 18,
        fontWeight: FontWeight.bold,
      ),
    );

    final TextPainter textPainter = TextPainter(
      text: textSpan,
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();

    Offset textOffset = Offset(
      horEnd.dx + 10,
      horEnd.dy - textPainter.height / 2,
    );
    textPainter.paint(canvas, textOffset);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

String inchToFeetInch(double inchValue) {
  int feet = inchValue ~/ 12;
  int inch = (inchValue % 12).round();
  return "$feet'$inch\"";
}

String inchToFeet(double inchValue) {
  int feet = inchValue ~/ 12;
  return "$feet ft";
}
