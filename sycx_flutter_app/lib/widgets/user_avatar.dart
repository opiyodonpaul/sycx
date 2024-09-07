import 'package:flutter/material.dart';
import 'package:sycx_flutter_app/utils/constants.dart';

class UserAvatar extends StatelessWidget {
  final Map<String, String> user;

  const UserAvatar({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton(
      offset: const Offset(0, 56),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: Colors.white,
      itemBuilder: (context) => [
        PopupMenuItem(
          enabled: false,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(user['name']!,
                  style: AppTextStyles.subheadingStyle
                      .copyWith(color: AppColors.primaryTextColor)),
              Text('Logged in as ${user['email']}',
                  style: AppTextStyles.bodyTextStyle.copyWith(
                      fontSize: 12, color: AppColors.secondaryTextColor)),
              const Divider(),
            ],
          ),
        ),
        PopupMenuItem(
          child: TextButton.icon(
            icon: const Icon(Icons.person, color: AppColors.primaryButtonColor),
            label: const Text('Profile',
                style: TextStyle(color: AppColors.primaryButtonColor)),
            onPressed: () {
              Navigator.of(context).pushNamed('/profile');
            },
          ),
        ),
        PopupMenuItem(
          child: TextButton.icon(
            icon: const Icon(Icons.logout, color: Colors.red),
            label: const Text('Logout', style: TextStyle(color: Colors.red)),
            onPressed: () {
              // Implement actual logout logic here
            },
          ),
        ),
      ],
      child: Container(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            color: AppColors.primaryButtonColor,
            width: 2,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(2),
          child: CircleAvatar(
            backgroundImage: NetworkImage(user['avatar']!),
          ),
        ),
      ),
    );
  }
}
