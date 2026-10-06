import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../providers/news_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/executive_card_view.dart';

class FeedView extends StatefulWidget {
  const FeedView({super.key});

  @override
  State<FeedView> createState() => _FeedViewState();
}


class SnappyPageScrollPhysics extends PageScrollPhysics {
  const SnappyPageScrollPhysics({super.parent = const ClampingScrollPhysics()});

  @override
  SnappyPageScrollPhysics applyTo(ScrollPhysics? ancestor) {
    return SnappyPageScrollPhysics(parent: buildParent(ancestor));
  }

  @override
  SpringDescription get spring => const SpringDescription(
    mass: 0.50,
    stiffness: 110.0,
    damping: 18.0, // Critically damped: zero upside-down oscillation or overshoot
  );

  double _getPage(ScrollMetrics position) {
    return position.pixels / position.viewportDimension;
  }

  double _getPixels(ScrollMetrics position, double page) {
    return page * position.viewportDimension;
  }

  @override
  Simulation? createBallisticSimulation(ScrollMetrics position, double velocity) {
    if ((velocity <= 0.0 && position.pixels <= position.minScrollExtent) ||
        (velocity >= 0.0 && position.pixels >= position.maxScrollExtent)) {
      return super.createBallisticSimulation(position, velocity);
    }
    
    final Tolerance tolerance = toleranceFor(position);
    final double page = _getPage(position);
    
    double targetPage;
    // Flick gesture (> 40 dp/s): snap directly in velocity direction
    if (velocity.abs() > 40.0) {
      targetPage = velocity > 0 ? page.ceilToDouble() : page.floorToDouble();
    } else {
      // Drag & release gesture: 30% delta guarantees crisp page advance without rubberband bounce
      final double fraction = page - page.floor();
      if (fraction > 0.30) {
        targetPage = page.ceilToDouble();
      } else {
        targetPage = page.floorToDouble();
      }
    }
    
    final double targetPixels = _getPixels(position, targetPage);
    
    if (targetPixels != position.pixels) {
      return ScrollSpringSimulation(spring, position.pixels, targetPixels, velocity, tolerance: tolerance);
    }
    return null;
  }
}

