import 'package:flutter/material.dart';
import 'package:sycx_flutter_app/services/auth.dart';
import 'package:sycx_flutter_app/utils/constants.dart';
import 'package:sycx_flutter_app/widgets/animated_button.dart';
import 'package:sycx_flutter_app/widgets/custom_textfield.dart';
import 'package:sycx_flutter_app/widgets/loading_widget.dart';

class ForgotPassword extends StatefulWidget {
  const ForgotPassword({super.key});

  @override
  ForgotPasswordState createState() => ForgotPasswordState();
}

class ForgotPasswordState extends State<ForgotPassword> {
  final _formKey = GlobalKey<FormState>();
  String _email = '';
  bool _loading = false;

  void _resetPassword() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _loading = true;
    });

    bool success = await Auth.resetPassword(_email);

    setState(() {
      _loading = false;
    });

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Password reset link sent to your email'),
      ));
      Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Failed to send password reset link'),
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Forgot Password')),
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
                      hintText: 'Email',
                      onChanged: (value) => _email = value,
                      validator: (value) =>
                          value!.isEmpty ? 'Enter an email' : null,
                    ),
                    const SizedBox(height: 20),
                    AnimatedButton(
                      text: 'Send Reset Link',
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
