import 'package:flutter/material.dart';
import '../../../core/responsive/responsive_layout.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/models/market_listing.dart';
import '../../../data/models/order.dart';
import '../../../data/repositories/market_repository.dart';
import '../../../data/repositories/order_repository.dart';
import '../../../l10n.dart';
import '../orders/orders_screen.dart';
import 'cart_sheet.dart';

class MarketplaceScreen extends StatefulWidget {
  const MarketplaceScreen({super.key});

  @override
  State<MarketplaceScreen> createState() => _MarketplaceScreenState();
}

class _MarketplaceScreenState extends State<MarketplaceScreen>
    with SingleTickerProviderStateMixin {
  final _marketRepo = MarketRepository();
  final _orderRepo = OrderRepository();
  late TabController _tabController;
  List<MarketListing> _listings = [];
  bool _loading = true;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        _loadData();
      }
    });
    _orderRepo.addListener(_onCartChanged);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _orderRepo.removeListener(_onCartChanged);
    super.dispose();
  }

  void _onCartChanged() {
    if (mounted) setState(() {});
  }

  MarketCategory get _currentCategory {
    switch (_tabController.index) {
      case 0:
        return MarketCategory.supplies; // Default to products for commerce
      case 1:
        return MarketCategory.services;
      case 2:
      default:
        return MarketCategory.adoption;
    }
  }

  Future<void> _loadData() async {
    setState(() => _loading = true);
    final items = await _marketRepo.getListings(category: _currentCategory);
    if (mounted) {
      setState(() {
        _listings = items;
        _loading = false;
      });
    }
  }

  void _addToCart(MarketListing item, {bool openCartImmediately = false}) {
    _orderRepo.addToCart(
      OrderItem(
        id: item.id,
        title: item.title,
        price: item.price,
        currency: item.currency,
        quantity: 1,
        category: item.category.name,
      ),
    );

    if (openCartImmediately) {
      CartSheet.show(context, onOrderPlaced: () {
        setState(() {});
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  '${item.title} ajouté au panier !',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          backgroundColor: HissouColors.primaryNavy,
          action: SnackBarAction(
            label: 'Voir Panier',
            textColor: HissouColors.accentAmber,
            onPressed: () {
              CartSheet.show(context, onOrderPlaced: () {
                setState(() {});
              });
            },
          ),
          duration: const Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
      );
    }
  }

  void _showAddListingDialog() {
    final titleCtl = TextEditingController();
    final descCtl = TextEditingController();
    final priceCtl = TextEditingController();
    final locCtl = TextEditingController();
    final phoneCtl = TextEditingController();
    MarketCategory category = _currentCategory;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) {
          final isDark = Theme.of(ctx).brightness == Brightness.dark;
          return Container(
            padding: EdgeInsets.only(
              left: 24,
              right: 24,
              top: 20,
              bottom: MediaQuery.of(ctx).viewInsets.bottom + 28,
            ),
            decoration: BoxDecoration(
              color: isDark ? HissouColors.cardSurfaceDark : Colors.white,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
              boxShadow: const [
                BoxShadow(
                  color: Colors.black26,
                  blurRadius: 20,
                  offset: Offset(0, -6),
                ),
              ],
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 48,
                      height: 5,
                      decoration: BoxDecoration(
                        color: isDark ? Colors.white24 : Colors.grey.withAlpha(90),
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  Text(
                    tr(context, 'add_listing'),
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w900,
                          letterSpacing: -0.5,
                          color: isDark ? Colors.white : HissouColors.primaryNavy,
                        ),
                  ),
                  const SizedBox(height: 16),
                  SegmentedButton<MarketCategory>(
                    segments: const [
                      ButtonSegment(
                        value: MarketCategory.supplies,
                        label: Text('Produits', style: TextStyle(fontSize: 12)),
                        icon: Icon(Icons.shopping_bag_rounded, size: 16),
                      ),
                      ButtonSegment(
                        value: MarketCategory.services,
                        label: Text('Services', style: TextStyle(fontSize: 12)),
                        icon: Icon(Icons.medical_services_rounded, size: 16),
                      ),
                      ButtonSegment(
                        value: MarketCategory.adoption,
                        label: Text('Adoption', style: TextStyle(fontSize: 12)),
                        icon: Icon(Icons.favorite_rounded, size: 16),
                      ),
                    ],
                    selected: {category},
                    onSelectionChanged: (set) {
                      setDialogState(() => category = set.first);
                    },
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    controller: titleCtl,
                    decoration: InputDecoration(
                      labelText: tr(context, 'listing_title'),
                      prefixIcon: const Icon(Icons.title_rounded),
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (category != MarketCategory.adoption) ...[
                    TextField(
                      controller: priceCtl,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: 'Prix (TND)',
                        prefixIcon: const Icon(Icons.monetization_on_outlined),
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],
                  TextField(
                    controller: locCtl,
                    decoration: InputDecoration(
                      labelText: tr(context, 'listing_location'),
                      prefixIcon: const Icon(Icons.location_on_outlined),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: phoneCtl,
                    keyboardType: TextInputType.phone,
                    decoration: InputDecoration(
                      labelText: tr(context, 'listing_contact'),
                      prefixIcon: const Icon(Icons.phone_outlined),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: descCtl,
                    maxLines: 3,
                    decoration: InputDecoration(
                      labelText: tr(context, 'listing_desc'),
                      alignLabelWithHint: true,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.pop(ctx),
                        child: Text(tr(context, 'cancel')),
                      ),
                      const SizedBox(width: 12),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: HissouColors.accentAmber,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                        ),
                        onPressed: () async {
                          final title = titleCtl.text.trim();
                          if (title.isEmpty) return;
                          final price = double.tryParse(priceCtl.text.trim()) ?? 0.0;
                          final item = MarketListing(
                            id: 'mkt_${DateTime.now().millisecondsSinceEpoch}',
                            title: title,
                            description: descCtl.text.trim(),
                            category: category,
                            price: category == MarketCategory.adoption ? 0.0 : price,
                            currency: 'TND',
                            location: locCtl.text.trim().isEmpty ? 'Grand Tunis' : locCtl.text.trim(),
                            contactPhone: phoneCtl.text.trim().isEmpty ? '+216 71 000 000' : phoneCtl.text.trim(),
                            isVerified: true,
                          );
                          await _marketRepo.addListing(item);
                          if (ctx.mounted) Navigator.pop(ctx);
                          _loadData();
                        },
                        child: Text(tr(context, 'save')),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final filtered = _listings.where((l) {
      if (_searchQuery.isEmpty) return true;
      final q = _searchQuery.toLowerCase();
      return l.title.toLowerCase().contains(q) ||
          l.description.toLowerCase().contains(q) ||
          l.location.toLowerCase().contains(q);
    }).toList();

    return Stack(
      children: [
        ResponsiveLayout.constrainedContainer(
          child: Column(
            children: [
              // Search & Header
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                child: Column(
                  children: [
                    // Top Bar
                    Row(
                      children: [
                        Text(
                          'Boutique Hissou',
                          style: TextStyle(
                            fontWeight: FontWeight.w900,
                            fontSize: 22,
                            letterSpacing: -0.6,
                            color: isDark ? Colors.white : HissouColors.primaryNavy,
                          ),
                        ),
                        const Spacer(),
                        // Mes Commandes Button
                        TextButton.icon(
                          onPressed: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(builder: (_) => const OrdersScreen()),
                            );
                          },
                          icon: const Icon(Icons.receipt_long_rounded, size: 18),
                          label: const Text('Commandes'),
                          style: TextButton.styleFrom(
                            foregroundColor: HissouColors.accentAmberDark,
                            backgroundColor: HissouColors.accentAmber.withAlpha(25),
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                        const SizedBox(width: 8),
                        IconButton.filledTonal(
                          style: IconButton.styleFrom(
                            backgroundColor: isDark ? Colors.white12 : Colors.grey.shade100,
                          ),
                          onPressed: _showAddListingDialog,
                          icon: const Icon(Icons.add_rounded, size: 20),
                          tooltip: 'Ajouter une annonce',
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Commerce Promo Banner
                    _buildPromoBanner(isDark),
                    const SizedBox(height: 12),

                    // Search Field
                    TextField(
                      onChanged: (v) => setState(() => _searchQuery = v),
                      decoration: InputDecoration(
                        hintText: 'Rechercher croquettes, litière, véto...',
                        prefixIcon: const Icon(Icons.search_rounded, color: HissouColors.accentAmber),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Tabs
                    Container(
                      height: 48,
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: isDark ? HissouColors.cardSurfaceDark : const Color(0xFFECEFF5),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: TabBar(
                        controller: _tabController,
                        indicator: BoxDecoration(
                          color: isDark ? HissouColors.accentAmber : HissouColors.primaryNavy,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: (isDark ? HissouColors.accentAmber : HissouColors.primaryNavy).withAlpha(50),
                              blurRadius: 8,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        indicatorSize: TabBarIndicatorSize.tab,
                        labelColor: Colors.white,
                        unselectedLabelColor: isDark ? Colors.white70 : HissouColors.neutralGrey,
                        dividerColor: Colors.transparent,
                        labelStyle: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
                        tabs: const [
                          Tab(text: 'Produits & Nutrition'),
                          Tab(text: 'Services & Soins'),
                          Tab(text: 'Adoption'),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // List content
              Expanded(
                child: _loading
                    ? const Center(child: CircularProgressIndicator(color: HissouColors.accentAmber))
                    : filtered.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.storefront_outlined, size: 54, color: Colors.grey.withAlpha(120)),
                                const SizedBox(height: 12),
                                Text(
                                  'Aucun article trouvé',
                                  style: TextStyle(
                                    color: isDark ? Colors.white54 : HissouColors.neutralGrey,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          )
                        : RefreshIndicator(
                            onRefresh: _loadData,
                            color: HissouColors.accentAmber,
                            child: ListView.builder(
                              padding: const EdgeInsets.fromLTRB(16, 4, 16, 100),
                              itemCount: filtered.length,
                              itemBuilder: (context, idx) {
                                return _buildListingCard(filtered[idx], isDark);
                              },
                            ),
                          ),
              ),
            ],
          ),
        ),

        // Floating Cart Pill (Visible when cart has items)
        if (_orderRepo.cartCount > 0)
          Positioned(
            left: 20,
            right: 20,
            bottom: 24,
            child: _buildFloatingCartPill(isDark),
          ),
      ],
    );
  }

  Widget _buildPromoBanner(bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [HissouColors.primaryNavy, HissouColors.primaryNavyLight],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: HissouColors.primaryNavy.withAlpha(50),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: HissouColors.accentAmber,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.bolt_rounded,
              color: HissouColors.primaryNavyDark,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text(
                  'Livraison Express & -10 TND avec HISSOU10',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 13,
                  ),
                ),
                Text(
                  'Commandez vos articles félins livrés sous 24h partout en Tunisie.',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildListingCard(MarketListing item, bool isDark) {
    final isAdopt = item.category == MarketCategory.adoption;

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: isDark ? HissouColors.cardSurfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: isDark ? Colors.white12 : HissouColors.borderSubtle,
        ),
        boxShadow: [
          BoxShadow(
            color: HissouColors.primaryNavy.withAlpha(isDark ? 40 : 10),
            blurRadius: 16,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: isAdopt
                        ? HissouColors.softRose.withAlpha(30)
                        : item.category == MarketCategory.supplies
                            ? HissouColors.accentAmber.withAlpha(30)
                            : HissouColors.warmPlum.withAlpha(30),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(
                    isAdopt
                        ? Icons.favorite_rounded
                        : item.category == MarketCategory.supplies
                            ? Icons.inventory_2_rounded
                            : Icons.medical_services_rounded,
                    color: isAdopt
                        ? HissouColors.softRose
                        : item.category == MarketCategory.supplies
                            ? HissouColors.accentAmberDark
                            : HissouColors.warmPlum,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          if (item.isVerified)
                            Container(
                              margin: const EdgeInsets.only(right: 6),
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: HissouColors.successGreen.withAlpha(30),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: const [
                                  Icon(Icons.verified_rounded, size: 12, color: HissouColors.successGreen),
                                  SizedBox(width: 3),
                                  Text(
                                    'Vérifié Hissou',
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: HissouColors.successGreen,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          const Spacer(),
                          Text(
                            isAdopt
                                ? 'Adoption Gratuite'
                                : '${item.price.toStringAsFixed(1)} ${item.currency}',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w900,
                              color: isAdopt ? HissouColors.softRose : HissouColors.accentAmberDark,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        item.title,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: isDark ? Colors.white : HissouColors.primaryNavy,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(Icons.location_on_outlined, size: 14, color: HissouColors.neutralGrey),
                          const SizedBox(width: 4),
                          Text(
                            item.location,
                            style: const TextStyle(
                              fontSize: 12,
                              color: HissouColors.neutralGrey,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(width: 8),
                          if (!isAdopt) ...[
                            Container(
                              width: 4,
                              height: 4,
                              decoration: const BoxDecoration(
                                color: HissouColors.neutralGrey,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 8),
                            const Icon(Icons.bolt_rounded, size: 14, color: HissouColors.accentAmberDark),
                            const Text(
                              'En Stock Express',
                              style: TextStyle(
                                fontSize: 11,
                                color: HissouColors.accentAmberDark,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              item.description,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 13,
                height: 1.4,
                color: isDark ? Colors.white70 : const Color(0xFF374151),
              ),
            ),
            const SizedBox(height: 16),

            // Action Buttons
            if (isAdopt)
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: isDark ? Colors.white : HissouColors.primaryNavy,
                      side: BorderSide(
                        color: isDark ? Colors.white24 : HissouColors.primaryNavy,
                        width: 1.5,
                      ),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    ),
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Appel du refuge au ${item.contactPhone}...'),
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    },
                    icon: const Icon(Icons.phone_rounded, size: 16),
                    label: const Text(
                      'Contacter le Refuge',
                      style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                    ),
                  ),
                ],
              )
            else
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: isDark ? Colors.white : HissouColors.primaryNavy,
                        side: BorderSide(
                          color: isDark ? Colors.white24 : HissouColors.primaryNavy.withAlpha(60),
                          width: 1.5,
                        ),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      onPressed: () => _addToCart(item, openCartImmediately: false),
                      icon: const Icon(Icons.add_shopping_cart_rounded, size: 18),
                      label: const Text(
                        'Ajouter au Panier',
                        style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: HissouColors.primaryNavy,
                        foregroundColor: Colors.white,
                        elevation: 2,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      onPressed: () => _addToCart(item, openCartImmediately: true),
                      icon: const Icon(Icons.flash_on_rounded, size: 18, color: HissouColors.accentAmber),
                      label: const Text(
                        'Commander',
                        style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
                      ),
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildFloatingCartPill(bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
      decoration: BoxDecoration(
        color: HissouColors.primaryNavyDark,
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(
            color: Colors.black45,
            blurRadius: 20,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: const BoxDecoration(
              color: HissouColors.accentAmber,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.shopping_bag_rounded,
              color: HissouColors.primaryNavyDark,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '${_orderRepo.cartCount} article(s) dans le panier',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 13,
                  ),
                ),
                Text(
                  'Total : ${_orderRepo.cartSubtotal.toStringAsFixed(1)} TND',
                  style: const TextStyle(
                    color: HissouColors.accentAmber,
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          ElevatedButton(
            onPressed: () {
              CartSheet.show(context, onOrderPlaced: () {
                setState(() {});
              });
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: HissouColors.primaryNavyDark,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text(
              'Voir Panier',
              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }
}
