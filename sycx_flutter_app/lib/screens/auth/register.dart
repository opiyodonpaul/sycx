import 'package:flutter/material.dart';
import 'package:sycx_flutter_app/services/auth.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:sycx_flutter_app/utils/pick_image.dart';
import 'package:sycx_flutter_app/utils/convert_to_base64.dart';
import 'package:sycx_flutter_app/utils/constants.dart';
import 'package:sycx_flutter_app/widgets/custom_textfield.dart';
import 'package:sycx_flutter_app/widgets/animated_button.dart';
import 'dart:io';

class Register extends StatefulWidget {
  const Register({super.key});

  @override
  RegisterState createState() => RegisterState();
}

class RegisterState extends State<Register> {
  final _formKey = GlobalKey<FormState>();
  final _usernameFocusNode = FocusNode();
  final _emailFocusNode = FocusNode();
  final _passwordFocusNode = FocusNode();
  String _username = '';
  String _email = '';
  String _password = '';
  File? _selectedImage;
  bool _obscurePassword = true;

  void _refreshForm() {
    setState(() {
      _formKey.currentState?.reset();
      _username = '';
      _email = '';
      _password = '';
      _selectedImage = null;
    });
  }

  Future<void> _handleRefresh() async {
    _refreshForm();
    return Future.delayed(const Duration(seconds: 1));
  }

  void _register() async {
    if (_formKey.currentState!.validate()) {
      if (_selectedImage == null) {
        Fluttertoast.showToast(
          msg: "Please select a profile picture",
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.BOTTOM,
        );
        return;
      }

      final base64Image = await convertFileToBase64(_selectedImage!);
      bool success =
          await Auth.register(_username, _email, _password, base64Image);

      if (success) {
        Navigator.pushReplacementNamed(context, '/home');
      } else {
        Fluttertoast.showToast(
          msg: "Registration failed",
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.BOTTOM,
        );
      }
    }
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

  @override
  void dispose() {
    _usernameFocusNode.dispose();
    _emailFocusNode.dispose();
    _passwordFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvoked: (bool didPop) {
        if (!didPop) {
          Navigator.pushReplacementNamed(context, '/welcome');
        }
      },
      child: Scaffold(
        body: RefreshIndicator(
          onRefresh: _handleRefresh,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: Container(
              height: MediaQuery.of(context).size.height,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    AppColors.gradientStart,
                    AppColors.gradientMiddle,
                    AppColors.gradientEnd,
                  ],
                ),
              ),
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        const SizedBox(height: 40),
                        Center(
                          child: Text(
                            'Create Account',
                            style: AppTextStyles.headingStyleWithShadow,
                            textAlign: TextAlign.center,
                          ),
                        ),
                        const SizedBox(height: 20),
                        Center(
                          child: Text(
                            'Join us and start summarizing the world.',
                            style: AppTextStyles.subheadingStyle,
                            textAlign: TextAlign.center,
                          ),
                        ),
                        const SizedBox(height: 40),
                        if (_selectedImage != null)
                          Center(
                            child: Container(
                              width: 180,
                              height: 180,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: AppColors.primaryButtonColor,
                                  width: 3,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: AppColors.primaryButtonColor
                                        .withOpacity(0.3),
                                    blurRadius: 10,
                                    spreadRadius: 2,
                                  ),
                                ],
                              ),
                              child: ClipOval(
                                child: Image.file(
                                  _selectedImage!,
                                  fit: BoxFit.cover,
                                ),
                              ),
                            ),
                          ),
                        const SizedBox(height: 24),
                        AnimatedButton(
                          text: 'Select Profile Picture',
                          onPressed: _selectProfilePicture,
                          backgroundColor: AppColors.secondaryButtonColor,
                          textColor: AppColors.secondaryButtonTextColor,
                        ),
                        const SizedBox(height: 24),
                        CustomTextField(
                          hintText: 'Username',
                          onChanged: (value) => _username = value,
                          validator: (value) =>
                              value!.isEmpty ? 'Enter username' : null,
                          focusNode: _usernameFocusNode,
                          onFieldSubmitted: (_) {
                            FocusScope.of(context)
                                .requestFocus(_emailFocusNode);
                          },
                          prefixIcon: Icons.person,
                        ),
                        const SizedBox(height: 16),
                        CustomTextField(
                          hintText: 'Email',
                          onChanged: (value) => _email = value,
                          validator: (value) =>
                              value!.isEmpty ? 'Enter email' : null,
                          focusNode: _emailFocusNode,
                          onFieldSubmitted: (_) {
                            FocusScope.of(context)
                                .requestFocus(_passwordFocusNode);
                          },
                          prefixIcon: Icons.email,
                        ),
                        const SizedBox(height: 16),
                        CustomTextField(
                          hintText: 'Password',
                          obscureText: _obscurePassword,
                          onChanged: (value) => _password = value,
                          validator: (value) =>
                              value!.isEmpty ? 'Enter password' : null,
                          focusNode: _passwordFocusNode,
                          onFieldSubmitted: (_) => _register(),
                          prefixIcon: Icons.lock,
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscurePassword
                                  ? Icons.visibility_off
                                  : Icons.visibility,
                              color: AppColors.secondaryTextColor,
                            ),
                            onPressed: () {
                              setState(() {
                                _obscurePassword = !_obscurePassword;
                              });
                            },
                          ),
                        ),
                        const SizedBox(height: 24),
                        AnimatedButton(
                          text: 'Register',
                          onPressed: _register,
                          backgroundColor: AppColors.primaryButtonColor,
                          textColor: AppColors.primaryButtonTextColor,
                        ),
                        const SizedBox(height: 16),
                        Center(
                          child: TextButton(
                            onPressed: () {
                              Navigator.pushReplacementNamed(context, '/login');
                            },
                            child: Text(
                              'Already have an account? Log in',
                              style: AppTextStyles.bodyTextStyle.copyWith(
                                color: AppColors.primaryTextColor,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
