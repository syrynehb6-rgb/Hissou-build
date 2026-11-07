import '../../services.dart';

class StoryPost {
  final String id;
  final String petId;
  final String petName;
  final String species;
  final String caption;
  final String? imagePath;
  final Interpretation? interpretation; // Hissou's signature AI translation attached!
  final DateTime createdAt;
  int likes;
  bool isLiked;

  StoryPost({
    required this.id,
    required this.petId,
    required this.petName,
    required this.species,
    required this.caption,
    this.imagePath,
    this.interpretation,
    DateTime? createdAt,
    this.likes = 0,
    this.isLiked = false,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toJson() => {
        'id': id,
        'petId': petId,
        'petName': petName,
        'species': species,
        'caption': caption,
        'imagePath': imagePath,
        'interpretation': interpretation?.toJson(),
        'createdAt': createdAt.toIso8601String(),
        'likes': likes,
        'isLiked': isLiked,
      };

  factory StoryPost.fromJson(Map<String, dynamic> json) => StoryPost(
        id: json['id'] as String? ?? DateTime.now().millisecondsSinceEpoch.toString(),
        petId: json['petId'] as String? ?? '',
        petName: json['petName'] as String? ?? 'Pet',
        species: json['species'] as String? ?? 'dog',
        caption: json['caption'] as String? ?? '',
        imagePath: json['imagePath'] as String?,
        interpretation: json['interpretation'] != null
            ? Interpretation.fromJson(json['interpretation'] as Map<String, dynamic>)
            : null,
        createdAt: DateTime.tryParse(json['createdAt'] as String? ?? '') ?? DateTime.now(),
        likes: (json['likes'] as num?)?.toInt() ?? 0,
        isLiked: json['isLiked'] as bool? ?? false,
      );
}
