import 'package:flutter/material.dart';
import 'package:sycx_flutter_app/utils/constants.dart';
import 'package:sycx_flutter_app/widgets/custom_app_bar_mini.dart';

class AccountSettings extends StatelessWidget {
  const AccountSettings({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBarMini(title: 'Account Settings'),
      body: ListView(
        children: [
          ListTile(
            title: Text('Change Password', style: AppTextStyles.bodyTextStyle),
            leading: const Icon(Icons.lock, color: AppColors.primaryTextColor),
            onTap: () {
              // TODO: Implement change password functionality
            },
          ),
          ListTile(
            title: Text('Linked Accounts', style: AppTextStyles.bodyTextStyle),
            leading: const Icon(Icons.link, color: AppColors.primaryTextColor),
            onTap: () {
              // TODO: Implement linked accounts functionality
            },
          ),
          ListTile(
            title: Text('Delete Account', style: AppTextStyles.bodyTextStyle),
            leading: const Icon(Icons.delete_forever, color: Colors.red),
            onTap: () {
              // TODO: Implement delete account functionality
            },
          ),
        ],
      ),
    );
  }
}
