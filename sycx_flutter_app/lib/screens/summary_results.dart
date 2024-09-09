import 'package:flutter/material.dart';
import 'package:sycx_flutter_app/models/summary.dart';
import 'package:sycx_flutter_app/utils/constants.dart';
import 'package:sycx_flutter_app/widgets/custom_app_bar_mini.dart';
import 'package:sycx_flutter_app/widgets/custom_bottom_nav_bar.dart';

class SummaryResults extends StatelessWidget {
  final List<Summary> summaries;

  const SummaryResults({super.key, required this.summaries});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBarMini(title: 'Summary Results'),
      body: ListView.builder(
        itemCount: summaries.length,
        itemBuilder: (context, index) {
          return _buildSummaryCard(summaries[index]);
        },
      ),
      bottomNavigationBar: const CustomBottomNavBar(
        currentRoute: '/summary_results',
      ),
    );
  }

  Widget _buildSummaryCard(Summary summary) {
    return Card(
      color: AppColors.textFieldFillColor,
      margin: const EdgeInsets.all(defaultMargin),
      child: Padding(
        padding: const EdgeInsets.all(defaultPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              summary.title,
              style: AppTextStyles.titleStyle,
            ),
            const SizedBox(height: 16),
            Text(
              summary.content,
              style: AppTextStyles.bodyTextStyle,
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                ElevatedButton(
                  onPressed: () {
                    // TODO: Implement view full summary
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryButtonColor,
                  ),
                  child: Text('View Full Summary',
                      style: AppTextStyles.buttonTextStyle),
                ),
                ElevatedButton(
                  onPressed: () {
                    // TODO: Implement download summary
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.secondaryButtonColor,
                  ),
                  child: Text('Download', style: AppTextStyles.buttonTextStyle),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
