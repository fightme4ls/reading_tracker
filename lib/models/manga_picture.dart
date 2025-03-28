class MangaPicture {
  final String imageUrl;

  MangaPicture({required this.imageUrl});

  factory MangaPicture.fromJson(Map<String, dynamic> json) {
    return MangaPicture(
      imageUrl: json['jpg']['image_url'] ?? '', // Use JPG image URL
    );
  }
}
