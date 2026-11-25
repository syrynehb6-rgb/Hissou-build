import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/models/order.dart';
import '../../../data/repositories/order_repository.dart';
import '../orders/order_tracking_sheet.dart';

class CartSheet extends StatefulWidget {
  final VoidCallback onOrderPlaced;

  const CartSheet({super.key, required this.onOrderPlaced});

  static Future<void> show(BuildContext context, {VoidCallback? onOrderPlaced}) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => CartSheet(onOrderPlaced: onOrderPlaced ?? () {}),
    );
  }

  @override
  State<CartSheet> createState() => _CartSheetState();
}

class _CartSheetState extends State<CartSheet> {
  final _orderRepo = OrderRepository();
  final _nameController = TextEditingController(text: 'Syrine');
  final _phoneController = TextEditingController(text: '+216 98 123 456');
  final _addressController = TextEditingController(text: 'Avenue Habib Bourguiba, Tunis');
  final _promoController = TextEditingController();

  double _discount = 0.0;
  String _promoApplied = '';
  String _selectedPayment = 'Paiement à la livraison';
  bool _isOrdering = false;

  @override
  void initState() {
    super.initState();
    _orderRepo.addListener(_onCartChanged);
  }

  @override
  void dispose() {
    _orderRepo.removeListener(_onCartChanged);
    _nameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _promoController.dispose();
    super.dispose();
  }

  void _onCartChanged() {
    if (mounted) setState(() {});
  }

