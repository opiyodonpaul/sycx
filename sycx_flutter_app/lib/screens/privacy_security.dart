import 'package:flutter/material.dart';
import 'package:sycx_flutter_app/utils/constants.dart';
import 'package:sycx_flutter_app/widgets/custom_app_bar_mini.dart';

class PrivacySecurity extends StatefulWidget {
  const PrivacySecurity({super.key});

  @override
  PrivacySecurityState createState() => PrivacySecurityState();
}

class PrivacySecurityState extends State<PrivacySecurity> {
  bool _twoFactorAuth = false;
  bool _privateProfile = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBarMini(title: 'Privacy & Security'),
      body: ListView(
        children: [
          SwitchListTile(
            title: Text('Two-Factor Authentication',
                style: AppTextStyles.bodyTextStyle),
            value: _twoFactorAuth,
            onChanged: (bool value) {
              setState(() {
                _twoFactorAuth = value;
              });
              // TODO: Implement two-factor authentication logic
            },
          ),
          SwitchListTile(
            title: Text('Private Profile', style: AppTextStyles.bodyTextStyle),
            value: _privateProfile,
            onChanged: (bool value) {
              setState(() {
                _privateProfile = value;
              });
              // TODO: Implement private profile logic
            },
          ),
          ListTile(
            title: Text('Blocked Users', style: AppTextStyles.bodyTextStyle),
            leading: const Icon(Icons.block, color: AppColors.primaryTextColor),
            onTap: () {
              // TODO: Implement blocked users screen
            },
          ),
        ],
      ),
    );
  }
}
