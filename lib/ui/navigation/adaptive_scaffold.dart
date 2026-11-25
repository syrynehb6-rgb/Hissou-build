import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/responsive/responsive_layout.dart';
import '../../core/theme/app_theme.dart';
import '../../data/repositories/order_repository.dart';
import '../../l10n.dart';
import '../features/auth/splash_screen.dart';
import '../features/health/health_screen.dart';
import '../features/marketplace/cart_sheet.dart';
import '../features/marketplace/marketplace_screen.dart';
import '../features/orders/orders_screen.dart';
import '../features/stories/stories_screen.dart';
import '../features/translator/translator_screen.dart';

class AdaptiveScaffold extends StatefulWidget {
  final ValueChanged<Locale> onLocaleChanged;

  const AdaptiveScaffold({super.key, required this.onLocaleChanged});

  @override
  State<AdaptiveScaffold> createState() => _AdaptiveScaffoldState();
}

class _AdaptiveScaffoldState extends State<AdaptiveScaffold> {
  int _currentIndex = 0;
  final _orderRepo = OrderRepository();
  String _userName = 'Syrine';
  String _userEmail = 'syrine@hissou.app';

  @override
  void initState() {
    super.initState();
    _orderRepo.addListener(_onCartChanged);
    _loadUserProfile();
  }

