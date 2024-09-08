import 'package:flutter/material.dart';
import 'package:sycx_flutter_app/utils/constants.dart';
import 'package:sycx_flutter_app/widgets/custom_app_bar_mini.dart';
import 'package:sycx_flutter_app/widgets/custom_bottom_nav_bar.dart';
import 'package:sycx_flutter_app/widgets/loading.dart';
import 'package:sycx_flutter_app/widgets/summary_card.dart';
import 'package:sycx_flutter_app/dummy_data.dart';

class SearchResults extends StatefulWidget {
  final String searchQuery;

  const SearchResults({super.key, required this.searchQuery});

  @override
  SearchResultsState createState() => SearchResultsState();
}

class SearchResultsState extends State<SearchResults> {
  late List<Map<String, dynamic>> searchResults;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _performSearch();
  }

  void _performSearch() {
    setState(() => _isLoading = true);

    // Filter summaries based on the search query
    searchResults = DummyData.summaries.where((summary) {
      final title = summary['title'].toString().toLowerCase();
      final query = widget.searchQuery.toLowerCase();
      return title.contains(query);
    }).toList();

    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return _isLoading
        ? const Loading()
        : Scaffold(
            appBar: CustomAppBarMini(
                title: 'Search Results: ${widget.searchQuery}'),
            body: Stack(
              children: [
                RefreshIndicator(
                  onRefresh: _handleRefresh,
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Results for "${widget.searchQuery}"',
                            style: AppTextStyles.titleStyle,
                          ),
                          const SizedBox(height: 16),
                          _buildSearchResults(),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
            bottomNavigationBar: const CustomBottomNavBar(
              currentRoute: '/search',
            ),
          );
  }

  Widget _buildSearchResults() {
    if (searchResults.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(defaultPadding),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppColors.gradientStart,
              AppColors.gradientMiddle,
              AppColors.gradientEnd,
            ],
          ),
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.error_outline,
              size: 48,
              color: AppColors.primaryTextColor,
            ),
            const SizedBox(height: defaultPadding),
            Text(
              'No Results Found',
              style: AppTextStyles.headingStyleNoShadow.copyWith(fontSize: 24),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: defaultPadding / 2),
            Text(
              'We couldn\'t find any results for "${widget.searchQuery}".\nPlease try a different search term.',
              style: AppTextStyles.bodyTextStyle
                  .copyWith(color: AppColors.altPriTextColor),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 0.75,
      ),
      itemCount: searchResults.length,
      itemBuilder: (context, index) {
        return SummaryCard(
          summary: searchResults[index],
          onTogglePin: (_) {}, // Empty function as pinning is not used here
          isEmpty: false,
        );
      },
    );
  }

  Future<void> _handleRefresh() async {
    setState(() => _isLoading = true);
    await Future.delayed(const Duration(seconds: 1)); // Simulate delay
    _performSearch();
  }
}
