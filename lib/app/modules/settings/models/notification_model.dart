import 'package:intl/intl.dart';

class NotificationModel {
  final int id;
  final int user;
  final String title;
  final String message;
  final bool isRead;
  final DateTime createdAt;

  NotificationModel({
    required this.id,
    required this.user,
    required this.title,
    required this.message,
    required this.isRead,
    required this.createdAt,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    DateTime parsedDate;
    try {
      parsedDate = DateFormat(
        'hh.mm a, dd MMMM yyyy',
      ).parse(json['created_at'] as String);
    } catch (e) {
      parsedDate = DateTime.parse(json['created_at'] as String);
    }

    return NotificationModel(
      id: json['id'] as int,
      user: json['user'] as int,
      title: json['title'] as String,
      message: json['message'] as String,
      isRead: json['is_read'] as bool,
      createdAt: parsedDate,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user': user,
      'title': title,
      'message': message,
      'is_read': isRead,
      'created_at': DateFormat('hh.mm a, dd MMMM yyyy').format(createdAt),
    };
  }
}
