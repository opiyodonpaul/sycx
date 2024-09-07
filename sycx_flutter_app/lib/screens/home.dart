import 'package:flutter/material.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:animations/animations.dart';
import 'package:sycx_flutter_app/dummy_data.dart';
import 'package:sycx_flutter_app/utils/constants.dart';
import 'package:sycx_flutter_app/widgets/custom_app_bar.dart';
import 'package:sycx_flutter_app/widgets/custom_bottom_nav_bar.dart';
import 'search_results.dart';

// Dummy data (replace with actual data from MongoDB later)
final dummyUser = {
  'name': 'Artkins',
  'email': 'opiyodon@gmail.com',
  'avatar':
      'https://images.unsplash.com/photo-1535713875002-d1d0cf377fde?ixlib=rb-4.0.3&ixid=M3wxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8fA%3D%3D&auto=format&fit=crop&w=880&q=80',
};

final dummySummaries = [
  {
    'id': '1',
    'title': 'Quantum Physics',
    'image':
        'https://images.unsplash.com/photo-1635070041078-e363dbe005cb?ixlib=rb-4.0.3&ixid=M3wxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8fA%3D%3D&auto=format&fit=crop&w=1470&q=80',
    'date': '2023-09-01',
    'isPinned': false
  },
  {
    'id': '2',
    'title': 'Machine Learning',
    'image':
        'https://images.unsplash.com/photo-1555949963-ff9fe0c870eb?ixlib=rb-4.0.3&ixid=M3wxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8fA%3D%3D&auto=format&fit=crop&w=1470&q=80',
    'date': '2023-08-28',
    'isPinned': true
  },
  {
    'id': '3',
    'title': 'World History',
    'image':
        'https://images.unsplash.com/photo-1447069387593-a5de0862481e?ixlib=rb-4.0.3&ixid=M3wxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8fA%3D%3D&auto=format&fit=crop&w=1469&q=80',
    'date': '2023-08-25',
    'isPinned': false
  },
  {
    'id': '4',
    'title': 'Organic Chemistry',
    'image':
        'https://images.unsplash.com/photo-1532187863486-abf9dbad1b69?ixlib=rb-4.0.3&ixid=M3wxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8fA%3D%3D&auto=format&fit=crop&w=1470&q=80',
    'date': '2023-08-22',
    'isPinned': false
  },
];

final dummySearches = [
  'Artificial Intelligence',
  'Renewable Energy',
  'Genetic Engineering',
  'Cybersecurity',
];

class Home extends StatefulWidget {
  const Home({super.key});

  @override
  HomeState createState() => HomeState();
}

class HomeState extends State<Home> with SingleTickerProviderStateMixin {
  final TextEditingController _searchController = TextEditingController();
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
    // Simulate data loading
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
        user: dummyUser,
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
        _buildRecentSearches(),
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
    return Padding(
      padding: const EdgeInsets.all(24),
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          hintText: 'Search for summaries...',
          prefixIcon: const Icon(Icons.search),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(30),
          ),
        ),
        onSubmitted: (value) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => SearchResults(searchQuery: value),
            ),
          );
        },
      ),
    );
  }

  Widget _buildRecentSummaries() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Recent Summaries',
              style:
                  GoogleFonts.exo2(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: 0.75,
            ),
            itemCount: dummySummaries.length,
            itemBuilder: (context, index) {
              return _buildSummaryCard(dummySummaries[index]);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(Map<String, dynamic> summary) {
    return OpenContainer(
      transitionDuration: const Duration(milliseconds: 500),
      openBuilder: (context, _) => Scaffold(
        appBar: AppBar(title: Text(summary['title']!)),
        body: const Center(child: Text('Summary details go here')),
      ),
      closedBuilder: (context, openContainer) => GestureDetector(
        onTap: openContainer,
        child: Stack(
          children: [
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                image: DecorationImage(
                  image: NetworkImage(summary['image']!),
                  fit: BoxFit.cover,
                ),
              ),
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Colors.transparent, Colors.black.withOpacity(0.7)],
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        summary['title']!,
                        style: GoogleFonts.exo2(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Created on ${DateFormat('MMM d, yyyy').format(DateTime.parse(summary['date']!))}',
                        style: GoogleFonts.roboto(
                            fontSize: 12, color: Colors.white70),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Positioned(
              top: 8,
              right: 8,
              child: GestureDetector(
                onTap: () => _togglePin(summary['id']),
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  transitionBuilder:
                      (Widget child, Animation<double> animation) {
                    return ScaleTransition(scale: animation, child: child);
                  },
                  child: Icon(
                    summary['isPinned']
                        ? Icons.push_pin
                        : Icons.push_pin_outlined,
                    key: ValueKey<bool>(summary['isPinned']),
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentSearches() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Recent Searches',
                  style: GoogleFonts.exo2(
                      fontSize: 20, fontWeight: FontWeight.bold)),
              ElevatedButton(
                onPressed: () {
                  setState(() {
                    dummySearches.clear();
                  });
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue.shade800,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
                child: const Text('Clear All'),
              ),
            ],
          ),
          const SizedBox(height: 8),
          AnimationLimiter(
            child: ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              padding: EdgeInsets.zero,
              itemCount: dummySearches.length,
              separatorBuilder: (context, index) => const SizedBox(height: 5),
              itemBuilder: (context, index) {
                return AnimationConfiguration.staggeredList(
                  position: index,
                  duration: const Duration(milliseconds: 375),
                  child: SlideAnimation(
                    verticalOffset: 50.0,
                    child: FadeInAnimation(
                      child: Container(
                        margin: const EdgeInsets.all(3),
                        child: Card(
                          elevation: 2,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: ListTile(
                            contentPadding:
                                const EdgeInsets.fromLTRB(16, 4, 16, 4),
                            leading: const Icon(Icons.history),
                            title: Text(
                              dummySearches[index],
                              style: GoogleFonts.roboto(fontSize: 16),
                            ),
                            trailing: IconButton(
                              icon: const Icon(Icons.close, size: 20),
                              onPressed: () {
                                setState(() {
                                  dummySearches.removeAt(index);
                                });
                              },
                            ),
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
    );
  }

  void _togglePin(String id) {
    setState(() {
      final summaryIndex =
          dummySummaries.indexWhere((summary) => summary['id'] == id);
      if (summaryIndex != -1) {
        dummySummaries[summaryIndex]['isPinned'] =
            !(dummySummaries[summaryIndex]['isPinned'] as bool);
      }
    });
  }

  Future<void> _handleRefresh() async {
    // Simulate a network request
    await Future.delayed(const Duration(seconds: 2));
  }
}
