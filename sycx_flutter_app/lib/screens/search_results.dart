import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:animations/animations.dart';

class SearchResults extends StatefulWidget {
  final String searchQuery;

  const SearchResults({super.key, required this.searchQuery});

  @override
  SearchResultsState createState() => SearchResultsState();
}

class SearchResultsState extends State<SearchResults> {
  // Dummy search results (replace with actual search logic later)
  late List<Map<String, dynamic>> searchResults;

  @override
  void initState() {
    super.initState();
    // Simulate search results based on the query
    searchResults = List.generate(
      10,
      (index) => {
        'id': 'search_$index',
        'title': '${widget.searchQuery} Result $index',
        'image': 'https://picsum.photos/seed/$index/300/200',
        'date': DateTime.now().subtract(Duration(days: index)).toString(),
        'isPinned': false,
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Search Results: ${widget.searchQuery}'),
      ),
      body: RefreshIndicator(
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
                  style: GoogleFonts.exo2(
                      fontSize: 24, fontWeight: FontWeight.bold),
                ),
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
                  itemCount: searchResults.length,
                  itemBuilder: (context, index) {
                    return _buildSummaryCard(searchResults[index]);
                  },
                ),
              ],
            ),
          ),
        ),
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

  void _togglePin(String id) {
    setState(() {
      final summaryIndex =
          searchResults.indexWhere((summary) => summary['id'] == id);
      if (summaryIndex != -1) {
        searchResults[summaryIndex]['isPinned'] =
            !searchResults[summaryIndex]['isPinned'];
      }
    });
  }

  Future<void> _handleRefresh() async {
    // Simulate a network request
    await Future.delayed(const Duration(seconds: 2));

    // In a real app, you would fetch new search results from the server here
    setState(() {
      // Update the search results for demonstration purposes
      searchResults.shuffle();
    });
  }
}
