import 'package:flutter/material.dart';
import 'package:sycx_flutter_app/services/auth.dart';
import 'package:sycx_flutter_app/utils/constants.dart';
import 'package:sycx_flutter_app/widgets/animated_button.dart';
import 'package:sycx_flutter_app/widgets/custom_textfield.dart';
import 'package:sycx_flutter_app/widgets/loading_widget.dart';

class ResetPassword extends StatefulWidget {
  final String token;

  const ResetPassword({super.key, required this.token});

  @override
  ResetPasswordState createState() => ResetPasswordState();
}

class ResetPasswordState extends State<ResetPassword> {
  final _formKey = GlobalKey<FormState>();
  String _newPassword = '';
  String _confirmPassword = '';
  bool _loading = false;

  void _resetPassword() async {
    if (!_formKey.currentState!.validate()) return;

    if (_newPassword != _confirmPassword) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Passwords do not match'),
      ));
      return;
    }

    setState(() {
      _loading = true;
    });

    bool success = await Auth.confirmResetPassword(widget.token, _newPassword);

    setState(() {
      _loading = false;
    });

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Password reset successfully'),
      ));
      Navigator.pushReplacementNamed(context, '/login');
    } else {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Failed to reset password'),
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Reset Password')),
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
                      hintText: 'New Password',
                      obscureText: true,
                      onChanged: (value) => _newPassword = value,
                      validator: (value) =>
                          value!.isEmpty ? 'Enter a new password' : null,
                    ),
                    CustomTextField(
                      hintText: 'Confirm Password',
                      obscureText: true,
                      onChanged: (value) => _confirmPassword = value,
                      validator: (value) =>
                          value!.isEmpty ? 'Confirm your password' : null,
                    ),
                    const SizedBox(height: 20),
                    AnimatedButton(
                      text: 'Reset Password',
                      onPressed: _resetPassword,
                      backgroundColor: AppColors.secondaryButtonColor,
                      textColor: AppColors.secondaryButtonTextColor,
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
