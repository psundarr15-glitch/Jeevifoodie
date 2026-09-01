class AppNotification {
  final int id;
  final String title;
  final String body;
  final String? imageUrl;
  final DateTime createdAt;

  AppNotification({
    required this.id,
    required this.title,
    required this.body,
    required this.imageUrl,
    required this.createdAt,
  });

  factory AppNotification.fromJson(Map<String, dynamic> j) => AppNotification(
        id: int.parse(j['id'].toString()),
        title: j['title']?.toString() ?? '',
        body: j['body']?.toString() ?? '',
        imageUrl: (j['image_url']?.toString().isEmpty ?? true) ? null : j['image_url'].toString(),
        // Backend sends "YYYY-MM-DD HH:MM:SS" (server local time); DateTime.parse
        // handles that format directly.
        createdAt: DateTime.tryParse(j['created_at']?.toString() ?? '') ?? DateTime.now(),
      );
}
