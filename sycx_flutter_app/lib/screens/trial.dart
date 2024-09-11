import 'package:flutter/material.dart';
import 'package:sycx_flutter_app/services/profile.dart';
import 'package:sycx_flutter_app/utils/constants.dart';
import 'package:sycx_flutter_app/utils/pick_image.dart';
import 'package:sycx_flutter_app/utils/convert_to_base64.dart';
import 'package:sycx_flutter_app/widgets/animated_button.dart';
import 'package:sycx_flutter_app/widgets/custom_app_bar_mini.dart';
import 'package:sycx_flutter_app/widgets/custom_bottom_nav_bar.dart';
import 'package:sycx_flutter_app/widgets/custom_textfield.dart';
import 'package:sycx_flutter_app/widgets/loading.dart';

class Profile extends StatefulWidget {
  const Profile({super.key});

  @override
  ProfileState createState() => ProfileState();
}

class ProfileState extends State<Profile> {
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  String _profilePic = '';
  bool _loading = false;

  void _updateProfile() async {
    setState(() {
      _loading = true;
    });

    try {
      bool success = await ProfileService.updateProfile(
        'user_id', // Pass user id here
        _usernameController.text,
        _emailController.text,
        _profilePic,
      );

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Profile updated successfully'),
        ));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Profile update failed'),
        ));
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Error: ${e.toString()}'),
      ));
    } finally {
      setState(() {
        _loading = false;
      });
    }
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _emailController.dispose();
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
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Form(
        child: Column(
          children: [
            CustomTextField(
              hintText: 'Username',
              onChanged: (value) => {},
              validator: (value) => value!.isEmpty ? 'Enter a username' : null,
              controller: _usernameController,
            ),
            CustomTextField(
              hintText: 'Email',
              onChanged: (value) => {},
              validator: (value) => value!.isEmpty ? 'Enter an email' : null,
              controller: _emailController,
            ),
            TextButton(
              onPressed: () async {
                final picker = PickImage();
                final file = await picker.pickImageFromGallery();
                if (file != null) {
                  _profilePic = await convertFileToBase64(file);
                }
              },
              child: const Text('Change Profile Picture'),
            ),
            const SizedBox(height: 20),
            AnimatedButton(
              text: 'Update Profile',
              onPressed: _updateProfile,
              backgroundColor: AppColors.secondaryButtonColor,
              textColor: AppColors.secondaryButtonTextColor,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleRefresh() async {
    await Future.delayed(const Duration(seconds: 2));
  }
}
