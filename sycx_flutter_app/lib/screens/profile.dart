import 'package:flutter/material.dart';
import 'package:sycx_flutter_app/services/profile.dart';
import 'package:sycx_flutter_app/widgets/animated_button.dart';
import 'package:sycx_flutter_app/widgets/custom_textfield.dart';
import 'package:sycx_flutter_app/widgets/loading_widget.dart';

class Profile extends StatefulWidget {
  const Profile({super.key});

  @override
  ProfileState createState() => ProfileState();
}

class ProfileState extends State<Profile> {
  String _username = '';
  String _email = '';
  String _profilePic = '';
  bool _loading = false;

  void _updateProfile() async {
    setState(() {
      _loading = true;
    });

    bool success = await Profile.updateProfile(
      'user_id', // Pass user id here
      _username,
      _email,
      _profilePic,
    );

    setState(() {
      _loading = false;
    });

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Profile updated successfully'),
      ));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Profile update failed'),
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Your Profile'),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete),
            onPressed: () async {
              bool success = await Profile.deleteAccount('user_id');
              if (success) {
                Navigator.pushReplacementNamed(context, '/login');
              }
            },
          ),
        ],
      ),
      body: _loading
          ? const Loading()
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                child: Column(
                  children: [
                    CustomTextField(
                      hintText: 'Username',
                      onChanged: (value) => _username = value,
                      validator: (value) =>
                          value!.isEmpty ? 'Enter a username' : null,
                    ),
                    CustomTextField(
                      hintText: 'Email',
                      onChanged: (value) => _email = value,
                      validator: (value) =>
                          value!.isEmpty ? 'Enter an email' : null,
                    ),
                    TextButton(
                      onPressed: () async {
                        final file =
                            await pickImage(); // Implement image picker
                        _profilePic = await convertToBase64(file);
                      },
                      child: const Text('Change Profile Picture'),
                    ),
                    const SizedBox(height: 20),
                    AnimatedButton(
                      text: 'Update Profile',
                      onPressed: _updateProfile,
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
