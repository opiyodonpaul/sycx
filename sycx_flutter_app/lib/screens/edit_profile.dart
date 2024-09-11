import 'package:flutter/material.dart';
import 'package:sycx_flutter_app/utils/constants.dart';
import 'package:sycx_flutter_app/widgets/custom_app_bar_mini.dart';
import 'package:sycx_flutter_app/widgets/custom_textfield.dart';
import 'package:sycx_flutter_app/widgets/animated_button.dart';
import 'package:sycx_flutter_app/utils/pick_image.dart';
import 'package:sycx_flutter_app/utils/convert_to_base64.dart';
import 'dart:io';

class EditProfile extends StatefulWidget {
  final Map<String, dynamic> userData;

  const EditProfile({super.key, required this.userData});

  @override
  EditProfileState createState() => EditProfileState();
}

class EditProfileState extends State<EditProfile> {
  late TextEditingController _nameController;
  late TextEditingController _emailController;
  File? _selectedImage;
  final FocusNode _nameFocus = FocusNode();
  final FocusNode _emailFocus = FocusNode();

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
    _nameFocus.dispose();
    _emailFocus.dispose();
    super.dispose();
  }

  void _selectProfilePicture() async {
    final picker = PickImage();
    final File? selectedImage = await picker.pickImageFromGallery();
    if (selectedImage != null) {
      setState(() {
        _selectedImage = selectedImage;
      });
    }
  }

  void _submitForm() async {
    String? base64Image;
    if (_selectedImage != null) {
      base64Image = await convertFileToBase64(_selectedImage!);
    }
    final updatedUserData = {
      ...widget.userData,
      'name': _nameController.text,
      'email': _emailController.text,
      if (base64Image != null) 'avatar': base64Image,
    };
    Navigator.pop(context, updatedUserData);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBarMini(title: 'Edit Profile'),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(height: 40),
                _buildProfileImage(),
                const SizedBox(height: 24),
                AnimatedButton(
                  text: 'Change Profile Picture',
                  onPressed: _selectProfilePicture,
                  backgroundColor: AppColors.secondaryButtonColor,
                  textColor: AppColors.secondaryButtonTextColor,
                ),
                const SizedBox(height: 24),
                CustomTextField(
                  controller: _nameController,
                  focusNode: _nameFocus,
                  hintText: 'Name',
                  onChanged: (value) {},
                  validator: (value) =>
                      value!.isEmpty ? 'Name cannot be empty' : null,
                  prefixIcon: Icons.person,
                  onFieldSubmitted: (_) {
                    FocusScope.of(context).requestFocus(_emailFocus);
                  },
                ),
                const SizedBox(height: 16),
                CustomTextField(
                  controller: _emailController,
                  focusNode: _emailFocus,
                  hintText: 'Email',
                  onChanged: (value) {},
                  validator: (value) =>
                      value!.isEmpty ? 'Email cannot be empty' : null,
                  prefixIcon: Icons.email,
                  onFieldSubmitted: (_) => _submitForm(),
                ),
                const SizedBox(height: 32),
                AnimatedButton(
                  text: 'Save Changes',
                  onPressed: _submitForm,
                  backgroundColor: AppColors.primaryButtonColor,
                  textColor: AppColors.primaryButtonTextColor,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProfileImage() {
    return Center(
      child: Container(
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
            radius: 90,
            backgroundImage: _selectedImage != null
                ? FileImage(_selectedImage!) as ImageProvider
                : NetworkImage(widget.userData['avatar']),
          ),
        ),
      ),
    );
  }
}
