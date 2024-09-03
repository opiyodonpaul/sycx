import 'package:flutter/material.dart';
import 'package:sycx_flutter_app/services/auth.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:sycx_flutter_app/utils/pick_image.dart';
import 'package:sycx_flutter_app/utils/convert_to_base64.dart';
import 'dart:io';

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
  File? _selectedImage;

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
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Register')),
      body: Form(
        key: _formKey,
        child: Column(
          children: [
            TextFormField(
              decoration: const InputDecoration(labelText: 'Username'),
              onChanged: (value) => _username = value,
              validator: (value) => value!.isEmpty ? 'Enter username' : null,
            ),
            TextFormField(
              decoration: const InputDecoration(labelText: 'Email'),
              onChanged: (value) => _email = value,
              validator: (value) => value!.isEmpty ? 'Enter email' : null,
            ),
            TextFormField(
              decoration: const InputDecoration(labelText: 'Password'),
              obscureText: true,
              onChanged: (value) => _password = value,
              validator: (value) => value!.isEmpty ? 'Enter password' : null,
            ),
            ElevatedButton(
              onPressed: _selectProfilePicture,
              child: const Text('Select Profile Picture'),
            ),
            if (_selectedImage != null)
              Image.file(
                _selectedImage!,
                height: 100,
                width: 100,
                fit: BoxFit.cover,
              ),
            ElevatedButton(
              onPressed: _register,
              child: const Text('Register'),
            ),
          ],
        ),
      ),
    );
  }
}
