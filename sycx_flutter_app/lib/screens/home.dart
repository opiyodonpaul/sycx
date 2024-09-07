import 'package:flutter/material.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:sycx_flutter_app/dummy_data.dart';
import 'package:sycx_flutter_app/utils/constants.dart';
import 'package:sycx_flutter_app/widgets/custom_app_bar.dart';
import 'package:sycx_flutter_app/widgets/custom_bottom_nav_bar.dart';
import 'package:sycx_flutter_app/widgets/custom_textfield.dart';
import 'package:sycx_flutter_app/widgets/summary_card.dart';
import 'package:sycx_flutter_app/widgets/recent_searches_card.dart';
import 'search_results.dart';

class Home extends StatefulWidget {
  const Home({super.key});

  @override
  HomeState createState() => HomeState();
}

class HomeState extends State<Home> with SingleTickerProviderStateMixin {
  final ScrollController _scrollController = ScrollController();
  bool _showAppBarBackground = false;
  late AnimationController _animationController;

  List<Map<String, dynamic>> summaries = DummyData.summaries;
  List<String> searches = DummyData.searches;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    _loadData();
  }

  Future<void> _loadData() async {
    await Future.delayed(const Duration(seconds: 2));
    if (mounted) {
      setState(() {});
      _animationController.forward();
    }
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.offset > 10 && !_showAppBarBackground) {
      setState(() => _showAppBarBackground = true);
    } else if (_scrollController.offset <= 10 && _showAppBarBackground) {
      setState(() => _showAppBarBackground = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: CustomAppBar(
        user: DummyData.user,
        showBackground: false,
        title: 'SycX',
      ),
      body: RefreshIndicator(
        onRefresh: _handleRefresh,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: _buildBody(),
        ),
      ),
      bottomNavigationBar: const CustomBottomNavBar(),
    );
  }

  Widget _buildBody() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildWelcomeSection(),
        _buildSearchBar(),
        _buildRecentSummaries(),
        AnimatedBuilder(
          animation: _animationController,
          builder: (context, child) {
            return Transform.translate(
              offset: Tween<Offset>(
                begin: const Offset(0, 50),
                end: Offset.zero,
              )
                  .animate(CurvedAnimation(
                      parent: _animationController,
                      curve: const Interval(0.6, 1.0, curve: Curves.easeOut)))
                  .value,
              child: Opacity(
                opacity: Tween<double>(begin: 0.0, end: 1.0)
                    .animate(CurvedAnimation(
                        parent: _animationController,
                        curve: const Interval(0.6, 1.0, curve: Curves.easeOut)))
                    .value,
                child: child,
              ),
            );
          },
          child: RecentSearchesCard(
            searches: searches,
            onClearAll: () {
              setState(() {
                searches.clear();
              });
            },
            onRemoveSearch: (index) {
              setState(() {
                searches.removeAt(index);
              });
            },
          ),
        ),
      ],
    );
  }

  Widget _buildWelcomeSection() {
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return Transform.translate(
          offset: Tween<Offset>(
            begin: const Offset(0, 50),
            end: Offset.zero,
          )
              .animate(CurvedAnimation(
                  parent: _animationController, curve: Curves.easeOut))
              .value,
          child: Opacity(
            opacity: Tween<double>(begin: 0.0, end: 1.0)
                .animate(CurvedAnimation(
                    parent: _animationController, curve: Curves.easeOut))
                .value,
            child: child,
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.fromLTRB(24, 120, 24, 24),
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [AppColors.gradientStart, AppColors.gradientEnd],
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildGreeting(),
            const SizedBox(height: 16),
            Text(
              'Welcome to SycX, your AI-powered summarization companion!',
              style: AppTextStyles.bodyTextStyle,
            ),
            const SizedBox(height: 8),
            Text(
              'SycX helps you digest complex information quickly, create concise summaries, and enhance your learning experience.',
              style: AppTextStyles.bodyTextStyle,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGreeting() {
    final hour = DateTime.now().hour;
    String greeting;

    if (hour < 12) {
      greeting = 'Good Morning';
    } else if (hour < 17) {
      greeting = 'Good Afternoon';
    } else {
      greeting = 'Good Evening';
    }

    return Row(
      children: [
        Expanded(
          child: Text(
            '$greeting ${DummyData.user['name']} 👋',
            style: AppTextStyles.headingStyleWithShadow.copyWith(fontSize: 24),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildSearchBar() {
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return Transform.translate(
          offset: Tween<Offset>(
            begin: const Offset(0, 50),
            end: Offset.zero,
          )
              .animate(CurvedAnimation(
                  parent: _animationController,
                  curve: const Interval(0.2, 1.0, curve: Curves.easeOut)))
              .value,
          child: Opacity(
            opacity: Tween<double>(begin: 0.0, end: 1.0)
                .animate(CurvedAnimation(
                    parent: _animationController,
                    curve: const Interval(0.2, 1.0, curve: Curves.easeOut)))
                .value,
            child: child,
          ),
        );
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(
          vertical: 16,
          horizontal: 24,
        ),
        child: CustomTextField(
          hintText: 'Search for summaries...',
          onChanged: (value) {},
          validator: (value) => null,
          prefixIcon: Icons.search,
          onFieldSubmitted: (value) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => SearchResults(searchQuery: value),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildRecentSummaries() {
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return Transform.translate(
            offset: Tween<Offset>(
              begin: const Offset(0, 50),
              end: Offset.zero,
            )
                .animate(CurvedAnimation(
                    parent: _animationController,
                    curve: const Interval(0.4, 1.0, curve: Curves.easeOut)))
                .value,
            child: Opacity(
              opacity: Tween<double>(begin: 0.0, end: 1.0)
                  .animate(CurvedAnimation(
                      parent: _animationController,
                      curve: const Interval(0.4, 1.0, curve: Curves.easeOut)))
                  .value,
              child: child,
            ));
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Text('Recent Summaries',
                  style: AppTextStyles.titleStyle.copyWith(fontSize: 18)),
            ),
            const SizedBox(height: 8),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 24),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 0.8,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
              ),
              itemCount: summaries.length,
              itemBuilder: (context, index) {
                return AnimationConfiguration.staggeredGrid(
                  position: index,
                  duration: const Duration(milliseconds: 375),
                  columnCount: 2,
                  child: ScaleAnimation(
                    child: FadeInAnimation(
                      child: SummaryCard(
                        summary: summaries[index],
                        onTogglePin: _togglePin,
                      ),
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  void _togglePin(String id) {
    setState(() {
      final summaryIndex =
          summaries.indexWhere((summary) => summary['id'] == id);
      if (summaryIndex != -1) {
        summaries[summaryIndex]['isPinned'] =
            !(summaries[summaryIndex]['isPinned'] as bool);
      }
    });
  }

  Future<void> _handleRefresh() async {
    await Future.delayed(const Duration(seconds: 2));
  }
}
