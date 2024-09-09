import 'package:flutter/material.dart';
import 'package:sycx_flutter_app/dummy_data.dart';
import 'package:sycx_flutter_app/models/summary.dart';
import 'package:sycx_flutter_app/services/summary.dart';
import 'package:sycx_flutter_app/utils/constants.dart';
import 'package:sycx_flutter_app/widgets/custom_app_bar.dart';
import 'package:sycx_flutter_app/widgets/custom_bottom_nav_bar.dart';

class Summaries extends StatefulWidget {
  const Summaries({super.key});

  @override
  SummariesState createState() => SummariesState();
}

class SummariesState extends State<Summaries>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  List<Summary> summaries = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    _animationController.forward();

    _loadSummaries();
  }

  Future<void> _loadSummaries() async {
    try {
      final loadedSummaries = await SummaryService.getSummaries('dummyUserId');
      setState(() {
        summaries = loadedSummaries;
        isLoading = false;
      });
    } catch (e) {
      print('Error loading summaries: $e');
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
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
      body: _buildBody(),
      bottomNavigationBar: const CustomBottomNavBar(
        currentRoute: '/summaries',
      ),
    );
  }

  Widget _buildBody() {
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildWelcomeSection(),
          Padding(
            padding: const EdgeInsets.all(defaultPadding),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildSummariesList(),
              ],
            ),
          ),
        ],
      ),
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
            Text(
              'Your Summaries',
              style: AppTextStyles.headingStyleWithShadow,
            ),
            const SizedBox(height: 8),
            Text(
              'View and manage your summarized content.',
              style: AppTextStyles.subheadingStyle,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummariesList() {
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Your Summaries',
            style: AppTextStyles.titleStyle,
          ),
          const SizedBox(height: 16),
          isLoading
              ? const CircularProgressIndicator()
              : ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: summaries.length,
                  itemBuilder: (context, index) {
                    final summary = summaries[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 16),
                      color: AppColors.textFieldFillColor,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: ListTile(
                        contentPadding: const EdgeInsets.all(16),
                        leading: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.network(
                            summary.image ?? 'assets/images/welcome.png',
                            width: 48,
                            height: 48,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return Image.asset(
                                'assets/images/welcome.png',
                                width: 48,
                                height: 48,
                                fit: BoxFit.cover,
                              );
                            },
                          ),
                        ),
                        title: Text(
                          summary.title ?? 'Untitled',
                          style: AppTextStyles.titleStyle.copyWith(
                            color: AppColors.primaryTextColor,
                          ),
                        ),
                        subtitle: Text(
                          'Created on ${summary.date ?? 'Unknown date'}',
                          style: AppTextStyles.bodyTextStyle.copyWith(
                            color: AppColors.secondaryTextColor,
                          ),
                        ),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete,
                              color: AppColors.gradientEnd),
                          onPressed: () =>
                              _showDeleteConfirmation(context, summary),
                        ),
                        onTap: () {
                          // Navigate to summary details page
                          // You'll need to implement this page
                          // Navigator.pushNamed(context, '/summary-details', arguments: summary);
                        },
                      ),
                    );
                  },
                ),
        ],
      ),
    );
  }

  void _showDeleteConfirmation(BuildContext context, Summary summary) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: AppColors.textFieldFillColor,
          title: Text(
            'Delete Summary',
            style: AppTextStyles.titleStyle
                .copyWith(color: AppColors.primaryTextColor),
          ),
          content: Text(
            'Are you sure you want to delete this summary?',
            style: AppTextStyles.bodyTextStyle
                .copyWith(color: AppColors.primaryTextColor),
          ),
          actions: [
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(false),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.gradientStart,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
              child: Text(
                'Cancel',
                style: AppTextStyles.buttonTextStyle,
              ),
            ),
            ElevatedButton(
              onPressed: () {
                // Delete the summary
                setState(() {
                  summaries.remove(summary);
                });
                Navigator.of(context).pop(true);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.gradientEnd,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
              child: Text(
                'Delete',
                style: AppTextStyles.buttonTextStyle,
              ),
            ),
          ],
        );
      },
    );
  }
}
