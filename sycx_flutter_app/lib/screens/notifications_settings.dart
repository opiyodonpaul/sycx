import 'package:flutter/material.dart';
import 'package:sycx_flutter_app/utils/constants.dart';
import 'package:sycx_flutter_app/widgets/custom_app_bar_mini.dart';

class NotificationsSettings extends StatefulWidget {
  const NotificationsSettings({super.key});

  @override
  NotificationsSettingsState createState() => NotificationsSettingsState();
}

class NotificationsSettingsState extends State<NotificationsSettings> {
  bool _pushNotifications = true;
  bool _emailNotifications = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBarMini(title: 'Notifications'),
      body: ListView(
        children: [
          SwitchListTile(
            title:
                Text('Push Notifications', style: AppTextStyles.bodyTextStyle),
            value: _pushNotifications,
            onChanged: (bool value) {
              setState(() {
                _pushNotifications = value;
              });
              // TODO: Implement push notifications logic
            },
          ),
          SwitchListTile(
            title:
                Text('Email Notifications', style: AppTextStyles.bodyTextStyle),
            value: _emailNotifications,
            onChanged: (bool value) {
              setState(() {
                _emailNotifications = value;
              });
              // TODO: Implement email notifications logic
            },
          ),
        ],
      ),
    );
  }
}
