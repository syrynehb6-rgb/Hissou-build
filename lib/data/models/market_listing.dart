enum MarketCategory { adoption, supplies, services }

class MarketListing {
  final String id;
  final String title;
  final String description;
  final MarketCategory category;
  final double price; // 0 for free adoption
  final String currency;
  final String location;
  final String contactPhone;
  final String? imagePath;
  final bool isVerified;
  final String species; // dog, cat, bird, all
  final DateTime createdAt;

  MarketListing({
    required this.id,
    required this.title,
    required this.description,
    required this.category,
    this.price = 0.0,
    this.currency = '\$',
    required this.location,
    required this.contactPhone,
    this.imagePath,
    this.isVerified = false,
    this.species = 'all',
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'description': description,
        'category': category.name,
        'price': price,
        'currency': currency,
        'location': location,
        'contactPhone': contactPhone,
        'imagePath': imagePath,
        'isVerified': isVerified,
        'species': species,
        'createdAt': createdAt.toIso8601String(),
      };

  factory MarketListing.fromJson(Map<String, dynamic> json) => MarketListing(
        id: json['id'] as String? ?? DateTime.now().millisecondsSinceEpoch.toString(),
        title: json['title'] as String? ?? '',
        description: json['description'] as String? ?? '',
        category: MarketCategory.values.firstWhere(
          (c) => c.name == json['category'],
          orElse: () => MarketCategory.adoption,
        ),
        price: (json['price'] as num?)?.toDouble() ?? 0.0,
        currency: json['currency'] as String? ?? '\$',
        location: json['location'] as String? ?? '',
        contactPhone: json['contactPhone'] as String? ?? '',
        imagePath: json['imagePath'] as String?,
        isVerified: json['isVerified'] as bool? ?? false,
        species: json['species'] as String? ?? 'all',
        createdAt: DateTime.tryParse(json['createdAt'] as String? ?? '') ?? DateTime.now(),
      );
}
