import 'package:flutter/material.dart';
import '../../../core/responsive/responsive_layout.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/models/market_listing.dart';
import '../../../data/repositories/market_repository.dart';
import '../../../l10n.dart';

class MarketplaceScreen extends StatefulWidget {
  const MarketplaceScreen({super.key});

  @override
  State<MarketplaceScreen> createState() => _MarketplaceScreenState();
}

class _MarketplaceScreenState extends State<MarketplaceScreen>
    with SingleTickerProviderStateMixin {
  final _marketRepo = MarketRepository();
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
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  MarketCategory get _currentCategory {
    switch (_tabController.index) {
      case 0:
        return MarketCategory.adoption;
      case 1:
        return MarketCategory.supplies;
      case 2:
      default:
        return MarketCategory.services;
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
                    segments: [
                      ButtonSegment(
                        value: MarketCategory.adoption,
                        label: Text(tr(context, 'tab_adopt'), style: const TextStyle(fontSize: 12)),
                        icon: const Icon(Icons.favorite_rounded, size: 16),
                      ),
                      ButtonSegment(
                        value: MarketCategory.supplies,
                        label: Text(tr(context, 'tab_supplies'), style: const TextStyle(fontSize: 12)),
                        icon: const Icon(Icons.shopping_bag_rounded, size: 16),
                      ),
                      ButtonSegment(
                        value: MarketCategory.services,
                        label: Text(tr(context, 'tab_services'), style: const TextStyle(fontSize: 12)),
                        icon: const Icon(Icons.medical_services_rounded, size: 16),
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
                        labelText: tr(context, 'listing_price'),
                        prefixIcon: const Icon(Icons.attach_money_rounded),
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
                            location: locCtl.text.trim().isEmpty ? 'Local Community' : locCtl.text.trim(),
                            contactPhone: phoneCtl.text.trim().isEmpty ? '+1 (555) 0123' : phoneCtl.text.trim(),
                            isVerified: category == MarketCategory.adoption,
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

    return ResponsiveLayout.constrainedContainer(
      child: Column(
        children: [
          // Search & Header
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      tr(context, 'market_title'),
                      style: TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 20,
                        letterSpacing: -0.5,
                        color: isDark ? Colors.white : HissouColors.primaryNavy,
                      ),
                    ),
                    FilledButton.icon(
                      style: FilledButton.styleFrom(
                        backgroundColor: HissouColors.accentAmber,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      onPressed: _showAddListingDialog,
                      icon: const Icon(Icons.add_rounded, size: 18),
                      label: Text(
                        tr(context, 'add_listing'),
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                TextField(
                  onChanged: (v) => setState(() => _searchQuery = v),
                  decoration: InputDecoration(
                    hintText: tr(context, 'search_market'),
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
                    tabs: [
                      Tab(text: tr(context, 'tab_adopt')),
                      Tab(text: tr(context, 'tab_supplies')),
                      Tab(text: tr(context, 'tab_services')),
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
                              tr(context, 'empty_market'),
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
                          padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                          itemCount: filtered.length,
                          itemBuilder: (context, idx) {
                            return _buildListingCard(filtered[idx], isDark);
                          },
                        ),
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
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: isAdopt
                        ? HissouColors.softRose.withAlpha(30)
                        : HissouColors.accentAmber.withAlpha(30),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(
                    isAdopt
                        ? Icons.favorite_rounded
                        : item.category == MarketCategory.supplies
                            ? Icons.shopping_bag_rounded
                            : Icons.medical_services_rounded,
                    color: isAdopt ? HissouColors.softRose : HissouColors.accentAmberDark,
                    size: 26,
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
                                children: [
                                  const Icon(Icons.verified_rounded, size: 12, color: HissouColors.successGreen),
                                  const SizedBox(width: 3),
                                  Text(
                                    tr(context, 'verified_shelter'),
                                    style: const TextStyle(
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
                                ? tr(context, 'free_adoption')
                                : '${item.currency}${item.price.toStringAsFixed(0)}',
                            style: TextStyle(
                              fontSize: 17,
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
            const SizedBox(height: 14),
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
                        content: Text('Contacting ${item.contactPhone}...'),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  },
                  icon: const Icon(Icons.chat_bubble_outline_rounded, size: 16),
                  label: Text(
                    tr(context, 'contact_seller'),
                    style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
