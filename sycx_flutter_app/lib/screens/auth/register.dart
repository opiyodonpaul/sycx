import 'dart:io';
import 'package:flutter/material.dart';
import 'package:sycx_flutter_app/services/auth.dart';
import 'package:sycx_flutter_app/utils/convert_to_base64.dart';
import 'package:sycx_flutter_app/utils/pick_image.dart';
import 'package:sycx_flutter_app/widgets/animated_button.dart';
import 'package:sycx_flutter_app/widgets/custom_textfield.dart';
import 'package:sycx_flutter_app/widgets/loading_widget.dart';

class Register extends StatefulWidget {
  const Register({super.key});

  @override
  RegisterState createState() => RegisterState();
}

class RegisterState extends State<Register> {
  final _formKey = GlobalKey<FormState>();
  String _username = '';
  String _email = '';
  String _password = '';
  String _profilePic = '';
  File? _selectedImage;
  bool _loading = false;

  void _register() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _loading = true;
    });

    bool success =
        await Auth.register(_username, _email, _password, _profilePic);

    setState(() {
      _loading = false;
    });

    if (success) {
      Navigator.pushReplacementNamed(context, '/home');
    } else {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Registration failed'),
      ));
    }
  }

  void _selectProfilePicture() async {
    final picker = PickImage();
    final File? selectedImage = await picker.pickImageFromGallery();
    if (selectedImage != null) {
      final base64Image = await convertFileToBase64(selectedImage);
      setState(() {
        _profilePic = base64Image;
        _selectedImage = selectedImage;
      });
    }
  }

  void _googleSignIn() async {
    setState(() {
      _loading = true;
    });

    bool success = await Auth.googleSignIn();

    setState(() {
      _loading = false;
    });

    if (success) {
      Navigator.pushReplacementNamed(context, '/home');
    } else {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Google sign-in failed'),
      ));
    }
  }

  void _appleSignIn() async {
    setState(() {
      _loading = true;
    });

    bool success = await Auth.appleSignIn();

    setState(() {
      _loading = false;
    });

    if (success) {
      Navigator.pushReplacementNamed(context, '/home');
    } else {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Apple sign-in failed'),
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _loading
          ? const Loading()
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
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
                    CustomTextField(
                      hintText: 'Password',
                      obscureText: true,
                      onChanged: (value) => _password = value,
                      validator: (value) =>
                          value!.isEmpty ? 'Enter a password' : null,
                    ),
                    TextButton(
                      onPressed: _selectProfilePicture,
                      child: const Text('Upload Profile Picture'),
                    ),
                    if (_selectedImage != null)
                      Image.file(
                        _selectedImage!,
                        width: 100,
                        height: 100,
                        fit: BoxFit.cover,
                      ),
                    const SizedBox(height: 20),
                    AnimatedButton(
                      text: 'Register',
                      onPressed: _register,
                    ),
                    const SizedBox(height: 20),
                    AnimatedButton(
                      text: 'Sign in with Google',
                      onPressed: _googleSignIn,
                    ),
                    const SizedBox(height: 10),
                    AnimatedButton(
                      text: 'Sign in with Apple',
                      onPressed: _appleSignIn,
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