class _FeedViewState extends State<FeedView> {
  late final PageController _pageController;
  NewsProvider? _newsProvider;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _newsProvider = context.read<NewsProvider>();
    _newsProvider?.onScrollToTopRequested = _scrollToTop;
  }

  void _scrollToTop() {
    if (_pageController.hasClients) {
      _pageController.animateToPage(
        0,
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeOutCubic,
      );
    }
  }

  @override
  void dispose() {
    if (_newsProvider?.onScrollToTopRequested == _scrollToTop) {
      _newsProvider?.onScrollToTopRequested = null;
    }
    _newsProvider = null;
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<NewsProvider>();
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final articles = provider.articles;

    // 1. Initial Loading State: Skeleton Shimmer Card
    if (provider.isLoading && articles.isEmpty) {
      return _buildSkeletonLoader(isDark);
    }

    // 2. Error State
    if (provider.errorMessage != null && articles.isEmpty) {
      return _buildErrorState(context, provider, isDark);
    }

    // 3. Empty State (Filter mismatch or zero articles)
    if (articles.isEmpty) {
      return _buildEmptyState(context, provider, isDark);
    }

    // 4. Main Executive Card Stream & Dedicated Quick Filter Header
    return Column(
      children: [
        // Top Topic Filter Quick Chips (Dedicated non-overlapping header bar)
        Container(
          height: 38,
          margin: const EdgeInsets.only(top: 4, bottom: 4),
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 14),
            physics: const BouncingScrollPhysics(),
            children: [
              _buildQuickFilterChip(
                label: 'All Feed',
                icon: Icons.all_inclusive_rounded,
                isSelected: provider.selectedCategory == 'All' &&
                    provider.selectedPlayer == 'All' &&
                    provider.selectedPlayer != 'All Players',
                isDark: isDark,
                onTap: () {
                  HapticFeedback.selectionClick();
                  provider.resetFiltersInMemory();
                },
              ),
              const SizedBox(width: 6),
              _buildQuickFilterChip(
                label: 'Renewables',
                icon: Icons.solar_power_rounded,
                isSelected: provider.selectedCategory.toLowerCase() == 'renewables',
                isDark: isDark,
                onTap: () {
                  HapticFeedback.selectionClick();
                  provider.setCategory('renewables');
                },
              ),
              const SizedBox(width: 6),
              _buildQuickFilterChip(
                label: 'Grid & T&D',
                icon: Icons.electric_bolt_rounded,
                isSelected: provider.selectedCategory.toLowerCase() == 'transmission',
                isDark: isDark,
                onTap: () {
                  HapticFeedback.selectionClick();
                  provider.setCategory('transmission');
                },
              ),
              const SizedBox(width: 6),
              _buildQuickFilterChip(
                label: 'DISCOMs',
                icon: Icons.bolt_rounded,
                isSelected: provider.selectedCategory.toLowerCase() == 'distribution',
                isDark: isDark,
                onTap: () {
                  HapticFeedback.selectionClick();
                  provider.setCategory('distribution');
                },
              ),
              const SizedBox(width: 6),
              _buildQuickFilterChip(
                label: 'Generation',
                icon: Icons.factory_rounded,
                isSelected: provider.selectedCategory.toLowerCase() == 'generation',
                isDark: isDark,
                onTap: () {
                  HapticFeedback.selectionClick();
                  provider.setCategory('generation');
                },
              ),
              const SizedBox(width: 6),
              _buildQuickFilterChip(
                label: 'Smart Meters',
                icon: Icons.speed_rounded,
                isSelected: provider.selectedCategory.toLowerCase() == 'smart_meters',
                isDark: isDark,
                onTap: () {
                  HapticFeedback.selectionClick();
                  provider.setCategory('smart_meters');
                },
              ),
            ],
          ),
        ),

        // Main Vertical Card Viewport
        Expanded(
          child: Stack(
            children: [
              PageView.builder(
                controller: _pageController,
                scrollDirection: Axis.vertical,
                physics: const SnappyPageScrollPhysics(),
                itemCount: articles.length,
                onPageChanged: (index) {
                  HapticFeedback.selectionClick();
                  provider.markArticleAsSeen(articles[index].id);
                  if (index >= articles.length - 2 && provider.hasMore && !provider.isLoadingMore) {
                    provider.fetchMoreNews();
                  }
                },
                itemBuilder: (context, index) {
                  final article = articles[index];
                  return ExecutiveCardView(
                    article: article,
                    currentIndex: index,
                    totalCount: articles.length,
                    onNextCard: () {
                      if (index < articles.length - 1) {
                        _pageController.nextPage(
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeOut,
                        );
                      }
                    },
                  );
                },
              ),

              // Floating Offline Mode Pill
              if (provider.isOffline)
                Positioned(
                  bottom: 16,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                      decoration: BoxDecoration(
                        color: Colors.black87,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.white24, width: 0.8),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.cloud_off_rounded, size: 12, color: Colors.amberAccent),
                          SizedBox(width: 6),
                          Text(
                            'Offline Cache Mode',
                            style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildQuickFilterChip({
    required String label,
    required IconData icon,
    required bool isSelected,
    required bool isDark,
    required VoidCallback onTap,
  }) {
    final activeBg = isDark ? const Color(0xFF2563EB) : const Color(0xFF2563EB);
    final idleBg = isDark ? const Color(0xFF1E293B).withValues(alpha: 0.85) : Colors.white.withValues(alpha: 0.92);
    const activeText = Colors.white;
    final idleText = isDark ? const Color(0xFF94A3B8) : const Color(0xFF475569);
    final borderColor = isSelected
        ? Colors.transparent
        : (isDark ? const Color(0xFF334155).withValues(alpha: 0.8) : const Color(0xFFE2E8F0));

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: isSelected ? activeBg : idleBg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: borderColor, width: 0.9),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.06),
              blurRadius: 4,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 13,
              color: isSelected ? Colors.white : (isDark ? const Color(0xFF38BDF8) : const Color(0xFF2563EB)),
            ),
            const SizedBox(width: 5),
            Text(
              label,
              style: TextStyle(
                fontSize: 11.5,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                color: isSelected ? activeText : idleText,
              ),
            ),
          ],
        ),
      ),
    );
  }



  Widget _buildSkeletonLoader(bool isDark) {
    final cardBg = isDark ? const Color(0xFF111827) : Colors.white;
    final placeholderColor = isDark ? const Color(0xFF1F2937) : const Color(0xFFE2E8F0);

    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 8, 14, 12),
      child: Container(
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: isDark ? const Color(0x14FFFFFF) : const Color(0x0F000000),
            width: 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image skeleton
            Container(
              height: 180,
              width: double.infinity,
              decoration: BoxDecoration(
                color: placeholderColor,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(width: 120, height: 12, color: placeholderColor),
                  const SizedBox(height: 14),
                  Container(width: double.infinity, height: 18, color: placeholderColor),
                  const SizedBox(height: 8),
                  Container(width: 220, height: 18, color: placeholderColor),
                  const SizedBox(height: 20),
                  Container(width: double.infinity, height: 12, color: placeholderColor),
                  const SizedBox(height: 8),
                  Container(width: double.infinity, height: 12, color: placeholderColor),
                  const SizedBox(height: 8),
                  Container(width: 280, height: 12, color: placeholderColor),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, NewsProvider provider, bool isDark) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1F2937) : const Color(0xFFF1F5F9),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.auto_stories_outlined,
                size: 30,
                color: isDark ? AppTheme.darkPrimary : AppTheme.lightPrimary,
              ),
            ),
            const SizedBox(height: 18),
            Text(
              'No Executive Briefings Found',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w800,
                color: isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              provider.isFiltered
                  ? 'No stories match the active filter. Tap below to reset and view all sector intelligence.'
                  : 'Feed is refreshing or no briefings available in retention period.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13.5,
                color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary,
              ),
            ),
            const SizedBox(height: 20),
            if (provider.isFiltered)
              ElevatedButton.icon(
                onPressed: () {
                  HapticFeedback.selectionClick();
                  provider.resetFiltersInMemory();
                },
                icon: const Icon(Icons.refresh_rounded, size: 16),
                label: const Text('Reset All Filters'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: isDark ? AppTheme.darkPrimary : AppTheme.lightPrimary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 11),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(BuildContext context, NewsProvider provider, bool isDark) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.cloud_off_rounded, size: 48, color: Colors.redAccent.shade100),
            const SizedBox(height: 16),
            Text(
              'Connection Error',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w800,
                color: isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              provider.errorMessage ?? 'Could not connect to power news cloud network.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary,
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: () => provider.retryConnection(),
              icon: const Icon(Icons.refresh_rounded, size: 16),
              label: const Text('Retry Connection'),
              style: ElevatedButton.styleFrom(
                backgroundColor: isDark ? AppTheme.darkPrimary : AppTheme.lightPrimary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 11),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
