import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:sycx_flutter_app/models/user.dart' as app_user;
import 'package:sycx_flutter_app/models/summary.dart';
import 'package:sycx_flutter_app/services/database.dart';
import 'package:sycx_flutter_app/screens/search_results.dart';
import 'package:sycx_flutter_app/utils/constants.dart';
import 'package:sycx_flutter_app/widgets/custom_app_bar.dart';
import 'package:sycx_flutter_app/widgets/custom_bottom_nav_bar.dart';
import 'package:sycx_flutter_app/widgets/custom_textfield.dart';
import 'package:sycx_flutter_app/widgets/loading.dart';
import 'package:sycx_flutter_app/widgets/summary_card.dart';
import 'package:sycx_flutter_app/widgets/recent_searches_card.dart';

class Home extends StatefulWidget {
  const Home({super.key});

  @override
  HomeState createState() => HomeState();
}

class HomeState extends State<Home> with SingleTickerProviderStateMixin {
  final ScrollController _scrollController = ScrollController();
  bool _showAppBarBackground = false;
  late AnimationController _animationController;

  List<Summary> _summaries = [];
  List<String> _searches = [];
  bool _isLoading = true;
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();

  // User data
  app_user.User? _currentUser;
  final Database _database = Database();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    _loadData();
    CustomBottomNavBar.updateLastMainRoute('/home');
  }

  Future<void> _loadData() async {
    try {
      // Get current user ID
      final firebaseUser = firebase_auth.FirebaseAuth.instance.currentUser;
      if (firebaseUser != null) {
        // Fetch user data
        final user = await _database.getUser(firebaseUser.uid);

        // Fetch recent summaries (latest 4)
        final summaries = await _database.getUserSummaries(firebaseUser.uid);

        // Fetch recent searches (latest 5)
        final searches = await _fetchRecentSearches(firebaseUser.uid);

        if (mounted) {
          setState(() {
            _currentUser = user;
            _summaries = summaries.length > 4
                ? summaries.sublist(summaries.length - 4).reversed.toList()
                : summaries.reversed.toList();
            _searches = searches;
            _isLoading = false;
          });
          _animationController.forward();
        }
      }
    } catch (e) {
      print('Error loading data: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<List<String>> _fetchRecentSearches(String userId) async {
    try {
      // Implement a method to fetch recent searches from Firestore
      // You'll need to create a 'searches' collection in Firestore
      QuerySnapshot searchesSnapshot = await _database.firestore
          .collection('searches')
          .where('userId', isEqualTo: userId)
          .orderBy('timestamp', descending: true)
          .limit(5)
          .get();

      return searchesSnapshot.docs
          .map((doc) => doc['query'] as String)
          .toList();
    } catch (e) {
      print('Error fetching searches: $e');
      return [];
    }
  }

  Future<void> _saveSearch(String query) async {
    try {
      final firebaseUser = firebase_auth.FirebaseAuth.instance.currentUser;
      if (firebaseUser != null) {
        await _database.firestore.collection('searches').add({
          'userId': firebaseUser.uid,
          'query': query,
          'timestamp': FieldValue.serverTimestamp(),
        });
      }
    } catch (e) {
      print('Error saving search: $e');
    }
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    _animationController.dispose();
    _searchController.dispose();
    _searchFocusNode.dispose();
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
    return _isLoading
        ? const Loading()
        : Scaffold(
            extendBodyBehindAppBar: true,
            appBar: CustomAppBar(
              user: _currentUser,
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
            bottomNavigationBar: const CustomBottomNavBar(
              currentRoute: '/home',
            ),
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
            searches: _searches,
            onClearAll: () async {
              final firebaseUser = firebase_auth.FirebaseAuth.instance.currentUser;
              if (firebaseUser != null) {
                // Implement method to clear all searches for the user
                await _database.firestore
                    .collection('searches')
                    .where('userId', isEqualTo: firebaseUser.uid)
                    .get()
                    .then((snapshot) {
                  for (DocumentSnapshot doc in snapshot.docs) {
                    doc.reference.delete();
                  }
                });

                setState(() {
                  _searches.clear();
                });
              }
            },
            onRemoveSearch: (index) async {
              final firebaseUser = firebase_auth.FirebaseAuth.instance.currentUser;
              if (firebaseUser != null) {
                // Implement method to remove a specific search
                final searchQuery = _searches[index];
                await _database.firestore
                    .collection('searches')
                    .where('userId', isEqualTo: firebaseUser.uid)
                    .where('query', isEqualTo: searchQuery)
                    .get()
                    .then((snapshot) {
                  for (DocumentSnapshot doc in snapshot.docs) {
                    doc.reference.delete();
                  }
                });

                setState(() {
                  _searches.removeAt(index);
                });
              }
            },
            onEmptySearchTap: () {
              _searchFocusNode.requestFocus();
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
            '$greeting ${_currentUser?.name ?? 'User'} 👋',
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
          controller: _searchController,
          focusNode: _searchFocusNode,
          hintText: 'Search for summaries...',
          onChanged: (value) {},
          validator: (value) => null,
          prefixIcon: Icons.search,
          onFieldSubmitted: (value) {
            if (value.isNotEmpty) {
              // Save the search
              _saveSearch(value);

              setState(() {
                if (!_searches.contains(value)) {
                  _searches.insert(0, value);
                }
              });
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => SearchResults(searchQuery: value),
                ),
              );
            }
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
          ),
        );
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
              itemCount: _summaries.isEmpty ? 1 : _summaries.length,
              itemBuilder: (context, index) {
                return AnimationConfiguration.staggeredGrid(
                  position: index,
                  duration: const Duration(milliseconds: 375),
                  columnCount: 2,
                  child: ScaleAnimation(
                    child: FadeInAnimation(
                      child: _summaries.isEmpty
                          ? SummaryCard(
                        summary: {
                          'id': 'empty',
                          'title': 'No summaries yet',
                          'date': DateTime.now().toIso8601String(),
                          'image': 'assets/images/card.png',
                          'isPinned': false,
                        },
                        onTogglePin: (_) {},
                        isEmpty: true,
                      )
                          : SummaryCard(
                        summary: {
                          'id': _summaries[index].id,
                          'title': _summaries[index].originalDocuments.isNotEmpty
                              ? _summaries[index].originalDocuments.first.title
                              : 'Untitled Summary',
                          'date': _summaries[index].createdAt.toIso8601String(),
                          'isPinned': _summaries[index].isPinned,
                        },
                        onTogglePin: _togglePin,
                        isEmpty: false,
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

  void _togglePin(String id) async {
    try {
      // Find the summary in the list
      Summary? summaryToToggle = _summaries.firstWhere((summary) => summary.id == id);

      // Get the current user
      final firebaseUser = firebase_auth.FirebaseAuth.instance.currentUser;
      if (firebaseUser == null) {
        _showToast('Please log in to pin summaries', isError: true);
        return;
      }

      // Toggle the pinned status
      summaryToToggle.isPinned = !summaryToToggle.isPinned;

      // Update in the database
      await _database.updateSummary(summaryToToggle);

      // Update the local list
      setState(() {
        // Find and update the summary in the list
        int index = _summaries.indexWhere((summary) => summary.id == id);
        if (index != -1) {
          _summaries[index] = summaryToToggle;
        }
      });

      // Show success toast
      _showToast(summaryToToggle.isPinned
          ? 'Summary pinned successfully'
          : 'Summary unpinned successfully');

    } catch (e) {
      // Handle any errors
      _showToast('Failed to toggle pin status', isError: true);
      print('Error toggling pin: $e');
    }
  }

  void _showToast(String message, {bool isError = false}) {
    Fluttertoast.showToast(
      msg: message,
      toastLength: Toast.LENGTH_SHORT,
      gravity: ToastGravity.BOTTOM,
      backgroundColor: isError
          ? Colors.red
          : AppColors.gradientMiddle,
      textColor: Colors.white,
    );
  }

  Future<void> _handleRefresh() async {
    CustomBottomNavBar.updateLastMainRoute('/home');
    await _loadData();
  }
}
