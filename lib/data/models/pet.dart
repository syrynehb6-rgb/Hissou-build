class Pet {
  final String id;
  final String name;
  final String species; // dog, cat, bird, horse, etc.
  final String breed;
  final String age;
  final String bio;
  final String? photoPath;

  const Pet({
    required this.id,
    required this.name,
    required this.species,
    this.breed = '',
    this.age = '',
    this.bio = '',
    this.photoPath,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'species': species,
        'breed': breed,
        'age': age,
        'bio': bio,
        'photoPath': photoPath,
      };

  factory Pet.fromJson(Map<String, dynamic> json) => Pet(
        id: json['id'] as String? ?? DateTime.now().millisecondsSinceEpoch.toString(),
        name: json['name'] as String? ?? 'Pet',
        species: json['species'] as String? ?? 'dog',
        breed: json['breed'] as String? ?? '',
        age: json['age'] as String? ?? '',
        bio: json['bio'] as String? ?? '',
        photoPath: json['photoPath'] as String?,
      );
}
