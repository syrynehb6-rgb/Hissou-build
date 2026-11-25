import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/models/order.dart';
import '../../../data/repositories/order_repository.dart';
import 'order_tracking_sheet.dart';

class OrdersScreen extends StatefulWidget {
  const OrdersScreen({super.key});

  @override
  State<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends State<OrdersScreen> {
  final _orderRepo = OrderRepository();
  List<OrderModel> _orders = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadOrders();
    _orderRepo.addListener(_onRepoChanged);
  }

  @override
  void dispose() {
    _orderRepo.removeListener(_onRepoChanged);
    super.dispose();
  }

  void _onRepoChanged() {
    _loadOrders();
  }

  Future<void> _loadOrders() async {
    final list = await _orderRepo.getOrders();
    if (mounted) {
      setState(() {
        _orders = list;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mes Commandes'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _orders.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: HissouColors.accentAmber.withAlpha(25),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.receipt_long_rounded,
                          size: 48,
                          color: HissouColors.accentAmberDark,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Aucune commande passée',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: isDark ? Colors.white : HissouColors.primaryNavy,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Passez votre première commande sur le marketplace Hissou !',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: HissouColors.neutralGrey, fontSize: 13),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  itemCount: _orders.length,
                  itemBuilder: (context, index) {
                    final order = _orders[index];
                    return _buildOrderCard(order, isDark);
                  },
                ),
    );
  }

  Widget _buildOrderCard(OrderModel order, bool isDark) {
    Color statusColor;
    IconData statusIcon;

    switch (order.status) {
      case OrderStatus.confirmed:
        statusColor = HissouColors.primaryNavyLight;
        statusIcon = Icons.done_all_rounded;
        break;
      case OrderStatus.preparing:
        statusColor = HissouColors.accentAmberDark;
        statusIcon = Icons.inventory_2_outlined;
        break;
      case OrderStatus.outForDelivery:
        statusColor = HissouColors.warningOrange;
        statusIcon = Icons.delivery_dining_rounded;
        break;
      case OrderStatus.delivered:
        statusColor = HissouColors.successGreen;
        statusIcon = Icons.check_circle_rounded;
        break;
      case OrderStatus.cancelled:
        statusColor = HissouColors.errorRed;
        statusIcon = Icons.cancel_outlined;
        break;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 14),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(
          color: isDark ? Colors.white12 : Colors.grey.shade200,
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () => OrderTrackingSheet.show(context, order),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: statusColor.withAlpha(25),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(statusIcon, color: statusColor, size: 20),
                      ),
                      const SizedBox(width: 10),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            order.id,
                            style: TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 15,
                              color: isDark ? Colors.white : HissouColors.primaryNavy,
                            ),
                          ),
                          Text(
                            '${order.createdAt.day}/${order.createdAt.month}/${order.createdAt.year} à ${order.createdAt.hour}h${order.createdAt.minute.toString().padLeft(2, '0')}',
                            style: const TextStyle(
                              fontSize: 11,
                              color: HissouColors.neutralGrey,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: statusColor.withAlpha(25),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: statusColor.withAlpha(50)),
                    ),
                    child: Text(
                      order.statusDisplay,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: statusColor,
                      ),
                    ),
                  ),
                ],
              ),
              const Divider(height: 20),
              Text(
                '${order.items.length} article(s) : ${order.items.map((i) => "${i.quantity}x ${i.title}").join(", ")}',
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 12,
                  color: isDark ? Colors.white70 : Colors.black87,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Total : ${order.total.toStringAsFixed(1)} TND',
                    style: const TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 15,
                      color: HissouColors.accentAmberDark,
                    ),
                  ),
                  Row(
                    children: [
                      Text(
                        'Détails & Suivi',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: HissouColors.primaryNavyLight,
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Icon(Icons.arrow_forward_ios_rounded, size: 12, color: HissouColors.primaryNavyLight),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