  void _applyPromo() {
    final code = _promoController.text.trim().toUpperCase();
    if (code == 'HISSOU' || code == 'HISSOU10') {
      setState(() {
        _discount = 10.0;
        _promoApplied = code;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: const [
              Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
              SizedBox(width: 8),
              Text('Code promo appliqué : -10 TND de réduction !'),
            ],
          ),
          backgroundColor: HissouColors.successGreen,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Code promo invalide. Essayez "HISSOU10"'),
          backgroundColor: HissouColors.errorRed,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    }
  }

  Future<void> _submitOrder() async {
    if (_nameController.text.trim().isEmpty ||
        _phoneController.text.trim().isEmpty ||
        _addressController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Veuillez remplir vos coordonnées de livraison'),
          backgroundColor: HissouColors.warningOrange,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
      return;
    }

    setState(() => _isOrdering = true);
    await Future.delayed(const Duration(milliseconds: 900));

    final order = await _orderRepo.placeOrder(
      clientName: _nameController.text.trim(),
      clientPhone: _phoneController.text.trim(),
      deliveryAddress: _addressController.text.trim(),
      paymentMethod: _selectedPayment,
      discount: _discount,
    );

    if (!mounted) return;
    setState(() => _isOrdering = false);
    Navigator.of(context).pop(); // Close cart

    widget.onOrderPlaced();

    // Show celebration tracking sheet
    OrderTrackingSheet.show(context, order);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final items = _orderRepo.cart;
    final subtotal = _orderRepo.cartSubtotal;
    final deliveryFee = subtotal >= 100.0 || items.isEmpty ? 0.0 : 7.0;
    final total = (subtotal + deliveryFee - _discount).clamp(0.0, double.infinity);

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.9,
      ),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
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
          // Drag indicator
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
                    color: HissouColors.accentAmber.withAlpha(35),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.shopping_bag_rounded,
                    color: HissouColors.accentAmberDark,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Mon Panier (${_orderRepo.cartCount} articles)',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: isDark ? Colors.white : HissouColors.primaryNavy,
                        ),
                      ),
                      Text(
                        deliveryFee == 0.0 && items.isNotEmpty
                            ? 'Livraison Offerte 🎉'
                            : 'Livraison express 24h-48h',
                        style: TextStyle(
                          fontSize: 12,
                          color: deliveryFee == 0.0 && items.isNotEmpty
                              ? HissouColors.successGreen
                              : HissouColors.neutralGrey,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                if (items.isNotEmpty)
                  TextButton.icon(
                    onPressed: () => _orderRepo.clearCart(),
                    icon: const Icon(Icons.delete_outline_rounded, size: 16),
                    label: const Text('Vider'),
                    style: TextButton.styleFrom(
                      foregroundColor: HissouColors.errorRed,
                    ),
                  ),
              ],
            ),
          ),
          const Divider(height: 1),

          // Content
          if (items.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 24),
              child: Column(
                children: [
                  Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      color: isDark ? Colors.white10 : Colors.black.withAlpha(10),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.shopping_cart_outlined,
                      size: 36,
                      color: HissouColors.neutralGrey,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Votre panier est vide',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: isDark ? Colors.white : HissouColors.primaryNavy,
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Ajoutez des produits de nutrition, accessoires ou services félins pour commander !',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: HissouColors.neutralGrey, fontSize: 13),
                  ),
                ],
              ),
            )
          else
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Items List
                    ...items.map((item) => _buildCartItemTile(item, isDark)),
                    const SizedBox(height: 16),

                    // Promo Code Box
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                      decoration: BoxDecoration(
                        color: isDark ? Colors.white.withAlpha(8) : Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: _promoApplied.isNotEmpty
                              ? HissouColors.successGreen
                              : (isDark ? Colors.white12 : Colors.grey.shade200),
                        ),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.confirmation_number_outlined,
                              color: HissouColors.accentAmber, size: 20),
                          const SizedBox(width: 10),
                          Expanded(
                            child: TextField(
                              controller: _promoController,
                              textCapitalization: TextCapitalization.characters,
                              decoration: const InputDecoration(
                                hintText: 'Code Promo (ex: HISSOU10)',
                                border: InputBorder.none,
                                isDense: true,
                                contentPadding: EdgeInsets.zero,
                              ),
                              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                            ),
                          ),
                          ElevatedButton(
                            onPressed: _applyPromo,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: HissouColors.primaryNavy,
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                              minimumSize: Size.zero,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            child: const Text('Appliquer', style: TextStyle(fontSize: 12)),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 18),

                    // Delivery Details Section
                    Text(
                      'Coordonnées de Livraison',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: isDark ? Colors.white : HissouColors.primaryNavy,
                      ),
                    ),
                    const SizedBox(height: 10),
                    _buildInputField(
                      controller: _nameController,
                      label: 'Nom & Prénom',
                      icon: Icons.person_outline_rounded,
                      isDark: isDark,
                    ),
                    const SizedBox(height: 8),
                    _buildInputField(
                      controller: _phoneController,
                      label: 'Numéro de Téléphone',
                      icon: Icons.phone_outlined,
                      keyboardType: TextInputType.phone,
                      isDark: isDark,
                    ),
                    const SizedBox(height: 8),
                    _buildInputField(
                      controller: _addressController,
                      label: 'Adresse Complète (Ville, Rue)',
                      icon: Icons.location_on_outlined,
                      isDark: isDark,
                    ),
                    const SizedBox(height: 18),

                    // Payment Methods
                    Text(
                      'Mode de Paiement',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: isDark ? Colors.white : HissouColors.primaryNavy,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _buildPaymentChip(
                          title: 'Paiement à la livraison',
                          icon: Icons.local_shipping_outlined,
                          isDark: isDark,
                        ),
                        _buildPaymentChip(
                          title: 'Carte Bancaire (En ligne)',
                          icon: Icons.credit_card_rounded,
                          isDark: isDark,
                        ),
                        _buildPaymentChip(
                          title: 'Flouci / Konnect',
                          icon: Icons.account_balance_wallet_outlined,
                          isDark: isDark,
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // Summary breakdown
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: isDark ? Colors.black26 : Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: Column(
                        children: [
                          _buildSummaryRow('Sous-total', '${subtotal.toStringAsFixed(1)} TND', isDark),
                          const SizedBox(height: 6),
                          _buildSummaryRow(
                            'Frais de livraison',
                            deliveryFee == 0.0 ? 'GRATUIT' : '${deliveryFee.toStringAsFixed(1)} TND',
                            isDark,
                            isFree: deliveryFee == 0.0,
                          ),
                          if (_discount > 0) ...[
                            const SizedBox(height: 6),
                            _buildSummaryRow(
                              'Réduction ($_promoApplied)',
                              '-${_discount.toStringAsFixed(1)} TND',
                              isDark,
                              isDiscount: true,
                            ),
                          ],
                          const Divider(height: 18),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Total à Payer',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w900,
                                  color: isDark ? Colors.white : HissouColors.primaryNavy,
                                ),
                              ),
                              Text(
                                '${total.toStringAsFixed(1)} TND',
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w900,
                                  color: HissouColors.accentAmberDark,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Checkout Button
                    SizedBox(
                      width: double.infinity,
                      height: 54,
                      child: ElevatedButton(
                        onPressed: _isOrdering ? null : _submitOrder,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: HissouColors.primaryNavy,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          elevation: 3,
                          shadowColor: HissouColors.primaryNavy.withAlpha(100),
                        ),
                        child: _isOrdering
                            ? const SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2.5,
                                ),
                              )
                            : Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(Icons.lock_outline_rounded, size: 18),
                                  const SizedBox(width: 10),
                                  Text(
                                    'Commander Maintenant • ${total.toStringAsFixed(1)} TND',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w800,
                                      fontSize: 15,
                                      color: Colors.white,
                                    ),
                                  ),
                                ],
                              ),
                      ),
                    ),
                    const SizedBox(height: 8),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildCartItemTile(OrderItem item, bool isDark) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withAlpha(8) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? Colors.white12 : Colors.grey.shade200,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [HissouColors.accentAmberLight, HissouColors.softRoseLight],
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.pets_rounded,
              color: HissouColors.primaryNavy,
              size: 24,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: isDark ? Colors.white : HissouColors.primaryNavy,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${item.price.toStringAsFixed(1)} TND / unité',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: HissouColors.accentAmberDark,
                  ),
                ),
              ],
            ),
          ),
          Row(
            children: [
              IconButton(
                visualDensity: VisualDensity.compact,
                icon: const Icon(Icons.remove_circle_outline_rounded, size: 20),
                color: HissouColors.neutralGrey,
                onPressed: () => _orderRepo.updateQuantity(item.id, item.quantity - 1),
              ),
              Text(
                '${item.quantity}',
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 14,
                  color: isDark ? Colors.white : HissouColors.primaryNavy,
                ),
              ),
              IconButton(
                visualDensity: VisualDensity.compact,
                icon: const Icon(Icons.add_circle_outline_rounded, size: 20),
                color: HissouColors.primaryNavyLight,
                onPressed: () => _orderRepo.updateQuantity(item.id, item.quantity + 1),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInputField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    required bool isDark,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(
          color: isDark ? Colors.white60 : Colors.black54,
          fontSize: 12,
        ),
        prefixIcon: Icon(icon, size: 18, color: HissouColors.accentAmber),
        isDense: true,
        filled: true,
        fillColor: isDark ? Colors.white.withAlpha(6) : Colors.grey.shade50,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: isDark ? Colors.white12 : Colors.grey.shade200),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: isDark ? Colors.white12 : Colors.grey.shade200),
        ),
      ),
    );
  }

  Widget _buildPaymentChip({
    required String title,
    required IconData icon,
    required bool isDark,
  }) {
    final selected = _selectedPayment == title;
    return ChoiceChip(
      selected: selected,
      onSelected: (_) => setState(() => _selectedPayment = title),
      avatar: Icon(
        icon,
        size: 16,
        color: selected ? Colors.white : HissouColors.neutralGrey,
      ),
      label: Text(
        title,
        style: TextStyle(
          fontSize: 12,
          fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
          color: selected ? Colors.white : (isDark ? Colors.white70 : Colors.black87),
        ),
      ),
      selectedColor: HissouColors.primaryNavy,
      backgroundColor: isDark ? Colors.white.withAlpha(8) : Colors.grey.shade100,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      showCheckmark: false,
    );
  }

  Widget _buildSummaryRow(
    String label,
    String value,
    bool isDark, {
    bool isFree = false,
    bool isDiscount = false,
  }) {
    Color valueColor;
    if (isFree) {
      valueColor = HissouColors.successGreen;
    } else if (isDiscount) {
      valueColor = HissouColors.softRose;
    } else {
      valueColor = isDark ? Colors.white70 : Colors.black87;
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            color: isDark ? Colors.white60 : Colors.grey.shade600,
            fontWeight: FontWeight.w500,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: valueColor,
          ),
        ),
      ],
    );
  }
}
