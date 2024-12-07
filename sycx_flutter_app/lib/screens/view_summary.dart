import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:sycx_flutter_app/models/summary.dart';
import 'package:sycx_flutter_app/utils/constants.dart';
import 'package:sycx_flutter_app/widgets/custom_app_bar_mini.dart';
import 'package:sycx_flutter_app/widgets/custom_bottom_nav_bar.dart';

class ViewSummary extends StatefulWidget {
  final Summary summary;

  const ViewSummary({super.key, required this.summary});

  @override
  ViewSummaryState createState() => ViewSummaryState();
}

class ViewSummaryState extends State<ViewSummary> {
  late String summaryText;

  @override
  void initState() {
    super.initState();
    _loadSummaryText();
  }

  Future<void> _loadSummaryText() async {
    try {
      // Directly use summaryContent from the summary
      final formattedSummaryText = await widget.summary.getFormattedSummaryText();
      setState(() {
        summaryText = formattedSummaryText;
      });
    } catch (e) {
      print('Error loading summary text: $e');
      setState(() {
        summaryText = 'Error loading summary';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBarMini(
        title: widget.summary.title ?? 'View Summary',
      ),
      body: RefreshIndicator(
        onRefresh: _handleRefresh,
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.summary.title ?? 'Untitled Summary',
                  style: AppTextStyles.headingStyleNoShadow.copyWith(
                    color: AppColors.primaryTextColorDark,
                  ),
                ),
                const SizedBox(height: 16.0),
                if (summaryText.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                    child: Html(
                      data: summaryText,
                    ),
                  )
                else
                  const CircularProgressIndicator(),
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: const CustomBottomNavBar(
        currentRoute: '/view_summary',
      ),
    );
  }

  Future<void> _handleRefresh() async {
    await Future.delayed(const Duration(seconds: 2));
  }
}