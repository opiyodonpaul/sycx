import 'package:flutter/material.dart';
import 'package:sycx_flutter_app/utils/constants.dart';
import 'package:sycx_flutter_app/widgets/custom_app_bar_mini.dart';

class HelpCenter extends StatelessWidget {
  const HelpCenter({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBarMini(title: 'Help Center'),
      body: ListView(
        children: [
          _buildSection(
            'Frequently Asked Questions',
            'Find answers to common questions.',
            Icons.question_answer,
          ),
          _buildSection(
            'Contact Support',
            'Get in touch with our support team.',
            Icons.support_agent,
          ),
          _buildSection(
            'User Guide',
            'Learn how to use the app effectively.',
            Icons.book,
          ),
          _buildSection(
            'Report a Problem',
            'Let us know if you encounter any issues.',
            Icons.bug_report,
          ),
        ],
      ),
    );
  }

  Widget _buildSection(String title, String description, IconData icon) {
    return ListTile(
      leading: Icon(icon, color: AppColors.primaryTextColor),
      title: Text(title, style: AppTextStyles.titleStyle),
      subtitle: Text(description, style: AppTextStyles.bodyTextStyle),
      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
      onTap: () {
        // Implement navigation or action for each section
      },
    );
  }
}
