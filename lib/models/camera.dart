class Camera {
  final String id;
  final String name;
  final String location;
  final bool isOnline;

  Camera({
    required this.id,
    required this.name,
    required this.location,
    required this.isOnline,
  });

  factory Camera.fromJson(Map<String, dynamic> json) => Camera(
    id:       json['id'],
    name:     json['name'],
    location: json['location'],
    isOnline: json['is_online'] ?? false,
  );
}