class Camera {
  final String id;
  final String name;
  final String location;
  final bool isOnline;

  const Camera({
    required this.id,
    required this.name,
    required this.location,
    required this.isOnline,
  });

  factory Camera.fromJson(Map<String, dynamic> json) {
    return Camera(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? 'Unnamed Camera',
      location: json['location']?.toString() ??
          json['zone']?.toString().replaceAll('_', ' ') ??
          '',
      isOnline: json['is_online'] == true || json['connected'] == true,
    );
  }
}