  Future<void> _loadUserProfile() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted) {
      setState(() {
        _userName = prefs.getString('hissou_user_name') ?? 'Syrine';
        _userEmail = prefs.getString('hissou_user_email') ?? 'syrine@hissou.app';
      });
    }
  }

  @override
  void dispose() {
    _orderRepo.removeListener(_onCartChanged);
    super.dispose();
  }

  void _onCartChanged() {
    if (mounted) setState(() {});
  }

  void _showProfileSheet(BuildContext context, bool isDark) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
        decoration: BoxDecoration(
          color: isDark ? HissouColors.cardSurfaceDark : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
          boxShadow: const [
            BoxShadow(color: Colors.black38, blurRadius: 30, offset: Offset(0, -10)),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 44,
              height: 4,
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                color: isDark ? Colors.white24 : Colors.black12,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Row(
              children: [
                Container(
                  width: 58,
                  height: 58,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: [HissouColors.accentAmber, HissouColors.softRose],
                    ),
                  ),
                  child: const Center(
                    child: Icon(Icons.person_rounded, color: Colors.white, size: 30),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            _userName,
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w900,
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
                            child: const Text(
                              'VIP PRO',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w900,
                                color: HissouColors.accentAmberDark,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _userEmail,
                        style: const TextStyle(
                          fontSize: 12,
                          color: HissouColors.neutralGrey,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            const Divider(height: 1),
            const SizedBox(height: 12),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: HissouColors.accentAmber.withAlpha(25),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  isDark ? Icons.dark_mode_rounded : Icons.light_mode_rounded,
                  color: HissouColors.accentAmberDark,
                ),
              ),
              title: Text(
                'Mode Sombre (Dark Mode)',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                  color: isDark ? Colors.white : HissouColors.primaryNavy,
                ),
              ),
              trailing: Switch(
                value: isDark,
                activeThumbColor: HissouColors.accentAmber,
                onChanged: (_) {
                  HissouThemeController.toggleTheme();
                  Navigator.pop(ctx);
                },
              ),
            ),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: HissouColors.successGreen.withAlpha(25),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.receipt_long_rounded,
                  color: HissouColors.successGreen,
                ),
              ),
              title: Text(
                'Mes Commandes & Livraisons',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                  color: isDark ? Colors.white : HissouColors.primaryNavy,
                ),
              ),
              trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14),
              onTap: () {
                Navigator.pop(ctx);
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const OrdersScreen()),
                );
              },
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  foregroundColor: HissouColors.softRose,
                  side: const BorderSide(color: HissouColors.softRose),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                onPressed: () async {
                  final prefs = await SharedPreferences.getInstance();
                  await prefs.setBool('hissou_user_logged_in', false);
                  await prefs.setBool('hissou_privacy_accepted', false);
                  if (!ctx.mounted) return;
                  Navigator.pop(ctx);
                  if (!context.mounted) return;
                  Navigator.of(context).pushReplacement(
                    MaterialPageRoute(
                      builder: (_) => SplashScreen(onLocaleChanged: widget.onLocaleChanged),
                    ),
                  );
                },
                icon: const Icon(Icons.logout_rounded, size: 18),
                label: const Text(
                  'Se Déconnecter & Revoir l\'Intro Animée',
                  style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWideScreen = constraints.maxWidth >= ResponsiveLayout.compactBreakpoint;
        final isDark = Theme.of(context).brightness == Brightness.dark;

        final screens = [
          StoriesScreen(
            key: const ValueKey('tab_stories'),
            onNavigateToTranslator: () => setState(() => _currentIndex = 1),
          ),
          TranslatorScreen(
            key: const ValueKey('tab_translator'),
            onStoryShared: () => setState(() => _currentIndex = 0),
          ),
          const MarketplaceScreen(key: ValueKey('tab_market')),
          const HealthScreen(key: ValueKey('tab_health')),
        ];

        final currentLang = Localizations.localeOf(context).languageCode.toUpperCase();
        final cartCount = _orderRepo.cartCount;

        return Scaffold(
          extendBody: !isWideScreen,
          appBar: AppBar(
            toolbarHeight: 64,
            titleSpacing: 16,
            backgroundColor: Theme.of(context).cardColor.withAlpha(240),
            surfaceTintColor: Colors.transparent,
            title: GestureDetector(
              onTap: () => _showProfileSheet(context, isDark),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(14),
                      gradient: const LinearGradient(
                        colors: [HissouColors.accentAmber, HissouColors.softRose],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: HissouColors.accentAmber.withAlpha(50),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.asset(
                        'assets/images/logo.png',
                        width: 36,
                        height: 36,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                tr(context, 'title'),
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontWeight: FontWeight.w900,
                                  fontSize: 19,
                                  letterSpacing: -0.6,
                                  color: isDark ? Colors.white : HissouColors.primaryNavy,
                                ),
                              ),
                            ),
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [HissouColors.accentAmber, HissouColors.softRose],
                                ),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: const Text(
                                'PRO',
                                style: TextStyle(
                                  fontSize: 9,
                                  fontWeight: FontWeight.w900,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ],
                        ),
                        Text(
                          'Bonjour $_userName ✨',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: isDark ? Colors.white70 : HissouColors.neutralGrey,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              // Animated Dark/Light Mode Switcher
              IconButton(
                tooltip: isDark ? 'Mode Clair' : 'Mode Sombre',
                onPressed: HissouThemeController.toggleTheme,
                icon: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  transitionBuilder: (child, anim) => RotationTransition(
                    turns: Tween<double>(begin: 0.75, end: 1.0).animate(anim),
                    child: ScaleTransition(scale: anim, child: child),
                  ),
                  child: Icon(
                    isDark ? Icons.light_mode_rounded : Icons.dark_mode_outlined,
                    key: ValueKey<bool>(isDark),
                    size: 21,
                    color: isDark ? HissouColors.accentAmber : HissouColors.primaryNavy,
                  ),
                ),
              ),

              // Shopping Cart Action Button with Animated Badge
              Stack(
                alignment: Alignment.center,
                children: [
                  IconButton(
                    icon: const Icon(Icons.shopping_bag_outlined, size: 22),
                    color: isDark ? Colors.white : HissouColors.primaryNavy,
                    tooltip: 'Panier d\'achats',
                    onPressed: () {
                      CartSheet.show(context, onOrderPlaced: () => setState(() {}));
                    },
                  ),
                  if (cartCount > 0)
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: HissouColors.softRose,
                          shape: BoxShape.circle,
                        ),
                        constraints: const BoxConstraints(minWidth: 17, minHeight: 17),
                        child: Center(
                          child: Text(
                            '$cartCount',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 9,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),

              // Profile & Settings Drawer trigger
              IconButton(
                icon: const Icon(Icons.account_circle_outlined, size: 22),
                color: isDark ? Colors.white : HissouColors.primaryNavy,
                tooltip: 'Mon Profil',
                onPressed: () => _showProfileSheet(context, isDark),
              ),

              // Language selector
              Container(
                margin: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: isDark ? Colors.white.withAlpha(15) : HissouColors.backgroundLight,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isDark ? Colors.white12 : HissouColors.borderSubtle,
                  ),
                ),
                child: PopupMenuButton<String>(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  icon: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.language, size: 15, color: HissouColors.accentAmberDark),
                      const SizedBox(width: 3),
                      Text(
                        currentLang,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color: isDark ? Colors.white : HissouColors.primaryNavy,
                        ),
                      ),
                    ],
                  ),
                  onSelected: (code) => widget.onLocaleChanged(Locale(code)),
                  itemBuilder: (_) => const [
                    PopupMenuItem(value: 'en', child: Text('English')),
                    PopupMenuItem(value: 'fr', child: Text('Français')),
                    PopupMenuItem(value: 'ar', child: Text('العربية')),
                  ],
                ),
              ),
              const SizedBox(width: 8),
            ],
          ),
          body: isWideScreen
              ? Row(
                  children: [
                    NavigationRail(
                      selectedIndex: _currentIndex,
                      onDestinationSelected: (i) {
                        HapticFeedback.selectionClick();
                        setState(() => _currentIndex = i);
                      },
                      labelType: NavigationRailLabelType.all,
                      backgroundColor: Theme.of(context).cardColor,
                      selectedIconTheme: const IconThemeData(color: HissouColors.primaryNavy),
                      selectedLabelTextStyle: const TextStyle(
                        color: HissouColors.primaryNavy,
                        fontWeight: FontWeight.w800,
                      ),
                      destinations: [
                        NavigationRailDestination(
                          icon: const Icon(Icons.auto_stories_outlined),
                          selectedIcon: const Icon(Icons.auto_stories),
                          label: Text(tr(context, 'nav_stories')),
                        ),
                        NavigationRailDestination(
                          icon: const Icon(Icons.mic_none_rounded),
                          selectedIcon: const Icon(Icons.mic_rounded),
                          label: Text(tr(context, 'nav_translator')),
                        ),
                        NavigationRailDestination(
                          icon: const Icon(Icons.storefront_outlined),
                          selectedIcon: const Icon(Icons.storefront),
                          label: Text(tr(context, 'nav_market')),
                        ),
                        NavigationRailDestination(
                          icon: const Icon(Icons.health_and_safety_outlined),
                          selectedIcon: const Icon(Icons.health_and_safety),
                          label: Text(tr(context, 'nav_health')),
                        ),
                      ],
                    ),
                    const VerticalDivider(thickness: 1, width: 1),
                    Expanded(
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 280),
                        switchInCurve: Curves.easeOutCubic,
                        switchOutCurve: Curves.easeInCubic,
                        child: screens[_currentIndex],
                      ),
                    ),
                  ],
                )
              : Stack(
                  children: [
                    Positioned.fill(
                      bottom: 84,
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 280),
                        switchInCurve: Curves.easeOutCubic,
                        switchOutCurve: Curves.easeInCubic,
                        transitionBuilder: (child, animation) {
                          return FadeTransition(
                            opacity: animation,
                            child: SlideTransition(
                              position: Tween<Offset>(
                                begin: const Offset(0.0, 0.02),
                                end: Offset.zero,
                              ).animate(animation),
                              child: child,
                            ),
                          );
                        },
                        child: screens[_currentIndex],
                      ),
                    ),
                    Positioned(
                      left: 16,
                      right: 16,
                      bottom: 14,
                      child: _buildModernFloatingNavBar(context),
                    ),
                  ],
                ),
        );
      },
    );
  }

  Widget _buildModernFloatingNavBar(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final items = [
      {'icon': Icons.auto_stories_outlined, 'activeIcon': Icons.auto_stories, 'label': tr(context, 'nav_stories')},
      {'icon': Icons.mic_none_rounded, 'activeIcon': Icons.mic_rounded, 'label': tr(context, 'nav_translator')},
      {'icon': Icons.storefront_outlined, 'activeIcon': Icons.storefront, 'label': tr(context, 'nav_market')},
      {'icon': Icons.health_and_safety_outlined, 'activeIcon': Icons.health_and_safety, 'label': tr(context, 'nav_health')},
    ];

    return ClipRRect(
      borderRadius: BorderRadius.circular(26),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          height: 68,
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          decoration: BoxDecoration(
            color: isDark
                ? HissouColors.cardSurfaceDark.withAlpha(225)
                : Colors.white.withAlpha(235),
            borderRadius: BorderRadius.circular(26),
            border: Border.all(
              color: isDark ? Colors.white.withAlpha(30) : Colors.white,
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: HissouColors.primaryNavyDark.withAlpha(isDark ? 90 : 35),
                blurRadius: 30,
                spreadRadius: 2,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: List.generate(items.length, (index) {
              final isSelected = _currentIndex == index;
              final item = items[index];

              return Expanded(
                child: GestureDetector(
                  onTap: () {
                    HapticFeedback.selectionClick();
                    setState(() => _currentIndex = index);
                  },
                  behavior: HitTestBehavior.opaque,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 260),
                    curve: Curves.easeOutBack,
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? (isDark
                              ? HissouColors.accentAmber.withAlpha(35)
                              : HissouColors.primaryNavy.withAlpha(15))
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        AnimatedScale(
                          duration: const Duration(milliseconds: 220),
                          curve: Curves.easeOutBack,
                          scale: isSelected ? 1.18 : 1.0,
                          child: Icon(
                            isSelected ? (item['activeIcon'] as IconData) : (item['icon'] as IconData),
                            size: 22,
                            color: isSelected
                                ? (isDark ? HissouColors.accentAmber : HissouColors.primaryNavy)
                                : (isDark ? Colors.white54 : HissouColors.neutralGrey),
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          item['label'] as String,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: isSelected ? FontWeight.w900 : FontWeight.w500,
                            color: isSelected
                                ? (isDark ? HissouColors.accentAmber : HissouColors.primaryNavy)
                                : (isDark ? Colors.white54 : HissouColors.neutralGrey),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}
