import 'package:flutter/material.dart';
import 'package:sycx_flutter_app/dummy_data.dart';
import 'package:sycx_flutter_app/utils/constants.dart';
import 'package:sycx_flutter_app/widgets/custom_app_bar_mini.dart';
import 'package:sycx_flutter_app/widgets/custom_bottom_nav_bar.dart';
import 'package:sycx_flutter_app/widgets/loading.dart';
import 'package:sycx_flutter_app/screens/edit_profile.dart';
import 'package:sycx_flutter_app/screens/account_settings.dart';
import 'package:sycx_flutter_app/screens/privacy_security.dart';
import 'package:sycx_flutter_app/screens/notifications_settings.dart';
import 'package:sycx_flutter_app/screens/data_access.dart';
import 'package:sycx_flutter_app/screens/help_center.dart';

class Profile extends StatefulWidget {
  const Profile({super.key});

  @override
  ProfileState createState() => ProfileState();
}

class ProfileState extends State<Profile> with SingleTickerProviderStateMixin {
  bool _loading = false;
  late AnimationController _animationController;
  Map<String, dynamic> userData = DummyData.user;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _loading = true;
    });
    await Future.delayed(const Duration(seconds: 2));
    setState(() {
      _loading = false;
    });
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _loading
        ? const Loading()
        : Scaffold(
            appBar: const CustomAppBarMini(title: 'Profile'),
            body: RefreshIndicator(
              onRefresh: _handleRefresh,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: _buildBody(),
              ),
            ),
            bottomNavigationBar: const CustomBottomNavBar(
              currentRoute: '/profile',
            ),
          );
  }

  Widget _buildBody() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildProfileHeader(),
        _buildSettings(),
      ],
    );
  }

  Widget _buildProfileHeader() {
    return Center(
      child: Container(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: AppColors.primaryButtonColor,
                  width: 3,
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(6),
                child: CircleAvatar(
                  radius: 80,
                  backgroundImage: NetworkImage(userData['avatar']),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              userData['name'],
              style: AppTextStyles.headingStyleNoShadow.copyWith(
                color: AppColors.primaryTextColorDark,
              ),
            ),
            Text(
              '@${userData['name'].toLowerCase()}',
              style: AppTextStyles.subheadingStyle.copyWith(
                color: AppColors.secondaryTextColorDark,
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () async {
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => EditProfile(userData: userData)),
                );
                if (result != null) {
                  setState(() {
                    userData = result;
                  });
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryButtonColor,
                foregroundColor: AppColors.primaryButtonTextColor,
              ),
              child: const Text('Edit Profile'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSettings() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text(
            'Settings',
            style: AppTextStyles.titleStyle.copyWith(
              color: AppColors.primaryTextColorDark,
            ),
          ),
        ),
        _buildSettingItem('Account settings', Icons.person, () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const AccountSettings()),
          );
        }),
        _buildSettingItem('Privacy & security', Icons.security, () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const PrivacySecurity()),
          );
        }),
        _buildSettingItem('Notifications', Icons.notifications, () {
          Navigator.push(
            context,
            MaterialPageRoute(
                builder: (context) => const NotificationsSettings()),
          );
        }),
        _buildSettingItem('Access to data', Icons.data_usage, () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const DataAccess()),
          );
        }),
        _buildSettingItem('Help Center', Icons.help, () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const HelpCenter()),
          );
        }),
      ],
    );
  }

  Widget _buildSettingItem(String title, IconData icon, VoidCallback onTap) {
    return ListTile(
      leading: Icon(icon, color: AppColors.primaryTextColorDark),
      title: Text(
        title,
        style: AppTextStyles.bodyTextStyle.copyWith(
          color: AppColors.primaryTextColorDark,
        ),
      ),
      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
      onTap: onTap,
    );
  }

  Future<void> _handleRefresh() async {
    await _loadData();
  }
}
