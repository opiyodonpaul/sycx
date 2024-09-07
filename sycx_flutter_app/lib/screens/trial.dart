import 'package:flutter/material.dart';
import 'package:sycx_flutter_app/screens/search_results.dart';
import 'package:sycx_flutter_app/widgets/loading.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:sycx_flutter_app/utils/constants.dart';
import 'package:sycx_flutter_app/widgets/animated_button.dart';
import 'package:sycx_flutter_app/widgets/custom_textfield.dart';
import 'package:sycx_flutter_app/widgets/custom_app_bar.dart';
import 'package:sycx_flutter_app/widgets/summary_card.dart';
import 'package:sycx_flutter_app/widgets/custom_bottom_nav_bar.dart';
import 'package:sycx_flutter_app/dummy_data.dart';

class Home extends StatefulWidget {
  const Home({super.key});

  @override
  HomeState createState() => HomeState();
}

class HomeState extends State<Home> with SingleTickerProviderStateMixin {
  final ScrollController _scrollController = ScrollController();
  bool _showAppBarBackground = false;
  bool _isLoading = true;
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
    // Simulate data loading
    await Future.delayed(const Duration(seconds: 2));
    if (mounted) {
      setState(() {
        _isLoading = false;
      });
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
        showBackground: _showAppBarBackground,
        title: 'SycX',
        user: DummyData.user,
      ),
      body: _isLoading
          ? const Loading()
          : RefreshIndicator(
        onRefresh: _handleRefresh,
        child: SingleChildScrollView(
          controller: _scrollController,
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            children: [
              _buildWelcomeSection(),
              _buildSearchBar(),
              _buildRecentSummaries(),
              _buildRecentSearches(),
              SizedBox(
                  height: MediaQuery.of(context).padding.bottom + 80),
            ],
          ),
        ),
      ),
      bottomNavigationBar: const CustomBottomNavBar(),
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
            const SizedBox(height: 24),
            Text(
              'Welcome to SycX, your AI-powered summarization companion for university learning!',
              style: AppTextStyles.subheadingStyle,
            ),
            const SizedBox(height: 16),
            Text(
              'SycX helps you digest complex information quickly, create concise summaries, and enhance your learning experience.',
              style: AppTextStyles.bodyTextStyle
                  .copyWith(color: AppColors.secondaryTextColor),
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
        Text(
          '$greeting ${DummyData.user['name']}',
          style: AppTextStyles.headingStyleWithShadow,
        ),
        const SizedBox(width: 8),
        const Text('👋', style: TextStyle(fontSize: 28)),
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
        padding: const EdgeInsets.only(
          top: 24,
          bottom: 8,
          left: 24,
          right: 24,
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
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Text('Recent Summaries',
                  style: AppTextStyles.subheadingStyle
                      .copyWith(color: AppColors.primaryTextColor)),
            ),
            const SizedBox(height: 16),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 24),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 0.75,
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

  Widget _buildRecentSearches() {
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
      child: Padding(
        padding:
        const EdgeInsets.only(top: 16, bottom: 16, left: 24, right: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Recent Searches',
                    style: AppTextStyles.subheadingStyle
                        .copyWith(color: AppColors.primaryTextColor)),
                AnimatedButton(
                  text: 'Clear All',
                  onPressed: () {
                    setState(() {
                      searches.clear();
                    });
                  },
                  backgroundColor: AppColors.primaryButtonColor,
                  textColor: AppColors.primaryButtonTextColor,
                ),
              ],
            ),
            const SizedBox(height: 8),
            AnimationLimiter(
              child: ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                padding: EdgeInsets.zero,
                itemCount: searches.length,
                separatorBuilder: (context, index) => const SizedBox(height: 8),
                itemBuilder: (context, index) {
                  return AnimationConfiguration.staggeredList(
                    position: index,
                    duration: const Duration(milliseconds: 375),
                    child: SlideAnimation(
                      verticalOffset: 50.0,
                      child: FadeInAnimation(
                        child: Card(
                          elevation: 2,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          margin: const EdgeInsets.all(2),
                          child: ListTile(
                            contentPadding:
                            const EdgeInsets.fromLTRB(16, 4, 16, 4),
                            leading: const Icon(Icons.history,
                                color: AppColors.secondaryTextColor),
                            title: Text(
                              searches[index],
                              style: AppTextStyles.bodyTextStyle,
                            ),
                            trailing: IconButton(
                              icon: const Icon(Icons.close,
                                  size: 20,
                                  color: AppColors.secondaryTextColor),
                              onPressed: () {
                                setState(() {
                                  searches.removeAt(index);
                                });
                              },
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
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
    // Implement refresh logic here
    await Future.delayed(const Duration(seconds: 2)); // Simulating a refresh
    setState(() {
      // Update your data here
    });
  }
}