import 'package:intl/intl.dart';

class HistoryModel {
  final int id;
  final int user;
  final String link;
  final String? image;
  final bool isRead;
  final DateTime scannedAt;

  HistoryModel({
    required this.id,
    required this.user,
    required this.link,
    required this.image,
    required this.isRead,
    required this.scannedAt,
  });

  factory HistoryModel.fromJson(Map<String, dynamic> json) {
    DateTime parsedDate;
    try {
      parsedDate = DateFormat(
        'hh.mm a, dd MMMM yyyy',
      ).parse(json['scanned_at'] as String);
    } catch (e) {
      parsedDate = DateTime.parse(json['scanned_at'] as String);
    }

    return HistoryModel(
      id: json['id'] as int,
      user: json['user'] as int,
      link: json['link'] as String,
      image: json['image'] as String,
      isRead: json['is_read'] as bool,
      scannedAt: parsedDate,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user': user,
      'link': link,
      'image': image ?? '',
      'is_read': isRead,
      'scanned_at': DateFormat('hh.mm a, dd MMMM yyyy').format(scannedAt),
    };
  }
}
