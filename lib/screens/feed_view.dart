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
                label: provider.sortOrder == FeedSortOrder.earliestFirst ? 'Earliest First' : 'Latest First',
                icon: provider.sortOrder == FeedSortOrder.earliestFirst ? Icons.schedule_rounded : Icons.bolt_rounded,
                isSelected: true,
                isDark: isDark,
                onTap: () {
                  HapticFeedback.selectionClick();
                  provider.toggleSortOrder();
                },
              ),
              const SizedBox(width: 6),
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
                label: 'Transmission',
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
                label: 'Policy',
                icon: Icons.gavel_rounded,
                isSelected: provider.selectedCategory.toLowerCase() == 'policy',
                isDark: isDark,
                onTap: () {
                  HapticFeedback.selectionClick();
                  provider.setCategory('policy');
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
                itemCount: articles.length + 1,
                onPageChanged: (index) {
                  HapticFeedback.selectionClick();
                  if (index < articles.length) {
                    provider.markArticleAsSeen(articles[index].id);
                  }
                  if (index >= articles.length - 5 && provider.hasMore && !provider.isLoadingMore) {
                    provider.fetchMoreNews();
                  }
                  if (index >= articles.length && provider.hasMore && !provider.isLoadingMore) {
                    provider.fetchMoreNews();
                  }
                },
                itemBuilder: (context, index) {
                  if (index >= articles.length) {
                    if (provider.hasMore || provider.isLoadingMore) {
                      return _buildLoadingPage(isDark);
                    } else {
                      return _buildEndOfFeedPage(isDark, provider);
                    }
                  }
                  final article = articles[index];
                  return ExecutiveCardView(
                    article: article,
                    currentIndex: index,
                    totalCount: articles.length,
                    onNextCard: () {
                      if (index < articles.length) {
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
    String title = 'No Executive Briefings Found';
    String subtitle = 'Feed is refreshing or no briefings available in retention period.';

    if (provider.isFiltered) {
      if (provider.searchQuery.trim().isNotEmpty) {
        title = 'No Stories for "${provider.searchQuery.trim()}"';
        subtitle = 'Try refining your search terms or resetting filters to browse all sector intelligence.';
      } else if (provider.selectedCategory != 'All' && provider.selectedCategory.isNotEmpty) {
        final catName = provider.selectedCategory[0].toUpperCase() + provider.selectedCategory.substring(1);
        title = 'No Articles in "$catName"';
        subtitle = 'No fresh stories indexed for $catName in this news cycle. PowerNews updates continuously throughout the day.';
      } else if (provider.selectedPlayer != 'All Players' && provider.selectedPlayer != 'All') {
        title = 'No Recent News for "${provider.selectedPlayer}"';
        subtitle = 'No recent updates detected for ${provider.selectedPlayer} in the current news cycle. Check back soon or reset filters.';
      } else if (provider.selectedDiscom != 'All DISCOMs') {
        title = 'No Updates for "${provider.selectedDiscom}"';
        subtitle = 'No distribution updates currently indexed for ${provider.selectedDiscom}. Tap below to browse all power news.';
      } else if (provider.selectedState != 'All States') {
        title = 'No Stories for "${provider.selectedState}"';
        subtitle = 'No state grid updates currently indexed for ${provider.selectedState}. Tap below to view national news.';
      } else {
        title = 'No Articles Match Filter';
        subtitle = 'No stories match the active filter criteria. Tap below to reset and view all sector intelligence.';
      }
    }

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
                provider.isFiltered ? Icons.filter_alt_off_rounded : Icons.auto_stories_outlined,
                size: 30,
                color: isDark ? AppTheme.darkPrimary : AppTheme.lightPrimary,
              ),
            ),
            const SizedBox(height: 18),
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w800,
                color: isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
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
                label: const Text('Reset to All News'),
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

  Widget _buildLoadingPage(bool isDark) {
    return Center(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 24),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
        decoration: BoxDecoration(
          color: isDark ? AppTheme.darkSurface : AppTheme.lightSurface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isDark ? AppTheme.darkBorder : const Color(0xFFE2E8F0),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.05),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 36,
              height: 36,
              child: CircularProgressIndicator(
                strokeWidth: 2.8,
                valueColor: AlwaysStoppedAnimation<Color>(
                  isDark ? AppTheme.darkPrimary : AppTheme.lightPrimary,
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Loading More Stories...',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Fetching next executive power briefings',
              style: TextStyle(
                fontSize: 12.5,
                color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEndOfFeedPage(bool isDark, NewsProvider provider) {
    return Center(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 24),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
        decoration: BoxDecoration(
          color: isDark ? AppTheme.darkSurface : AppTheme.lightSurface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isDark ? AppTheme.darkBorder : const Color(0xFFE2E8F0),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.05),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: (isDark ? AppTheme.darkPrimary : AppTheme.lightPrimary).withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.check_circle_rounded,
                size: 28,
                color: isDark ? AppTheme.darkPrimary : AppTheme.lightPrimary,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              "You're All Caught Up",
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w800,
                color: isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'All verified power sector briefings have been reviewed.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary,
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: _scrollToTop,
              icon: const Icon(Icons.arrow_upward_rounded, size: 16),
              label: const Text('Back to Top'),
              style: ElevatedButton.styleFrom(
                backgroundColor: isDark ? AppTheme.darkPrimary : AppTheme.lightPrimary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
