class OrderItem {
  final String id;
  final String title;
  final double price;
  final String currency;
  final int quantity;
  final String? imagePath;
  final String category;

  OrderItem({
    required this.id,
    required this.title,
    required this.price,
    this.currency = 'TND',
    this.quantity = 1,
    this.imagePath,
    this.category = 'supplies',
  });

  double get totalPrice => price * quantity;

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'price': price,
        'currency': currency,
        'quantity': quantity,
        'imagePath': imagePath,
        'category': category,
      };

  factory OrderItem.fromJson(Map<String, dynamic> json) => OrderItem(
        id: json['id'] as String,
        title: json['title'] as String,
        price: (json['price'] as num).toDouble(),
        currency: json['currency'] as String? ?? 'TND',
        quantity: json['quantity'] as int? ?? 1,
        imagePath: json['imagePath'] as String?,
        category: json['category'] as String? ?? 'supplies',
      );

  OrderItem copyWith({int? quantity}) => OrderItem(
        id: id,
        title: title,
        price: price,
        currency: currency,
        quantity: quantity ?? this.quantity,
        imagePath: imagePath,
        category: category,
      );
}

enum OrderStatus {
  confirmed,
  preparing,
  outForDelivery,
  delivered,
  cancelled,
}

class OrderModel {
  final String id;
  final List<OrderItem> items;
  final double subtotal;
  final double deliveryFee;
  final double discount;
  final double total;
  final OrderStatus status;
  final String deliveryAddress;
  final String clientPhone;
  final String clientName;
  final String paymentMethod; // Cash on delivery, Card, Flouci
  final DateTime createdAt;
  final DateTime estimatedDelivery;

  OrderModel({
    required this.id,
    required this.items,
    required this.subtotal,
    this.deliveryFee = 7.0,
    this.discount = 0.0,
    required this.total,
    this.status = OrderStatus.confirmed,
    required this.deliveryAddress,
    required this.clientPhone,
    required this.clientName,
    this.paymentMethod = 'Paiement à la livraison',
    DateTime? createdAt,
    DateTime? estimatedDelivery,
  })  : createdAt = createdAt ?? DateTime.now(),
        estimatedDelivery = estimatedDelivery ??
            DateTime.now().add(const Duration(hours: 24));

  String get statusDisplay {
    switch (status) {
      case OrderStatus.confirmed:
        return 'Commande Confirmée';
      case OrderStatus.preparing:
        return 'En Préparation';
      case OrderStatus.outForDelivery:
        return 'En Cours de Livraison';
      case OrderStatus.delivered:
        return 'Livrée avec Succès';
      case OrderStatus.cancelled:
        return 'Annulée';
    }
  }

  int get statusStep {
    switch (status) {
      case OrderStatus.confirmed:
        return 0;
      case OrderStatus.preparing:
        return 1;
      case OrderStatus.outForDelivery:
        return 2;
      case OrderStatus.delivered:
        return 3;
      case OrderStatus.cancelled:
        return -1;
    }
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'items': items.map((i) => i.toJson()).toList(),
        'subtotal': subtotal,
        'deliveryFee': deliveryFee,
        'discount': discount,
        'total': total,
        'status': status.name,
        'deliveryAddress': deliveryAddress,
        'clientPhone': clientPhone,
        'clientName': clientName,
        'paymentMethod': paymentMethod,
        'createdAt': createdAt.toIso8601String(),
        'estimatedDelivery': estimatedDelivery.toIso8601String(),
      };

  factory OrderModel.fromJson(Map<String, dynamic> json) => OrderModel(
        id: json['id'] as String,
        items: (json['items'] as List<dynamic>)
            .map((e) => OrderItem.fromJson(e as Map<String, dynamic>))
            .toList(),
        subtotal: (json['subtotal'] as num).toDouble(),
        deliveryFee: (json['deliveryFee'] as num?)?.toDouble() ?? 7.0,
        discount: (json['discount'] as num?)?.toDouble() ?? 0.0,
        total: (json['total'] as num).toDouble(),
        status: OrderStatus.values.firstWhere(
          (s) => s.name == json['status'],
          orElse: () => OrderStatus.confirmed,
        ),
        deliveryAddress: json['deliveryAddress'] as String,
        clientPhone: json['clientPhone'] as String,
        clientName: json['clientName'] as String,
        paymentMethod: json['paymentMethod'] as String? ?? 'Paiement à la livraison',
        createdAt: DateTime.parse(json['createdAt'] as String),
        estimatedDelivery: DateTime.parse(json['estimatedDelivery'] as String),
      );
}
