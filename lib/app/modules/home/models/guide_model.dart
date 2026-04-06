class GuideModel {
  final int id;
  final String title;
  final String video;

  GuideModel({required this.id, required this.title, required this.video});

  factory GuideModel.fromJson(Map<String, dynamic> json) => GuideModel(
    id: json['id'] ?? 0,
    title: json['title'] ?? '',
    video: json['video'] ?? '',
  );
}
