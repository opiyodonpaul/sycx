import 'package:flutter/material.dart';
import 'package:sycx_flutter_app/utils/constants.dart';
import 'package:sycx_flutter_app/widgets/custom_app_bar_mini.dart';
import 'package:sycx_flutter_app/widgets/custom_textfield.dart';

class EditProfile extends StatefulWidget {
  final Map<String, dynamic> userData;

  const EditProfile({super.key, required this.userData});

  @override
  EditProfileState createState() => EditProfileState();
}

class EditProfileState extends State<EditProfile> {
  late TextEditingController _nameController;
  late TextEditingController _emailController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.userData['name']);
    _emailController = TextEditingController(text: widget.userData['email']);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBarMini(title: 'Edit Profile'),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            CircleAvatar(
              radius: 50,
              backgroundImage: NetworkImage(widget.userData['avatar']),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                // TODO: Implement image picker
              },
              child: const Text('Change Avatar'),
            ),
            const SizedBox(height: 16),
            CustomTextField(
              controller: _nameController,
              hintText: 'Name',
              onChanged: (value) {},
              validator: (value) =>
                  value!.isEmpty ? 'Name cannot be empty' : null,
            ),
            const SizedBox(height: 16),
            CustomTextField(
              controller: _emailController,
              hintText: 'Email',
              onChanged: (value) {},
              validator: (value) =>
                  value!.isEmpty ? 'Email cannot be empty' : null,
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: () {
                // Update the user data
                final updatedUserData = {
                  ...widget.userData,
                  'name': _nameController.text,
                  'email': _emailController.text,
                };
                Navigator.pop(context, updatedUserData);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryButtonColor,
                foregroundColor: AppColors.primaryButtonTextColor,
              ),
              child: const Text('Save Changes'),
            ),
          ],
        ),
      ),
    );
  }
}
