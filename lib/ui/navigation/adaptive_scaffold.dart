import 'dart:ui';
import 'package:flutter/material.dart';
import '../../core/responsive/responsive_layout.dart';
import '../../core/theme/app_theme.dart';
import '../../l10n.dart';
import '../features/health/health_screen.dart';
import '../features/marketplace/marketplace_screen.dart';
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

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWideScreen = constraints.maxWidth >= ResponsiveLayout.compactBreakpoint;

        final screens = [
          StoriesScreen(
            onNavigateToTranslator: () => setState(() => _currentIndex = 1),
          ),
          TranslatorScreen(
            onStoryShared: () => setState(() => _currentIndex = 0),
          ),
          const MarketplaceScreen(),
          const HealthScreen(),
        ];

        final currentLang = Localizations.localeOf(context).languageCode.toUpperCase();

        return Scaffold(
          extendBody: !isWideScreen, // Allows content to flow behind frosted floating nav
          appBar: AppBar(
            toolbarHeight: 64,
            titleSpacing: 16,
            backgroundColor: Theme.of(context).cardColor.withAlpha(240),
            surfaceTintColor: Colors.transparent,
            title: Row(
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
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          tr(context, 'title'),
                          style: TextStyle(
                            fontWeight: FontWeight.w900,
                            fontSize: 20,
                            letterSpacing: -0.6,
                            color: Theme.of(context).brightness == Brightness.dark
                                ? Colors.white
                                : HissouColors.primaryNavy,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: HissouColors.accentAmber.withAlpha(35),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Text(
                            'AI',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              color: HissouColors.accentAmberDark,
                            ),
                          ),
                        ),
                      ],
                    ),
                    Text(
                      tr(context, 'tagline'),
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: Theme.of(context).brightness == Brightness.dark
                            ? Colors.white70
                            : HissouColors.neutralGrey,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            actions: [
              Container(
                margin: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: Theme.of(context).brightness == Brightness.dark
                      ? Colors.white.withAlpha(15)
                      : HissouColors.backgroundLight,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: Theme.of(context).brightness == Brightness.dark
                        ? Colors.white12
                        : HissouColors.borderSubtle,
                  ),
                ),
                child: PopupMenuButton<String>(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  icon: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.language, size: 16, color: HissouColors.primaryNavyLight),
                      const SizedBox(width: 4),
                      Text(
                        currentLang,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: HissouColors.primaryNavy,
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
              const SizedBox(width: 14),
            ],
          ),
          body: isWideScreen
              ? Row(
                  children: [
                    NavigationRail(
                      selectedIndex: _currentIndex,
                      onDestinationSelected: (i) => setState(() => _currentIndex = i),
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
                    Expanded(child: screens[_currentIndex]),
                  ],
                )
              : Stack(
                  children: [
                    Positioned.fill(
                      bottom: 84, // Reserve space for the floating nav
                      child: screens[_currentIndex],
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
        filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
        child: Container(
          height: 68,
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          decoration: BoxDecoration(
            color: isDark
                ? HissouColors.cardSurfaceDark.withAlpha(220)
                : Colors.white.withAlpha(235),
            borderRadius: BorderRadius.circular(26),
            border: Border.all(
              color: isDark ? Colors.white.withAlpha(25) : Colors.white,
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: HissouColors.primaryNavy.withAlpha(isDark ? 80 : 30),
                blurRadius: 28,
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
                  onTap: () => setState(() => _currentIndex = index),
                  behavior: HitTestBehavior.opaque,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 260),
                    curve: Curves.easeOutCubic,
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
                          duration: const Duration(milliseconds: 200),
                          scale: isSelected ? 1.15 : 1.0,
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
                            fontWeight: isSelected ? FontWeight.w800 : FontWeight.w500,
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
