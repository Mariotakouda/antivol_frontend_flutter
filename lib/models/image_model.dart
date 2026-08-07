class ImageModel {
  final int id;
  final String url;
  final bool principale;
  final int ordre;

  ImageModel({
    required this.id,
    required this.url,
    required this.principale,
    required this.ordre,
  });

  factory ImageModel.fromJson(Map<String, dynamic> json) {
    return ImageModel(
      id: json['id'] as int,
      url: json['url'] as String,
      principale: json['principale'] as bool,
      ordre: json['ordre'] as int,
    );
  }
}
