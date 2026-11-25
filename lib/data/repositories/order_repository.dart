import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/order.dart';

class OrderRepository extends ChangeNotifier {
  static final OrderRepository _instance = OrderRepository._internal();
  factory OrderRepository() => _instance;
  OrderRepository._internal();

  static const _key = 'hissou_orders_v1';
  final List<OrderItem> _cart = [];

  List<OrderItem> get cart => List.unmodifiable(_cart);
  int get cartCount => _cart.fold(0, (sum, item) => sum + item.quantity);
  double get cartSubtotal => _cart.fold(0.0, (sum, item) => sum + item.totalPrice);

  void addToCart(OrderItem item) {
    final index = _cart.indexWhere((element) => element.id == item.id);
    if (index >= 0) {
      _cart[index] = _cart[index].copyWith(quantity: _cart[index].quantity + item.quantity);
    } else {
      _cart.add(item);
    }
    notifyListeners();
  }

  void updateQuantity(String itemId, int quantity) {
    if (quantity <= 0) {
      _cart.removeWhere((element) => element.id == itemId);
    } else {
      final index = _cart.indexWhere((element) => element.id == itemId);
      if (index >= 0) {
        _cart[index] = _cart[index].copyWith(quantity: quantity);
      }
    }
    notifyListeners();
  }

  void removeFromCart(String itemId) {
    _cart.removeWhere((element) => element.id == itemId);
    notifyListeners();
  }

  void clearCart() {
    _cart.clear();
    notifyListeners();
  }

  List<OrderModel> _getDefaultOrders() {
    return [
      OrderModel(
        id: 'CMD-8921',
        items: [
          OrderItem(
            id: 'mkt_3',
            title: 'Sac de Transport Ergonomique Deluxe Hissou',
            price: 75.0,
            quantity: 1,
            category: 'supplies',
          ),
          OrderItem(
            id: 'item_toy',
            title: 'Jouet Laser Interactif avec Sons Apaisants',
            price: 25.0,
            quantity: 2,
            category: 'supplies',
          ),
        ],
        subtotal: 125.0,
        deliveryFee: 7.0,
        discount: 10.0,
        total: 122.0,
        status: OrderStatus.outForDelivery,
        deliveryAddress: 'Avenue Habib Bourguiba, Tunis',
        clientPhone: '+216 98 123 456',
        clientName: 'Syrine',
        paymentMethod: 'Paiement à la livraison',
        createdAt: DateTime.now().subtract(const Duration(hours: 3)),
        estimatedDelivery: DateTime.now().add(const Duration(hours: 2)),
      ),
      OrderModel(
        id: 'CMD-6410',
        items: [
          OrderItem(
            id: 'mkt_4',
            title: 'Séance Toilettage & Spa Félin à Domicile',
            price: 45.0,
            quantity: 1,
            category: 'services',
          ),
        ],
        subtotal: 45.0,
        deliveryFee: 0.0,
        discount: 0.0,
        total: 45.0,
        status: OrderStatus.delivered,
        deliveryAddress: 'La Marsa, Tunis',
        clientPhone: '+216 98 123 456',
        clientName: 'Syrine',
        paymentMethod: 'Carte Bancaire',
        createdAt: DateTime.now().subtract(const Duration(days: 2)),
        estimatedDelivery: DateTime.now().subtract(const Duration(days: 2, hours: -1)),
      ),
    ];
  }

  Future<List<OrderModel>> getOrders() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_key);
    if (raw == null || raw.isEmpty) {
      final defaults = _getDefaultOrders();
      await saveOrders(defaults);
      return defaults;
    }
    return raw
        .map((str) => OrderModel.fromJson(jsonDecode(str) as Map<String, dynamic>))
        .toList();
  }

  Future<void> saveOrders(List<OrderModel> orders) async {
    final prefs = await SharedPreferences.getInstance();
    final list = orders.map((o) => jsonEncode(o.toJson())).toList();
    await prefs.setStringList(_key, list);
    notifyListeners();
  }

  Future<OrderModel> placeOrder({
    required String clientName,
    required String clientPhone,
    required String deliveryAddress,
    required String paymentMethod,
    double discount = 0.0,
  }) async {
    final orders = await getOrders();
    final id = 'CMD-${(1000 + orders.length * 37 + DateTime.now().millisecond).toString()}';
    final sub = cartSubtotal;
    const fee = 7.0;
    final tot = (sub + fee - discount).clamp(0.0, double.infinity);

    final newOrder = OrderModel(
      id: id,
      items: List.from(_cart),
      subtotal: sub,
      deliveryFee: fee,
      discount: discount,
      total: tot,
      status: OrderStatus.confirmed,
      deliveryAddress: deliveryAddress,
      clientPhone: clientPhone,
      clientName: clientName,
      paymentMethod: paymentMethod,
      createdAt: DateTime.now(),
      estimatedDelivery: DateTime.now().add(const Duration(hours: 24)),
    );

    orders.insert(0, newOrder);
    await saveOrders(orders);
    clearCart();
    return newOrder;
  }
}
