import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/models/order.dart';

class OrderTrackingSheet extends StatelessWidget {
  final OrderModel order;

  const OrderTrackingSheet({super.key, required this.order});

  static Future<void> show(BuildContext context, OrderModel order) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => OrderTrackingSheet(order: order),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.88,
      ),
      decoration: BoxDecoration(
        color: isDark ? HissouColors.cardSurfaceDark : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        boxShadow: const [
          BoxShadow(
            color: Colors.black38,
            blurRadius: 30,
            offset: Offset(0, -10),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: 12, bottom: 8),
              width: 44,
              height: 4,
              decoration: BoxDecoration(
                color: isDark ? Colors.white24 : Colors.black12,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: HissouColors.successGreen.withAlpha(35),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.local_shipping_rounded,
                    color: HissouColors.successGreen,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            'Suivi de Commande',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              color: isDark ? Colors.white : HissouColors.primaryNavy,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: HissouColors.accentAmber.withAlpha(35),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              order.id,
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w900,
                                color: HissouColors.accentAmberDark,
                              ),
                            ),
                          ),
                        ],
                      ),
                      Text(
                        'Livraison estimée : ${order.estimatedDelivery.hour}h00 aujourd\'hui',
                        style: const TextStyle(
                          fontSize: 12,
                          color: HissouColors.neutralGrey,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close_rounded),
                ),
              ],
            ),
          ),
          const Divider(height: 1),

          // Content
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Animated Stepper
                  _buildStepperCard(isDark),
                  const SizedBox(height: 18),

                  // Courier Info Card
                  _buildCourierCard(isDark),
                  const SizedBox(height: 18),

                  // Order Items Recap
                  Text(
                    'Articles de la commande',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: isDark ? Colors.white : HissouColors.primaryNavy,
                    ),
                  ),
                  const SizedBox(height: 10),
                  ...order.items.map((item) => Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Row(
                          children: [
                            Container(
                              width: 32,
                              height: 32,
                              decoration: BoxDecoration(
                                color: HissouColors.primaryNavy.withAlpha(15),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(
                                Icons.pets_rounded,
                                size: 16,
                                color: HissouColors.primaryNavy,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                '${item.quantity}x ${item.title}',
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 13,
                                  color: isDark ? Colors.white : HissouColors.primaryNavy,
                                ),
                              ),
                            ),
                            Text(
                              '${item.totalPrice.toStringAsFixed(1)} TND',
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 13,
                                color: HissouColors.accentAmberDark,
                              ),
                            ),
                          ],
                        ),
                      )),
                  const Divider(height: 24),

                  // Receipt details
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Total Réglé :', style: TextStyle(fontWeight: FontWeight.w600)),
                      Text(
                        '${order.total.toStringAsFixed(1)} TND (${order.paymentMethod})',
                        style: const TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 15,
                          color: HissouColors.successGreen,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Adresse :', style: TextStyle(fontWeight: FontWeight.w600, color: HissouColors.neutralGrey)),
                      Flexible(
                        child: Text(
                          order.deliveryAddress,
                          textAlign: TextAlign.end,
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: isDark ? Colors.white70 : Colors.black87,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStepperCard(bool isDark) {
    final step = order.statusStep;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withAlpha(6) : Colors.grey.shade50,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? Colors.white12 : Colors.grey.shade200,
        ),
      ),
      child: Column(
        children: [
          _buildStepRow(
            title: 'Commande Confirmée',
            subtitle: 'Reçue et enregistrée dans le système Hissou',
            icon: Icons.check_circle_rounded,
            isActive: step >= 0,
            isCompleted: step > 0,
            isLast: false,
            isDark: isDark,
          ),
          _buildStepRow(
            title: 'En Préparation',
            subtitle: 'Articles emballés et vérifiés pour la santé féline',
            icon: Icons.inventory_2_rounded,
            isActive: step >= 1,
            isCompleted: step > 1,
            isLast: false,
            isDark: isDark,
          ),
          _buildStepRow(
            title: 'En Cours de Livraison',
            subtitle: 'Livreur en route vers votre domicile',
            icon: Icons.moped_rounded,
            isActive: step >= 2,
            isCompleted: step > 2,
            isLast: false,
            isDark: isDark,
          ),
          _buildStepRow(
            title: 'Livrée avec Succès',
            subtitle: 'Remise en main propre avec signature',
            icon: Icons.home_rounded,
            isActive: step >= 3,
            isCompleted: step >= 3,
            isLast: true,
            isDark: isDark,
          ),
        ],
      ),
    );
  }

  Widget _buildStepRow({
    required String title,
    required String subtitle,
    required IconData icon,
    required bool isActive,
    required bool isCompleted,
    required bool isLast,
    required bool isDark,
  }) {
    Color nodeColor;
    if (isCompleted) {
      nodeColor = HissouColors.successGreen;
    } else if (isActive) {
      nodeColor = HissouColors.accentAmber;
    } else {
      nodeColor = isDark ? Colors.white24 : Colors.grey.shade300;
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: nodeColor.withAlpha(35),
                shape: BoxShape.circle,
                border: Border.all(color: nodeColor, width: 2),
              ),
              child: Icon(icon, size: 14, color: nodeColor),
            ),
            if (!isLast)
              Container(
                width: 2,
                height: 34,
                color: isCompleted ? HissouColors.successGreen : (isDark ? Colors.white12 : Colors.grey.shade200),
              ),
          ],
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(top: 2, bottom: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontWeight: isActive ? FontWeight.w800 : FontWeight.w600,
                    fontSize: 14,
                    color: isActive
                        ? (isDark ? Colors.white : HissouColors.primaryNavy)
                        : HissouColors.neutralGrey,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 11,
                    color: isDark ? Colors.white54 : Colors.black54,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCourierCard(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            HissouColors.primaryNavy,
            HissouColors.primaryNavyLight,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: HissouColors.primaryNavy.withAlpha(50),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.sports_motorsports_rounded,
              color: HissouColors.primaryNavy,
              size: 26,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text(
                  'Livreur Hissou Express',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 14,
                  ),
                ),
                Text(
                  'Mohamed • Scooter Électrique #12',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          IconButton.filled(
            onPressed: () {},
            style: IconButton.styleFrom(
              backgroundColor: HissouColors.accentAmber,
              foregroundColor: HissouColors.primaryNavyDark,
            ),
            icon: const Icon(Icons.call_rounded, size: 18),
          ),
        ],
      ),
    );
  }
}
