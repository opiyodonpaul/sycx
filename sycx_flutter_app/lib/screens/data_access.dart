import 'package:flutter/material.dart';
import 'package:sycx_flutter_app/utils/constants.dart';
import 'package:sycx_flutter_app/widgets/custom_app_bar_mini.dart';

class DataAccess extends StatelessWidget {
  const DataAccess({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBarMini(title: 'Data Access'),
      body: ListView(
        children: [
          _buildSection(
            'Your Data',
            'View and manage the data associated with your account.',
            Icons.folder_open,
          ),
          _buildSection(
            'Download Your Data',
            'Request a copy of your personal data.',
            Icons.cloud_download,
          ),
          _buildSection(
            'Data Usage',
            'See how your data is used to improve our services.',
            Icons.bar_chart,
          ),
          _buildSection(
            'Third-Party Access',
            'Manage which third-party apps have access to your data.',
            Icons.security,
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
